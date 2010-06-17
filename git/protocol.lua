local socket = require 'socket'
local urllib = require 'socket.url'
local lfs = require 'lfs'

local Pack = git.pack.Pack
local join_path = git.util.join_path

local assert, io, os, pairs, print, string, tonumber =
	assert, io, os, pairs, print, string, tonumber

module(...)

local GIT_PORT = 9418

local function git_connect(host)
	local sock = assert(socket.connect(host, GIT_PORT))
	local gitsocket = {}

	function gitsocket:send(data)
		if not data then -- flush packet
			sock:send('0000')
		else
			local len = #data + 4
			len = string.format("%04x", len)
			assert(sock:send(len .. data))
		end
	end

	function gitsocket:receive()
		local len = assert(sock:receive(4))
		len = tonumber(len, 16)
		if len == 0 then return end -- flush packet
		local data = assert(sock:receive(len - 4))
		return data
	end

	return gitsocket
end

local function git_fetch(repo, host, path)
	local s = git_connect(host)
	s:send('git-upload-pack '..path..'\0host='..host..'\0')

	local refs = {}
	repeat
		local ref = s:receive()
		if ref then
			local sha, name = ref:sub(1,40), ref:sub(42, -2)
			refs[sha] = name
		end
	until not ref
	
	for sha in pairs(refs) do
		if not repo:has_object(sha) then
			s:send('want '..sha..'  multi_ack_detailed side-band-64k ofs-delta\n')
		end
	end
	s:send()
	s:send('done\n')
	
	assert(s:receive() == "NAK\n")
	
	local packname = os.tmpname() .. '.pack'
	local packfile = assert(io.open(packname, 'w'))
	repeat
		local got = s:receive()
		if got then
			-- get sideband channel, 1=pack data, 2=progress, 3=error
			local cmd = string.byte(got:sub(1,1))
			local data = got:sub(2)
			if cmd == 1 then
				packfile:write(data)
			elseif cmd == 2 then
				io.write(data)
			else
				error(data)
			end
		end
	until not got
	packfile:close()
	
	local pack = Pack.open(packname)
	pack:unpack(repo)
end

function fetch(repo, url)
	url =urllib.parse(url)
	if url.scheme == 'git' then
		git_fetch(repo, url.host, url.path)
	else
		error('unsupported scheme: '..u.scheme)
	end
end
