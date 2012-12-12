package.path = package.path .. ';lua/?.lua'
package.cpath = package.cpath .. ';b/?.so'

require 'git'

os.execute('rm -rf /tmp/test.git')
os.execute('rm -rf /tmp/extracted')

R = git.repo.create('/tmp/test.git')
local pack, sha = git.protocol.fetch('git://github.com/mkottman/lua-git.git', R, 'refs/heads/master')
R:commit(sha):checkout('/tmp/extracted')