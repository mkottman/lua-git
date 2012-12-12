package.path = package.path .. ';lua/?.lua'
package.cpath = package.cpath .. ';b/?.so'

require 'git'

local r = git.repo.open('.')

local c = r:head()

print('Commit', c.id)
print(c.author)
print(c.committer)
print(c.message)
print()

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
	print(type, entry_path)
end)

os.execute('rm -rf tst2')
os.execute('mkdir tst2')
os.execute('cd tst2 && git init')
r = git.repo.open('tst2')
git.protocol.fetch('git://github.com/mkottman/lua-git.git', r)