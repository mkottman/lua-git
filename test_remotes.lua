package.path = package.path .. ';lua/?.lua'
package.cpath = package.cpath .. ';b/?.so'

require 'git'

local refs = git.protocol.remotes('git://github.com/LuaDist/lua.git')
for name, sha in pairs(refs) do
	print(name, sha)
end
