--- Library for interfacing with Fin 3
-- @name fin3
-- @class library
-- @libtbl fin3_library

SF.RegisterLibrary("fin3")

local checkluatype = SF.CheckLuaType
local clamp = math.Clamp

return function(instance)

local ents_meta = instance.Types.Entity
local ents_methods, unwrap = ents_meta.Methods, ents_meta.Unwrap

-- Fin functions
do
    --- Returns the angle of attack of a Fin 3 fin
    -- @server
    -- @return number Angle of attack, in degrees
    function ents_methods:fin3GetAngleOfAttack()
        local fin = Fin3.fins[unwrap(self)]
        if not fin then return 0 end

        return fin.angleOfAttack
    end
end

-- Propeller functions
do
    --- Sets the angle of a Fin 3 propeller's blades
    -- @server
    -- @param pitch number Blade pitch, in degrees
    function ents_methods:fin3SetBladePitch(pitch)
        checkluatype(pitch, TYPE_NUMBER)
        local this = unwrap(self)
        local propeller = Fin3.propellers[this]
        if not propeller then return end

        pitch = clamp(pitch, -90, 90)

        this:SetNW2Float("fin3_propeller_bladePitch", pitch)

        if propeller.invertRotation then
            pitch = -pitch
        end

        propeller.bladePitch = pitch
    end

    --- Returns the angle of a Fin 3 propeller's blades
    -- @server
    -- @return number Blade pitch, in degrees
    function ents_methods:fin3GetBladePitch()
        local propeller = Fin3.propellers[unwrap(self)]
        if not propeller then return 0 end

        return propeller.invertRotation and -propeller.bladePitch or propeller.bladePitch
    end

    --- Returns the RPM of a Fin 3 propeller
    -- @server
    -- @return number RPM
    function ents_methods:fin3GetPropellerRPM()
        local propeller = Fin3.propellers[unwrap(self)]
        if not propeller then return 0 end

        return propeller.rpm
    end
end

end