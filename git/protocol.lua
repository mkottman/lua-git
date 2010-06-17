local socket = require 'socket'
local url = require 'socket.url'

local fmt = string.format

-- module(...)

local GIT_PORT = 9418

local function git_connect(host)
	local sock = assert(socket.connect(host, GIT_PORT))
	local gitsocket = {}

	function gitsocket:send(data)
		local len = #data + 4
		len = string.format("%04x", len)
		print('>#', len)
		print('>', data)
		assert(sock:send(len .. data))
	end

	function gitsocket:receive()
		local len = assert(sock:receive(4))
		print('<#', len)
		len = tonumber(len, 16)
		if len == 0 then return end -- flush packet
		local data = assert(sock:receive(len - 4))
		print('<', data)
		return data
	end

	return gitsocket
end

local function git_fetch(host, path)
	local s = git_connect(host)
	s:send('git-upload-pack '..path..'\0host='..host..'\0')
	local refs = {}
	repeat
		local ref = s:receive()
		if ref then
			local sha, name = ref:sub(1,40), ref:sub(42, -2)
			print(sha, name)
		end
	until not ref
end

function fetch(u)
	u = url.parse(u)
	if u.scheme == 'git' then
		git_fetch(u.host, u.path)
	else
		error('unsupported scheme: '..u.scheme)
	end
end

fetch 'git://github.com/mkottman/lua-git.git'
