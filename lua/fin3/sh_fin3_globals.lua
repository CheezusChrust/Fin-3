Fin3 = Fin3 or {}

Fin3.allowedClasses = {
    prop_physics = true,
    primitive_shape = true,
    primitive_airfoil = true,
    sent_prop2mesh = true,
    sent_prop2mesh_legacy = true
}

if SERVER then
    Fin3.airDensity = 1.225 -- kg/m^3
    Fin3.finEfficiency = 0.9   -- 0.9 is a magic arbitrarily chosen number, sue me
                                -- Used for calculating induced drag coefficient

    Fin3.fins = {}
    Fin3.propellers = {}

    Fin3.playerFinCount = Fin3.playerFinCount or {}
    CreateConVar("sbox_max_fin3", "20", FCVAR_ARCHIVE, "Maximum number of entities with Fin3 each player can have", 0)

    Fin3.playerPropellerCount = Fin3.playerPropellerCount or {}
    CreateConVar("sbox_max_fin3_propellers", "20", FCVAR_ARCHIVE, "Maximum number of entities with Fin3 propellers each player can have", 0)

    util.AddNetworkString("fin3_networkfinids")
    util.AddNetworkString("fin3_networkpropellerids")
else
    CreateClientConVar("fin3_fintype", "symmetrical", false, true, "The type of airfoil to use for the fin")
    CreateClientConVar("fin3_efficiency", "1", false, true, "The multiplier for the lift and drag forces", 0.1, 1.5)
    CreateClientConVar("fin3_zeroliftangle", "2", false, true, "The negative angle of attack at which the fin produces no lift", 1, 8)
    CreateClientConVar("fin3_induceddrag", "1", false, true, "The multiplier for induced drag", 0, 1)
    CreateClientConVar("fin3_lowpass", "0", false, true, "Whether or not to apply a low-pass filter to the fin's calculations", 0, 1)

    CreateClientConVar("fin3_debug", "0", false, true, "Whether or not to draw debug information on all fins owned by you", 0, 1)
    CreateClientConVar("fin3_debug_showvectors", "1", true, true, "Whether or not to draw the lift and drag vectors", 0, 1)
    CreateClientConVar("fin3_debug_showforces", "1", true, true, "Whether or not to display forces applied for lift and drag", 0, 1)

    CreateClientConVar("fin3_propeller_bladecount", "2", false, true, "The number of blades on the propeller", 2, 6)
    CreateClientConVar("fin3_propeller_diameter", "2", false, true, "The diameter of the propeller, in meters", 0.1, 6)
    CreateClientConVar("fin3_propeller_bladeangle", "15", false, true, "The angle of the blades on the propeller, in degrees", 0, 90)
    CreateClientConVar("fin3_propeller_invert", "0", false, true, "If enabled, propeller will produce thrust when rotating counter clockwise when viewed from the back", 0, 1)
    CreateClientConVar("fin3_propeller_debug", "0", false, true, "Whether or not to draw debug information on all propellers owned by you", 0, 1)
    CreateClientConVar("fin3_propeller_debug_showvectors", "1", true, true, "Whether or not to draw the lift and drag vectors", 0, 1)
    CreateClientConVar("fin3_propeller_debug_showforces", "1", true, true, "Whether or not to display forces applied for lift and drag", 0, 1)
end