# Copyright (C) 2012 LuaDist.
# Created by Michal Kottman
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

project ( lua-git C )
cmake_minimum_required ( VERSION 2.8 )
include ( cmake/dist.cmake )
include ( lua )

find_package ( ZLIB )

set ( SRC src/bit.c src/core.c src/sha.c src/zlib.c )
set ( LIB ${ZLIB_LIBRARIES} )

# Binary
install_lua_module ( git.core ${SRC} LINK ${LIB} )
# Lua 
install_lua_module ( git lua/git.lua )
install_lua_module ( git.objects lua/git/objects.lua )
install_lua_module ( git.pack lua/git/pack.lua )
install_lua_module ( git.protocol lua/git/protocol.lua )
install_lua_module ( git.repo lua/git/repo.lua )
install_lua_module ( git.util lua/git/util.lua )
