package.path = package.path .. ';lua/?.lua'
package.cpath = package.cpath .. ';b/?.so'

require 'git'

os.execute('rm -rf /tmp/test')
git.repo.create('/tmp/test')

local R = git.repo.open('/tmp/test')
local pack, sha = git.protocol.fetch('git://github.com/LuaDist/Repository.git', R, 'refs/heads/master')
R:checkout(sha)
