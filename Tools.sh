#!/bin/sh
./Tools/lua.exe Tools/client.lua > Server/lualib/proto/client.lua
./Tools/lua.exe Tools/cluster.lua > Server/lualib/proto/cluster.lua
./Tools/lua.exe Tools/client.lua > Client/Assets/Scripts/Lua/proto.lua

./Tools/lua.exe Tools/client.lua > /z/code/SomeGame/Server/lualib/proto/client.lua
./Tools/lua.exe Tools/cluster.lua > /z/code/SomeGame/Server/lualib/proto/cluster.lua
