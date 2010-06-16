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

function print_tree(tree, path)
	path = path or '.'
	for name, type, entry in tree:entries() do
		print(git.util.join_path(path, name), type)
		if type == 'tree' then
			print_tree(entry, git.util.join_path(path, name))
		else
			print(entry:content())
		end
	end
end

local tree = pc:tree()
print_tree(tree)

print()
print(tree['git.lua']:content())
