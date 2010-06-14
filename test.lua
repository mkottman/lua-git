require 'git'

local r = git.repo.new('.')
local c = r:commit('aa01735fd4b206ee1e83c2290e9283b564198aa2')
local t = c:tree()

print('Commit', 'aa01735fd4b206ee1e83c2290e9283b564198aa2')
print(c.author)
print(c.committer)
print(table.concat(c.message))
print()

local parent = c.parents[1]
local pc = r:commit(parent)
print('Commit', parent)
print(pc.author)
print(pc.committer)
print(table.concat(pc.message))

