include("fin3/sh_fin3_globals.lua")
include("fin3/sh_fin3_models.lua")
include("fin3/sh_fin3_util.lua")

if SERVER then
    include("fin3/sv_fin3.lua")
    include("fin3/sv_fin3_propeller.lua")
    AddCSLuaFile("fin3/cl_fin3_hud.lua")
    AddCSLuaFile("fin3/sh_fin3_globals.lua")
    AddCSLuaFile("fin3/sh_fin3_util.lua")
    AddCSLuaFile("fin3/sh_fin3_models.lua")
    resource.AddFile("resource/localization/en/fin3.properties")
else
    include("fin3/cl_fin3_hud.lua")
end