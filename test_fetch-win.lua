require 'git'

os.execute('rd /S /Q C:\\tmp\\test.git')
os.execute('rd /S /Q C:\\tmp\\extracted')

R = git.repo.create('C:\\tmp\\test.git')
local pack, sha = git.protocol.fetch('git://github.com/mkottman/lua-git.git', R, 'refs/heads/master')
R:checkout(sha, 'C:\\tmp\\extracted')
