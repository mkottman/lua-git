package.path = package.path .. ';lua/?.lua'
package.cpath = package.cpath .. ';b/?.so'

require 'git'

local repoUrl = arg[1] or 'git://github.com/mkottman/lua-git.git'

local refs = git.protocol.remotes(repoUrl)
for name, sha in pairs(refs) do
	print(name, sha)
end
