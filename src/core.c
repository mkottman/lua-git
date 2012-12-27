#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

void init_bit(lua_State *L);
void init_sha(lua_State *L);
void init_zlib(lua_State *L);

int luaopen_git_core(lua_State *L)
{
	lua_createtable(L, 0, 0);
	init_bit(L);
	init_sha(L);
	init_zlib(L);
	return 1;
}
