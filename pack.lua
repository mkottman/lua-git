require 'struct'
require 'zlib'
local bit = require 'bit'

local ord = string.byte
local band = bit.band
local rshift, lshift = bit.rshift, bit.lshift
local up = struct.unpack

local types = {'commit', 'tree', 'blob', 'tag', '???', 'ofs_delta', 'ref_delta'}


function read_object_header(f)
	local b = ord(f:read(1))
	local type = band(rshift(b, 4), 0x7)
	local len = band(b, 0xF)
	local ofs = 0
	while band(b, 0x80) ~= 0 do
		b = ord(f:read(1))
		len = len + lshift(band(b, 0x7F), ofs * 7 + 4)
		ofs = ofs + 1
	end
	return type, len
end


function read_delta_header(f)
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
function uncompress_by_len(f, size)
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

function unpack_object(f, type, len)
	local data = uncompress_by_len(f, len)
	print(data)
end

function unpack_delta(f, type, len)
	if type == 6 then
		local offset = read_delta_header(f)
		local data = uncompress_by_len(f, len)
		print(data)
	elseif type == 7 then
		local sha = f:read(20)
		local data = uncompress_by_len(f, len)
		print(data)
	end
end

function read_object(f)
	local type, len = read_object_header(f)
	print(types[type], len)

	if type < 6 then
		return unpack_object(f, type, len)
	elseif type == 6 or type == 7 then
		return unpack_delta(f, type, len)
	else
		error('unknown object type: '..type)
	end
end

local f = assert(io.open('.git/objects/pack/pack-b1fcb3b180269935114d04221098b2deaf7fee1b.pack'))
local head = f:read(4)
assert(head == 'PACK', head)

local version = up('>I4', f:read(4))
print('version', version)

local nobj = up('>I4', f:read(4))
print('objects', nobj)

for i=1,nobj do
	read_object(f)
end

