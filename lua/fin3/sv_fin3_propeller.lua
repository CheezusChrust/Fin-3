local sin, cos, tan, atan2 = math.sin, math.cos, math.tan, math.atan2
local pi = math.pi
local abs, sign = math.abs, Fin3.sign
local sqrt = math.sqrt
local calcLinearInterp = Fin3.calcLinearInterp
local dt = engine.TickInterval()
local rad2deg = 180 / pi
local deg2rad = pi / 180

Fin3.propeller = {}

--[[
Propeller creation data table structure:
    forwardAxis: vector
    bladeCount: number [2 - 6]
    diameter: number [0.1 - 6]
    bladeAngle: number [0 - 90]
    invertRotation: boolean
--]]

--- Adds a new propeller to an entity
---@param ply Player Player that created the propeller
---@param ent Entity Entity to add the propeller to
---@param data table Propeller creation data table
function Fin3.propeller:new(ply, ent, data)
    local propeller = setmetatable({}, {__index = self})

    if not Fin3.propellers[ent] then
        local propellerLimit = GetConVar("sbox_max_fin3_propellers"):GetInt()
        local currentPropellerCount = Fin3.playerPropellerCount[ply] or 0

        if currentPropellerCount >= propellerLimit then
            ply:LimitHit("Fin3_Propeller")

            return
        end

        Fin3.playerPropellerCount[ply] = currentPropellerCount + 1
    end

    local phys = ent:GetPhysicsObject()

    if not IsValid(ent) or not IsValid(phys) or not Fin3.allowedClasses[ent:GetClass()] then return end

    propeller.ent = ent
    propeller.phys = phys
    propeller.owner = ply
    propeller.forwardAxis = data.forwardAxis
    propeller.bladeCount = data.bladeCount
    propeller.diameter = data.diameter
    propeller.radius = data.diameter / 2
    propeller.bladeArea = propeller.radius * (propeller.radius / 7) -- Aspect ratio of 7, make adjustable in the future?
    propeller.bladeAngle = data.bladeAngle
    propeller.invertRotation = data.invertRotation

    --propeller:calcPropellerData()

    phys:EnableDrag(false)
    phys:SetDamping(0, 0)

    ent:SetNW2Int("fin3_propeller_bladeCount", propeller.bladeCount)
    ent:SetNW2Float("fin3_propeller_diameter", propeller.diameter)
    ent:SetNW2Float("fin3_propeller_bladeAngle", propeller.bladeAngle)
    ent:SetNW2Bool("fin3_propeller_invertRotation", propeller.invertRotation)

    Fin3.propellers[ent] = propeller

    --Fin3.transmitFin(ent)

    duplicator.StoreEntityModifier(ent, "fin3_propeller", data)

    return propeller
end

--function Fin3.propeller:calcPropellerData()
    --self.pitch = pi * 0.75 * self.diameter * tan(self.bladeAngle * deg2rad)
--end

function Fin3.propeller:calcAoA(forwardVel, radialVel)
    local airflowAngle = (atan2(forwardVel, radialVel) * rad2deg + 90) % 360 - 180 -- Airflow angle relative to propeller forwards
    local alpha = (airflowAngle + self.bladeAngle - 270) % 360 - 180 -- Angle of attack of blades

    return airflowAngle, alpha
end

function Fin3.propeller:calcCoefficients(alpha)
    local liftCoef
    local dragCoef

    alpha = abs(alpha)

    if alpha < 90 then
        liftCoef = calcLinearInterp(Fin3.models.symmetrical.interpolatedCurves.lift, alpha + 91)
        dragCoef = calcLinearInterp(Fin3.models.symmetrical.interpolatedCurves.drag, alpha + 91)
    else
        liftCoef = calcLinearInterp(Fin3.models.flat.interpolatedCurves.lift, 271 - alpha)
        dragCoef = calcLinearInterp(Fin3.models.flat.interpolatedCurves.drag, 271 - alpha)
    end

    return liftCoef, dragCoef
end

function Fin3.propeller:calcForces(airspeed, alpha, liftCoef, dragCoef)
    local aeroForce = 0.5 * Fin3.airDensity * self.bladeArea * self.bladeCount * airspeed^2
    local liftForceNewtons = liftCoef * aeroForce * sign(alpha)
    local dragForceNewtons = dragCoef * aeroForce

    return liftForceNewtons, dragForceNewtons
end

function Fin3.propeller:calcForceComponents(liftForceNewtons, dragForceNewtons, airflowAngle)
    local bladeAngle = self.bladeAngle
    local forwardLiftComponent = abs(cos(bladeAngle * deg2rad)) * liftForceNewtons
    local radialLiftComponent = abs(sin(bladeAngle * deg2rad)) * liftForceNewtons
    if invertRotation then radialLiftComponent = -radialLiftComponent end

    local forwardDragComponent = -cos(airflowAngle * deg2rad) * dragForceNewtons
    local radialDragComponent = sin(airflowAngle * deg2rad) * dragForceNewtons

    local finalForwardForceN = forwardLiftComponent + forwardDragComponent
    local finalTorqueNm = (radialLiftComponent + radialDragComponent) * self.radius * 0.75

    return finalForwardForceN, finalTorqueNm
end

function Fin3.propeller:think()
    local ent = self.ent
    local phys = self.phys

    if not IsValid(self.phys) or self.phys ~= ent:GetPhysicsObject() then
        local newPhys = ent:GetPhysicsObject()
        self.phys = newPhys

        if not IsValid(newPhys) then return end
    end

    local forwardAxis = self.forwardAxis
    local forwardVel = ent:WorldToLocal(ent:GetVelocity() + ent:GetPos()):Dot(forwardAxis) / 39.3701 -- m/s
    local rotVel = -phys:GetAngleVelocity():Dot(forwardAxis) -- deg/s
    local radialVel = (rotVel * deg2rad) * self.radius * 0.75
    -- local idealVel = propPitch * (-rotVel / 360) -- Theoretical vel in m/s based on prop pitch and rotational velocity
    -- local slipVel = idealVel - forwardVel -- Slip velocity in m/s
    local airspeed = abs(sqrt(forwardVel^2 + radialVel^2)) -- Effective airspeed over the blade at 75% position

    local airflowAngle, alpha = self:calcAoA(forwardVel, radialVel)
    local liftCoef, dragCoef = self:calcCoefficients(alpha)
    local liftForceNewtons, dragForceNewtons = self:calcForces(airspeed, alpha, liftCoef, dragCoef)
    local finalForwardForceN, finalTorqueNm = self:calcForceComponents(liftForceNewtons, dragForceNewtons, airflowAngle)

    local worldForward = Fin3.localToWorldVector(ent, forwardAxis)
    phys:ApplyForceCenter(worldForward * finalForwardForceN * 39.3701 * dt)
    phys:ApplyTorqueCenter(worldForward * -finalTorqueNm * rad2deg * dt)
end

function Fin3.propeller:remove()
    local ent = self.ent

    if IsValid(ent) then
        ent:SetNW2Int("fin3_propeller_bladeCount", nil)
        ent:SetNW2Float("fin3_propeller_diameter", nil)
        ent:SetNW2Float("fin3_propeller_bladeAngle", nil)
        ent:SetNW2Bool("fin3_propeller_invertRotation", nil)

        local phys = ent:GetPhysicsObject()

        if IsValid(phys) then
            phys:EnableDrag(true)
        end
    end

    Fin3.propellers[ent] = nil

    local owner = self.owner
    local propellerCount = Fin3.playerPropellerCount[owner]
    if IsValid(owner) and propellerCount then
        Fin3.playerPropellerCount[owner] = propellerCount - 1
    end

    duplicator.ClearEntityModifier(self.ent, "fin3_propeller")
end

hook.Add("Think", "fin3_propellerthink", function()
    for _, propeller in pairs(Fin3.propellers) do
        if not IsValid(propeller.ent) then
            propeller:remove()
        else
            propeller:think()
        end
    end
end)