local next = next

module(...)

Commit = {}
Commit.__index = Commit

function Commit:tree()
	return self.repo:tree(self.tree_sha)
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

