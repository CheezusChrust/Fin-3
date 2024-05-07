Fin3 = Fin3 or {}

Fin3.allowedClasses = {
    prop_physics = true,
    primitive_shape = true,
    primitive_airfoil = true
}

if SERVER then
    Fin3.airDensity = 1.225 -- kg/m^3
    Fin3.finEfficiency = 0.9   -- 0.9 is a magic arbitrarily chosen number, sue me
                                -- Used for calculating induced drag coefficient

    Fin3.fins = {}

    Fin3.playerFinCount = Fin3.playerFinCount or {}
    CreateConVar("sbox_max_fin3", "20", FCVAR_ARCHIVE, "Maximum number of entities with Fin3 each player can have", 0)

    util.AddNetworkString("fin3_networkfinids")
else
    CreateClientConVar("fin3_fintype", "symmetrical", false, true, "The type of airfoil to use for the fin")
    CreateClientConVar("fin3_efficiency", "1", false, true, "The multiplier for the lift and drag forces", 0.1, 1.5)
    CreateClientConVar("fin3_zeroliftangle", "2", false, true, "The negative angle of attack at which the fin produces no lift", 1, 8)
    CreateClientConVar("fin3_induceddrag", "1", false, true, "The multiplier for induced drag", 0, 1)

    CreateClientConVar("fin3_debug", "0", false, true, "Whether or not to draw debug information on all fins owned by you", 0, 1)
    CreateClientConVar("fin3_debug_showvectors", "1", true, true, "Whether or not to draw the lift and drag vectors", 0, 1)
    CreateClientConVar("fin3_debug_showforces", "1", true, true, "Whether or not to display forces applied for lift and drag", 0, 1)

    surface.CreateFont("fin3_bigtext", {
        font = "Roboto",
        size = 24,
        weight = 850
    })

    surface.CreateFont("fin3_labeltext", {
        font = "Roboto",
        size = 16,
        weight = 550
    })
end