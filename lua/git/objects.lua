local util = require 'git.util'

local assert, next, io, print, os, type, string =
	assert, next, io, print, os, type, string
local join_path = git.util.join_path

local require = require

module(...)

Commit = {}
Commit.__index = Commit

function Commit:tree()
	return self.repo:tree(self.tree_sha)
end

function Commit:checkout(path)
	assert(path, 'path argument missing')
	self:tree():checkoutTo(path)
end


Tree = {}
Tree.__index = function (t,k)
	if Tree[k] then return Tree[k] end
	return t:entry(k)
end

function Tree:entries()
	return function(t, n)
		local n, entry = next(t, n)
		if entry then
			if entry.type == 'tree' then
				return n, entry.type, self.repo:tree(entry.id)
			else
				return n, entry.type, self.repo:blob(entry.id)
			end
		end
	end, self._entries
end

function Tree:entry(n)
	local e = self._entries[n]
	if not e then return end
	if e.type == 'tree' then
		return self.repo:tree(e.id)
	else
		return self.repo:blob(e.id)
	end
end

function Tree:walk(func, path)
	path = path or '.'
	assert(type(func) == "function", "argument is not a function")
	local function walk(tree, path)
		for name, type, entry in tree:entries() do
			local entry_path = join_path(path, name)
			func(entry, entry_path, type)
			if type == "tree" then
				walk(entry, entry_path)
			end
		end
	end
	walk(self, path)
end

function Tree:checkoutTo(path)
	util.make_dir(path)
	--os.execute(string.format('mkdir -p %q', path))
	self:walk(function (entry, entry_path, type)
		if type == 'tree' then
			util.make_dir(entry_path)
			--os.execute(string.format('mkdir -p %q', entry_path))
		else
			local out = assert(io.open(entry_path, 'w'))
			out:write(entry:content())
			out:close()
		end
	end, path)
end

Blob = {}
Blob.__index = Blob

function Blob:content()
	if self.stored then
		local f = self.repo:raw_object(self.id)
		local ret = f:read('*a')
		return ret
	else
		return self.data
	end
end

