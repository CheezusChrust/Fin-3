E2Lib.RegisterExtension("fin3", true)

local clamp = math.Clamp

__e2setcost(1)

-- Fin functions
do
    [nodiscard]
    e2function number entity:fin3GetAngleOfAttack()
        local fin = Fin3.fins[this]
        if not IsValid(this) or not fin then return 0 end

        return fin.angleOfAttack
    end
end

-- Propeller functions
do
    e2function void entity:fin3SetBladePitch(number bladePitch)
        local propeller = Fin3.propellers[this]
        if not IsValid(this) or not propeller then return end

        bladePitch = clamp(bladePitch, -90, 90)

        propeller.ent:SetNW2Float("fin3_propeller_bladePitch", bladePitch)
        
        if propeller.invertRotation then
            bladePitch = -bladePitch
        end

        propeller.bladePitch = bladePitch
    end

    [nodiscard]
    e2function number entity:fin3GetBladePitch()
        local propeller = Fin3.propellers[this]
        if not IsValid(this) or not propeller then return 0 end

        return propeller.invertRotation and -propeller.bladePitch or propeller.bladePitch
    end

    [nodiscard]
    e2function number entity:fin3GetPropellerRPM()
        local propeller = Fin3.propellers[this]
        if not IsValid(this) or not propeller then return 0 end

        return propeller.invertRotation and -propeller.rpm or propeller.rpm
    end
end