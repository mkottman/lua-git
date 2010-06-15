local join_path = git.util.join_path
local decompressed = git.util.decompressed
local read_until_nul = git.util.read_until_nul
local to_hex = git.util.to_hex

module(..., package.seeall)

local Repo = {}
Repo.__index = Repo

function Repo:raw_object(sha)
	if self.packs then
		for _, pack in ipairs(self.packs) do
			local obj, len = pack:get_raw(sha)
			if obj then
				return obj, len
			end
		end
	end

	local dir = sha:sub(1,2)
	local file = sha:sub(3)
	local path = join_path(self.dir, 'objects', dir, file)

	local f = decompressed(path)
	local content = read_until_nul(f)

	local typ, len = content:match('(%w+) (%d+)')
	return f, len, typ
end

function Repo:commit(sha)
	local f, len, typ = self:raw_object(sha)
	assert(typ == 'commit', string.format('%s (%s) is not a commit', sha, typ))

	local commit = { id = sha, repo = self, stored = true, parents = {} }
	repeat
		local line = f:read()
		if not line then break end

		local space = line:find(' ') or 0
		local word = line:sub(1, space - 1)
		local afterSpace = line:sub(space + 1)

		if word == 'tree' then
			commit.tree_sha = afterSpace
		elseif word == 'parent' then
			table.insert(commit.parents, afterSpace)
		elseif word == 'author' then
			commit.author = afterSpace
		elseif word == 'committer' then
			commit.committer = afterSpace
		elseif commit.message then
			table.insert(commit.message, line)
		elseif line == '' then
			commit.message = {}
		end
	until false -- ends with break

	return setmetatable(commit, git.objects.Commit)
end

function Repo:tree(sha)
	local f, len, typ = self:raw_object(sha)
	assert(typ == 'tree', string.format('%s (%s) is not a tree', sha, typ))

	local tree = { id = sha, repo = self, stored = true, _entries = {} }

	while true do
		local info = read_until_nul(f)
		if not info then break end
		local entry_sha = to_hex(f:read(20))
		local mode, name = info:match('^(%d+)%s(.+)$')
		local entry_type = mode == '40000' and 'tree' or 'blob'
		tree._entries[name] = { mode = mode, id = entry_sha, type = entry_type }
	end

	return setmetatable(tree, git.objects.Tree)
end

function Repo:blob(sha)
	local f, len, typ = self:raw_object(sha)
	f:close() -- can be reopened in Blob:content()

	assert(typ == 'blob', string.format('%s (%s) is not a blob', sha, typ))

	local blob = { id = sha, len = len, repo = self, stored = true }

	return setmetatable(blob, git.objects.Blob)
end


function new(dir)
	if not dir:match('%.git.?$') then
		dir = join_path(dir, '.git')
	end
	return setmetatable({
		dir = dir
	}, Repo)
end

return Repo
