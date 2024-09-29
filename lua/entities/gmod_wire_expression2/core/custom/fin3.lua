E2Lib.RegisterExtension("fin3", true)

local clamp = math.Clamp

__e2setcost(1)

e2function void entity:fin3SetBladeAngle(number bladeAngle)
    local propeller = Fin3.propellers[this]
    if not IsValid(this) or not propeller then return end

    bladeAngle = clamp(bladeAngle, -90, 90)

    propeller.ent:SetNW2Float("fin3_propeller_bladeAngle", bladeAngle)
    
    if propeller.invertRotation then
        bladeAngle = -bladeAngle
    end

    propeller.bladeAngle = bladeAngle
end

[nodiscard]
e2function number entity:fin3GetBladeAngle()
    local propeller = Fin3.propellers[this]
    if not IsValid(this) or not propeller then return 0 end

    return propeller.invertRotation and -propeller.bladeAngle or propeller.bladeAngle
end