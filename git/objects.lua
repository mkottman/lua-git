module(...)

Commit = {}
Commit.__index = Commit

function Commit:tree()
	return self.repo:tree(self.tree_sha)
end



Tree = {}
Tree.__index = Tree



Blob = {}
Blob.__index = Blob
