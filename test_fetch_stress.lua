package.path = package.path .. ';lua/?.lua'
package.cpath = package.cpath .. ';b/?.so'

require 'git'

local n = arg[1] or 100
local repoUrl = arg[2] or 'git://github.com/mkottman/lua-git.git'
local ref = arg[3] or 'refs/heads/master'

for i=1,n do
	os.execute('rm -rf /tmp/test.git')
	os.execute('rm -rf /tmp/extracted')

	R = git.repo.create('/tmp/test.git')
	local pack, sha = git.protocol.fetch(repoUrl, R, ref)
	R:checkout(sha, '/tmp/extracted')
	R:close()
end
