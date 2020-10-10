// CC0/Unlicense system32 2020

#include "lua_api/l_clientobject.h"
#include "l_internal.h"
#include "common/c_converter.h"
#include "client/client.h"
#include "object_properties.h"


ClientObjectRef *ClientObjectRef::checkobject(lua_State *L, int narg)
{
    luaL_checktype(L, narg, LUA_TUSERDATA);
    void *userdata = luaL_checkudata(L, narg, className);
    if (!userdata)
        luaL_typerror(L, narg, className);
    return *(ClientObjectRef**)userdata;
}

ClientActiveObject *ClientObjectRef::get_cao(ClientObjectRef *ref)
{
    ClientActiveObject *obj = ref->m_object;
    return obj;
}

GenericCAO *ClientObjectRef::get_generic_cao(ClientObjectRef *ref, lua_State *L)
{
    ClientActiveObject *obj = get_cao(ref);
    ClientEnvironment &env = getClient(L)->getEnv();
    GenericCAO *gcao = env.getGenericCAO(obj->getId());
    return gcao;
}

int ClientObjectRef::l_get_pos(lua_State *L)
{
    ClientObjectRef *ref = checkobject(L, 1);
    ClientActiveObject *cao = get_cao(ref);
    push_v3f(L, cao->getPosition() / BS);
    return 1;
}

int ClientObjectRef::l_is_player(lua_State *L)
{
    ClientObjectRef *ref = checkobject(L, 1);
    GenericCAO *gcao = get_generic_cao(ref, L);
    lua_pushboolean(L, gcao->isPlayer());
    return 1;
}

int ClientObjectRef::l_get_name(lua_State *L)
{
    ClientObjectRef *ref = checkobject(L, 1);
    GenericCAO *gcao = get_generic_cao(ref, L);
    lua_pushstring(L, gcao->getName().c_str());
    return 1;
}

int ClientObjectRef::l_get_parent(lua_State *L)
{
    ClientObjectRef *ref = checkobject(L, 1);
    GenericCAO *gcao = get_generic_cao(ref, L);
    create(L, gcao->getParent());
    return 1;
}

int ClientObjectRef::l_get_nametag(lua_State *L)
{
    ClientObjectRef *ref = checkobject(L, 1);
    GenericCAO *gcao = get_generic_cao(ref, L);
    ObjectProperties *props = gcao->getProperties();
    lua_pushstring(L, props->nametag.c_str());
    return 1;
}

int ClientObjectRef::l_get_textures(lua_State *L)
{
    ClientObjectRef *ref = checkobject(L, 1);
    GenericCAO *gcao = get_generic_cao(ref, L);
    ObjectProperties *props = gcao->getProperties();
    lua_newtable(L);

    for (std::string &texture : props->textures) {
        lua_pushstring(L, texture.c_str());
    }
    return 1;
}

ClientObjectRef::ClientObjectRef(ClientActiveObject *object):
    m_object(object)
{
}

void ClientObjectRef::create(lua_State *L, ClientActiveObject *object)
{
    if (object) {
        ClientObjectRef *o = new ClientObjectRef(object);
        *(void **)(lua_newuserdata(L, sizeof(void *))) = o;
        luaL_getmetatable(L, className);
        lua_setmetatable(L, -2);
    }
}

int ClientObjectRef::gc_object(lua_State *L) {
    ClientObjectRef *obj = *(ClientObjectRef **)(lua_touserdata(L, 1));
    delete obj;
    return 0;
}

// taken from LuaLocalPlayer
void ClientObjectRef::Register(lua_State *L)
{
    lua_newtable(L);
    int methodtable = lua_gettop(L);
    luaL_newmetatable(L, className);
    int metatable = lua_gettop(L);

    lua_pushliteral(L, "__metatable");
    lua_pushvalue(L, methodtable);
    lua_settable(L, metatable); // hide metatable from lua getmetatable()

    lua_pushliteral(L, "__index");
    lua_pushvalue(L, methodtable);
    lua_settable(L, metatable);

    lua_pushliteral(L, "__gc");
    lua_pushcfunction(L, gc_object);
    lua_settable(L, metatable);

    lua_pop(L, 1); // Drop metatable

    luaL_openlib(L, 0, methods, 0); // fill methodtable
    lua_pop(L, 1);                  // Drop methodtable
}

const char ClientObjectRef::className[] = "ClientObjectRef";
luaL_Reg ClientObjectRef::methods[] = {
    luamethod(ClientObjectRef, get_pos),
    luamethod(ClientObjectRef, is_player),
    luamethod(ClientObjectRef, get_name),
    luamethod(ClientObjectRef, get_parent),
    luamethod(ClientObjectRef, get_nametag),
    luamethod(ClientObjectRef, get_textures),
    {0, 0}
};
