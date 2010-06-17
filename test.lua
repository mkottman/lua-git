require 'git'

local r = git.repo.open('.')

local c = r:head()

print('Commit', c.id)
print(c.author)
print(c.committer)
print(c.message)
print()

-- extract the head into directory 'tst'
c:checkout('tst')

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

-- find the initial commit
while #c.parents > 0 do
	c = r:commit(c.parents[1])
end

print(c.message)

c:tree():walk(function(entry, entry_path, type)
	print(type, entry_path, entry.id)
end)

assert(r:has_object('10909b56ced7f4ce9f23304ff408e7f8b88ca08b'))
