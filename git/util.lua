local zlib = require 'zlib'

module(..., package.seeall)

local BUF_SIZE = 4096

local dirsep = package.config:sub(1,1)

-- joins several path components into a single path, uses system-specific directory
-- separator, cleans input, i.e. join_path('a/', 'b', 'c/') => 'a/b/c'
function join_path(...)
	local n = select('#', ...)
	local args = {...}
	for i=1,n do
		args[i] = args[i]:gsub(dirsep..'?$', '')
	end
	return table.concat(args, dirsep, 1, n)
end

-- decompress the file and return a handle to temporary uncompressed file
function decompressed(path)
	local fi = assert(io.open(path))
	local fo = io.tmpfile()

	local z = zlib.inflate()
	repeat
		local str = fi:read(BUF_SIZE)
		local data = z(str)
		if type(data) == 'string' then
			fo:write(data)
		else print('!!!', data) end
	until not str

	fo:seek('set')
	return fo
end

-- reads until the byte \0, consumes it and returns the string up to the \0
function read_until_nul(f)
	local t = {}
	repeat
		local c = f:read(1)
		if c and c ~= '\0' then t[#t+1] = c end
	until not c or c == '\0'
	if #t > 0 then
		return table.concat(t)
	else
		return nil
	end
end

-- converts a string to lowercase hex
function to_hex(s)
	return (s:gsub('.', function(c)
		return string.format('%02x', string.byte(c))
	end))
end

-- converts a string from hex to binary
function from_hex(s)
	return (s:gsub('..', function(cc)
		return string.char(tonumber(cc, 16))
	end))
end
