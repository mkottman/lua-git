module(..., package.seeall)

local BUF_SIZE = 4096

local dirsep = package.config:sub(1,1)
function join_path(...)
	local n = select('#', ...)
	local args = {...}
	for i=1,n do
		args[i] = args[i]:gsub(dirsep..'?$', '')
	end
	return table.concat(args, dirsep, 1, n)
end

function decompressed(path)
	local fi = assert(io.open(path))
	local fo = io.tmpfile()

	local z = zlib.inflate()
	repeat
		local str = fi:read(BUF_SIZE)
		local data = z(str)
		if type(data) == 'string' then
			fo:write(data)
		else print(data) end
	until not str

	fo:seek('set')
	return fo
end

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

function to_hex(s)
	return (s:gsub('.', function(c)
		return string.format('%02x', string.byte(c))
	end))
end

function from_hex(s)
	return (s:gsub('..', function(cc)
		return string.char(tonumber(cc, 16))
	end))
end
