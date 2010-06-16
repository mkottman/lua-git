require 'git'

local r = git.repo.open('.')

local c = r:head()

print('Commit', c.id)
print(c.author)
print(c.committer)
print(c.message)
print()

local parent = c.parents[1]
local pc = r:commit(parent)

print('Commit', pc.id)
print(pc.author)
print(pc.committer)
print(pc.message)
print()

local tree = pc:tree()
tree:walk(function(entry, entry_path, type)
	print(type, entry_path)
end)

print()
print(tree['git.lua']:content())
