// CC0/Unlicense system32 2020

#include "lua_api/l_base.h"
#include "client/clientobject.h"
#include "client/content_cao.h"

class ClientObjectRef : public ModApiBase
{
public:
    ClientObjectRef(ClientActiveObject *object);

    ~ClientObjectRef() = default;

    static void Register(lua_State *L);

    static void create(lua_State *L, ClientActiveObject *object);

    static ClientObjectRef *checkobject(lua_State *L, int narg);

private:
    ClientActiveObject *m_object = nullptr;
    static const char className[];
    static luaL_Reg methods[];

    static ClientActiveObject *get_cao(ClientObjectRef *ref);
    static GenericCAO *get_generic_cao(ClientObjectRef *ref, lua_State *L);

    static int gc_object(lua_State *L);

    // get_pos(self)
    // returns: {x=num, y=num, z=num}
    static int l_get_pos(lua_State *L);

    // get_velocity(self)
    static int l_get_velocity(lua_State *L);

    // get_acceleration(self)
    static int l_get_acceleration(lua_State *L);

    // get_rotation(self)
    static int l_get_rotation(lua_State *L);

    // is_player(self)
    static int l_is_player(lua_State *L);

    // get_name(self)
    static int l_get_name(lua_State *L);

    // get_parent(self)
    static int l_get_parent(lua_State *L);

    // get_nametag(self)
    static int l_get_nametag(lua_State *L);

    // get_textures(self)
    static int l_get_item_textures(lua_State *L);

    // get_hp(self)
    static int l_get_max_hp(lua_State *L);
};
