require 'git'

local commit = 'aa01735fd4b206ee1e83c2290e9283b564198aa2'

local r = git.repo.new('.')
local c = r:commit(commit)

print('Commit', commit)
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
print()

function print_tree(tree, path)
	path = path or '.'
	for name, type, entry in tree:entries() do
		print(git.util.join_path(path, name), type)
		if type == 'tree' then
			print_tree(entry, git.util.join_path(path, name))
		end
	end
end

local tree = pc:tree()
print_tree(tree)

print()
print(tree['git.lua']:content())
