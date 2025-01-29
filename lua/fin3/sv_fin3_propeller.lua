local sin, cos, atan2 = math.sin, math.cos, math.atan2
local pi = math.pi
local abs, sign = math.abs, Fin3.sign
local sqrt = math.sqrt
local dt = engine.TickInterval()
local rad2deg = 180 / pi
local deg2rad = pi / 180

Fin3.propeller = {}

--[[
Propeller creation data table structure:
    forwardAxis: vector
    bladeCount: number [2 - 6]
    diameter: number [0.1 - 6]
    bladePitch: number [0 - 90]
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
    propeller.bladePitch = data.bladePitch
    propeller.invertRotation = data.invertRotation

    propeller.rpm = 0
    propeller.lastTorque = 0
    propeller.lastForce = 0

    if data.invertRotation then
        propeller.bladePitch = -propeller.bladePitch
    end

    --propeller:calcPropellerData()

    phys:EnableDrag(false)
    phys:SetDamping(0, 0)

    ent:SetNW2Vector("fin3_propeller_forwardAxis", propeller.forwardAxis)
    ent:SetNW2Int("fin3_propeller_bladeCount", propeller.bladeCount)
    ent:SetNW2Float("fin3_propeller_diameter", propeller.diameter)
    ent:SetNW2Float("fin3_propeller_bladePitch", propeller.invertRotation and -propeller.bladePitch or propeller.bladePitch)
    ent:SetNW2Bool("fin3_propeller_invertRotation", propeller.invertRotation)

    Fin3.propellers[ent] = propeller

    Fin3.transmitPropeller(ent)

    duplicator.StoreEntityModifier(ent, "fin3_propeller", data)

    return propeller
end

duplicator.RegisterEntityModifier("fin3_propeller", function(...)
    Fin3.propeller:new(...)
end)

--function Fin3.propeller:calcPropellerData()
    --self.pitch = pi * 0.75 * self.diameter * tan(self.bladePitch * deg2rad)
--end

function Fin3.propeller:calcAoA(forwardVel, radialVel)
    local airflowAngle = (atan2(forwardVel, radialVel) * rad2deg + 90) % 360 - 180 -- Airflow angle relative to propeller forwards
    local alpha = (airflowAngle + self.bladePitch - 270) % 360 - 180 -- Angle of attack of blades

    if self.invertRotation then
        alpha = -(alpha % 360 - 180)
    end

    return airflowAngle, alpha
end

function Fin3.propeller:calcCoefficients(alpha)
    local liftCoef
    local dragCoef
    local propModel = Fin3.models.propeller
    local flatModel = Fin3.models.flat

    alpha = abs(alpha)

    if alpha < 90 then
        liftCoef = Fin3.calcLiftCoef(alpha, propModel.stallAngle, propModel.liftCoefPeakPreStall, propModel.liftCoefPeakPostStall)
        dragCoef = Fin3.calcDragCoef(alpha, propModel.stallAngle, propModel.dragCoefPeakPreStall, propModel.dragCoefPeakPostStall)
    else
        liftCoef = Fin3.calcLiftCoef(180 - alpha, flatModel.stallAngle, flatModel.liftCoefPeakPreStall, flatModel.liftCoefPeakPostStall)
        dragCoef = Fin3.calcDragCoef(180 - alpha, flatModel.stallAngle, flatModel.dragCoefPeakPreStall, flatModel.dragCoefPeakPostStall)
    end

    --print("Lift Coef: " .. math.Round(liftCoef, 2), "Drag Coef: " .. math.Round(dragCoef, 2))

    return liftCoef, dragCoef
end

function Fin3.propeller:calcForces(airspeed, alpha, liftCoef, dragCoef)
    local aeroForce = 0.5 * Fin3.airDensity * self.bladeArea * self.bladeCount * airspeed^2
    local liftForceNewtons = liftCoef * aeroForce * sign(alpha)
    local dragForceNewtons = dragCoef * aeroForce

    return liftForceNewtons, dragForceNewtons
end

function Fin3.propeller:calcForceComponents(liftForceNewtons, dragForceNewtons, airflowAngle, alpha)
    local bladePitch = self.bladePitch
    local forwardLiftComponent = abs(cos(bladePitch * deg2rad)) * liftForceNewtons
    local radialLiftComponent = abs(sin(bladePitch * deg2rad)) * liftForceNewtons * sign(bladePitch)

    local forwardDragComponent = -cos(airflowAngle * deg2rad) * dragForceNewtons
    local radialDragComponent = sin(alpha / rad2deg) * dragForceNewtons * sign(bladePitch)

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
    local finalForwardForceN, finalTorqueNm = self:calcForceComponents(liftForceNewtons, dragForceNewtons, airflowAngle, alpha)

    -- Low pass filter to try to dampen any unwanted oscillations in low inertia/weight situations
    finalForwardForceN = self.lastForce * 0.6 + finalForwardForceN * 0.4
    finalTorqueNm = self.lastTorque * 0.6 + finalTorqueNm * 0.4

    local rpm = -rotVel / 6
    self.rpm = rpm
    self.lastForce = finalForwardForceN
    self.lastTorque = finalTorqueNm

    ent:SetNW2Float("fin3_propeller_thrust", finalForwardForceN)
    ent:SetNW2Float("fin3_propeller_torque", finalTorqueNm)
    ent:SetNW2Float("fin3_propeller_aoa", alpha)
    ent:SetNW2Float("fin3_propeller_rpm", rpm)

    local worldForward = Fin3.localToWorldVector(ent, forwardAxis)
    phys:ApplyForceCenter(worldForward * finalForwardForceN * 39.3701 * dt)
    phys:ApplyTorqueCenter(worldForward * -finalTorqueNm * rad2deg * dt)
end

function Fin3.propeller:remove()
    local ent = self.ent

    if IsValid(ent) then
        ent:SetNW2Vector("fin3_propeller_forwardAxis", nil)
        ent:SetNW2Int("fin3_propeller_bladeCount", nil)
        ent:SetNW2Float("fin3_propeller_diameter", nil)
        ent:SetNW2Float("fin3_propeller_bladePitch", nil)
        ent:SetNW2Bool("fin3_propeller_invertRotation", nil)
        ent:SetNW2Float("fin3_propeller_thrust", nil)
        ent:SetNW2Float("fin3_propeller_torque", nil)
        ent:SetNW2Float("fin3_propeller_aoa", nil)
        ent:SetNW2Float("fin3_propeller_rpm", nil)

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

hook.Add("Tick", "fin3_propellerthink", function()
    for _, propeller in pairs(Fin3.propellers) do
        if not IsValid(propeller.ent) then
            propeller:remove()
        else
            propeller:think()
        end
    end
end)

net.Receive("fin3_networkpropellerids", function(_, ply)
    Fin3.transmitAllPropellers(ply)
end)
