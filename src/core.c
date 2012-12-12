#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

int luaopen_git_core(lua_State *L)
{
	lua_createtable(L, 0, 0);
	init_bit(L);
	init_zlib(L);
	init_sha(L);
	return 1;
}
