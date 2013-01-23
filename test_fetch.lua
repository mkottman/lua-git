package.path = package.path .. ';lua/?.lua'
package.cpath = package.cpath .. ';b/?.so'

require 'git'

local repoUrl = arg[1] or 'git://github.com/mkottman/lua-git.git'
local ref = arg[2] or 'refs/heads/master'

os.execute('rm -rf /tmp/test.git')
os.execute('rm -rf /tmp/extracted')

R = git.repo.create('/tmp/test.git')
local pack, sha = git.protocol.fetch(repoUrl, R, ref)
R:checkout(sha, '/tmp/extracted')
