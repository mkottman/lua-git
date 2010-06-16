local io = io
local struct = require 'struct'
local bit = require 'bit'
local zlib = require 'zlib'

local assert, pcall, print, setmetatable =
	assert, pcall, print, setmetatable

local ord = string.byte
local band = bit.band
local rshift, lshift = bit.rshift, bit.lshift
local up = struct.unpack
local to_hex = git.util.to_hex
local from_hex = git.util.from_hex

module(...)

-- 1 = commit, 2 = tree ...
local types = {'commit', 'tree', 'blob', 'tag', '???', 'ofs_delta', 'ref_delta'}

--[[
TODO: apply deltas, from git sources

delta.h:
static inline unsigned long get_delta_hdr_size(const unsigned char **datap,
					       const unsigned char *top)
{
	const unsigned char *data = *datap;
	unsigned long cmd, size = 0;
	int i = 0;
	do {
		cmd = *data++;
		size |= (cmd & 0x7f) << i;
		i += 7;
	} while (cmd & 0x80 && data < top);
	*datap = data;
	return size;
}

patch-delta.c:
void *patch_delta(const void *src_buf, unsigned long src_size,
		  const void *delta_buf, unsigned long delta_size,
		  unsigned long *dst_size)
{
	const unsigned char *data, *top;
	unsigned char *dst_buf, *out, cmd;
	unsigned long size;

	if (delta_size < DELTA_SIZE_MIN)
		return NULL;

	data = delta_buf;
	top = (const unsigned char *) delta_buf + delta_size;

	/* make sure the orig file size matches what we expect */
	size = get_delta_hdr_size(&data, top);
	if (size != src_size)
		return NULL;

	/* now the result size */
	size = get_delta_hdr_size(&data, top);
	dst_buf = xmallocz(size);

	out = dst_buf;
	while (data < top) {
		cmd = *data++;
		if (cmd & 0x80) {
			unsigned long cp_off = 0, cp_size = 0;
			if (cmd & 0x01) cp_off = *data++;
			if (cmd & 0x02) cp_off |= (*data++ << 8);
			if (cmd & 0x04) cp_off |= (*data++ << 16);
			if (cmd & 0x08) cp_off |= ((unsigned) *data++ << 24);
			if (cmd & 0x10) cp_size = *data++;
			if (cmd & 0x20) cp_size |= (*data++ << 8);
			if (cmd & 0x40) cp_size |= (*data++ << 16);
			if (cp_size == 0) cp_size = 0x10000;
			if (cp_off + cp_size < cp_size ||
			    cp_off + cp_size > src_size ||
			    cp_size > size)
				break;
			memcpy(out, (char *) src_buf + cp_off, cp_size);
			out += cp_size;
			size -= cp_size;
		} else if (cmd) {
			if (cmd > size)
				break;
			memcpy(out, data, cmd);
			out += cmd;
			data += cmd;
			size -= cmd;
		} else {
			/*
			 * cmd == 0 is reserved for future encoding
			 * extensions. In the mean time we must fail when
			 * encountering them (might be data corruption).
			 */
			error("unexpected delta opcode 0");
			goto bad;
		}
	}
	...
}

builtin/unpack-objects.c:
static void resolve_delta(unsigned nr, enum object_type type,
			  void *base, unsigned long base_size,
			  void *delta, unsigned long delta_size)
{
	void *result;
	unsigned long result_size;

	result = patch_delta(base, base_size,
			     delta, delta_size,
			     &result_size);
	if (!result)
		die("failed to apply delta");
	free(delta);
	write_object(nr, type, result, result_size);
}

--]]

-- read git/Documentation/technical/pack-format.txt for more info

Pack = {}
Pack.__index = Pack

-- read in the type and file length
local function read_object_header(f)
	local b = ord(f:read(1))
	local type = band(rshift(b, 4), 0x7)
	local len = band(b, 0xF)
	local ofs = 0
	while band(b, 0x80) ~= 0 do
		b = ord(f:read(1))
		len = len + lshift(band(b, 0x7F), ofs * 7 + 4)
		ofs = ofs + 1
	end
	return len, type
end

-- reads in the delta header and returns the offset where original data is stored
local function read_delta_header(f)
	local b = ord(f:read(1))
	local offset = band(b, 0x7F)
	while band(b, 0x80) ~= 0 do
		offset = offset + 1
		b = ord(f:read(1))
		offset = lshift(offset, 7) + band(b, 0x7F)
	end
	return offset
end

-- read just enough of file `f` to uncompress `size` bytes
local function uncompress_by_len(f, size)
	local z = zlib.inflate()
	-- read `size` bytes, even though it will be more than needed
	-- however, we cannot know in advance, how many bytes we will need
	local data = f:read(size + 64)
	local ok, res, total = pcall(z, data)
	if not ok or not total then print('>>>', data, res) end
	-- repair the current position in stream
	f:seek('cur', -#data + total)
	return res
end

local function unpack_object(f, len, type)
	local data = uncompress_by_len(f, len)
	return data, len, type
end

local function unpack_delta(f, len, type)
	-- TODO: resolve deltas
	if type == 6 then
		local offset = read_delta_header(f)
		local data = uncompress_by_len(f, len)
		return data, len, type
	elseif type == 7 then
		local sha = f:read(20)
		local data = uncompress_by_len(f, len)
		return data, len, type
	end
end

-- read an object from the current location in pack, or from a specific `offset`
-- if specified
function Pack:read_object(offset)
	local f = self.pack_file
	if offset then
		f:seek('set', offset)
	end
	local len, type = read_object_header(f)
	if type < 5 then
		return unpack_object(f, len, type)
	elseif type == 6 or type == 7 then
		return unpack_delta(f, len, type)
	else
		error('unknown object type: '..type)
	end
end

-- if the object name `sha` exists in the pack, returns a temporary file with the
-- object content, length and type, otherwise returns nil
function Pack:get_object(sha)
	local offset = self.index[from_hex(sha)]
	if not offset then return end

	local data, len, type = self:read_object(offset)
	local f = io.tmpfile()
	f:write(data)
	f:seek('set', 0)

	return f, len, types[type]
end

-- parses the index
function Pack:parse_index()
	local f = self.index_file

	local head = f:read(4)
	assert(head == '\255tOc', "Incorrect header: " .. head)
	local version = up('>I4', f:read(4))
	assert(version == 2, "Incorrect version: " .. version)

	-- first the fanout table (how many objects are in the index, whose
	-- first byte is below or equal to i)
	local fanout = {}
	for i=0, 255 do
		local nobjs = up('>I4', f:read(4))
		fanout[i] = nobjs
	end

	-- the last element in fanout is the number of all objects in index
	local count = fanout[255]

	-- then come the sorted object names (=sha hash)
	local tmp = {}
	for i=1,count do
		local sha = f:read(20)
		tmp[i] = { sha = sha }
	end

	-- then the CRCs (assume ok, skip them)
	for i=1, count do
		local crc = f:read(4)
	end

	-- then come the offsets - read just the 32bit ones, does not handle packs > 2G
	for i=1, count do
		local offset = up('>I4', f:read(4))
		tmp[i].offset = offset
	end

	-- construct the lookup table
	local lookup = {}
	for i=1, count do
		lookup[tmp[i].sha] = tmp[i].offset
	end
	self.index = lookup
end

function Pack.open(path)
	local fp = assert(io.open(path))
	local fi = assert(io.open((path:gsub('%.pack$', '.idx'))))

	-- read the pack header
	local head = fp:read(4)
	assert(head == 'PACK', "Incorrect header: " .. head)
	local version = up('>I4', fp:read(4))
	assert(version == 2, "Incorrect version: " .. version)
	local nobj = up('>I4', fp:read(4))

	local pack = setmetatable({
		offsets = {},
		nobjects = nobj,
		pack_file = fp,
		index_file = fi,
	}, Pack)

	-- read the index
	pack:parse_index()

	-- fill the offsets by traversing through the pack
	for i=1,nobj do
		pack.offsets[i] = fp:seek()
		-- ignore the return value, we only need the offset
		pack:read_object()
	end

	return pack
end

return Pack
