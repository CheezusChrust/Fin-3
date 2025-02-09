local abs = math.abs
local sin, pi = math.sin, math.pi
local min, max = math.min, math.max

function Fin3.sign(x)
    return x > 0 and 1 or x < 0 and -1 or 0
end

local sign = Fin3.sign

--- Calculates the lift coefficient of a wing given the basic parameters
--- https://www.desmos.com/calculator/xgpli0tqha
--- @param angleOfAttack number Angle of attack in degrees
--- @param stallAngle number Angle at which the wing stalls in degrees
--- @param coefPeakPreStall number Coefficient of lift at the stall angle
--- @param coefPeakPostStall number Coefficient of lift at 45 degrees AoA
function Fin3.calcLiftCoef(angleOfAttack, stallAngle, coefPeakPreStall, coefPeakPostStall)
    if angleOfAttack < stallAngle * 0.75 then -- Linear rise
        return (angleOfAttack / stallAngle) * 1.138 * coefPeakPreStall
    elseif angleOfAttack < stallAngle then -- Gradual peak
        return sin((angleOfAttack * pi) / (stallAngle * 2)) ^ 2 * coefPeakPreStall
    elseif angleOfAttack < 45 then -- Drop into post stall dynamics
        local immediatePost = -(angleOfAttack - stallAngle) ^ 2 * 0.05 + coefPeakPreStall
        local postStallFactor = 1 - min(coefPeakPreStall / coefPeakPostStall, 1.25)
        local flatPre45 = sin((angleOfAttack * pi) / 90) ^ postStallFactor * coefPeakPostStall

        return max(immediatePost, flatPre45)
    else -- Deep stall, 45 to 90 degrees
        return sin((angleOfAttack * pi) / 90) * coefPeakPostStall
    end
end

--- Calculates the drag coefficient of a wing given the basic parameters
--- https://www.desmos.com/calculator/p6sd97dpwi
--- @param angleOfAttack number Angle of attack in degrees
--- @param stallAngle number Angle at which the wing stalls in degrees
--- @param coefPeakPreStall number Coefficient of drag at the stall angle
--- @param coefPeakPostStall number Coefficient of drag at 90 degrees AoA
function Fin3.calcDragCoef(angleOfAttack, stallAngle, coefPeakPreStall, coefPeakPostStall)
    if angleOfAttack < stallAngle then
        return angleOfAttack / stallAngle * coefPeakPreStall
    else
        local immediatePost = 0.1 * angleOfAttack + (coefPeakPreStall - 0.1 * stallAngle)
        local flat = sin((angleOfAttack * pi) / 180) * coefPeakPostStall

        return min(immediatePost, flat)
    end
end

-- Vector functions
do
    --- Rounds a direction vector to the nearest cardinal axis
    ---@param v Vector Direction vector
    ---@return Vector
    function Fin3.roundVectorToAxis(v)
        local absX, absY, absZ = abs(v.x), abs(v.y), abs(v.z)

        if absX >= absY and absX >= absZ then
            return Vector(Fin3.sign(v.x), 0, 0)
        elseif absY >= absX and absY >= absZ then
            return Vector(0, Fin3.sign(v.y), 0)
        else
            return Vector(0, 0, Fin3.sign(v.z))
        end
    end

    function Fin3.localToWorldVector(ent, v)
        return ent:LocalToWorld(v) - ent:GetPos()
    end

    function Fin3.worldToLocalVector(ent, v)
        return ent:WorldToLocal(v + ent:GetPos())
    end

    function Fin3.projectVector(v, normal)
        return v - v:Dot(normal) * normal
    end
end

if SERVER then
    function Fin3.getRootParent(ent)
        local parent = ent:GetParent()

        if IsValid(parent) then
            return Fin3.getRootParent(parent)
        else
            return ent
        end
    end

    -- https://github.com/Facepunch/garrysmod-issues/issues/5159
    local m_in_sq = 1 / 39.37 ^ 2 -- in^2 to m^2
    local const = m_in_sq * 360 / (2 * 3.1416)
    function Fin3.applyForceOffsetFixed(phys, force, pos)
        phys:ApplyForceCenter(force)

        local off = pos - phys:LocalToWorld(phys:GetMassCenter())
        local angf = off:Cross(force) * const

        phys:ApplyTorqueCenter(angf)
    end

    function Fin3.transmitFin(ent)
        net.Start("fin3_networkfinids")
        net.WriteUInt(1, 10)
        net.WriteUInt(ent:EntIndex(), 13)
        net.Broadcast()
    end

    function Fin3.transmitAllFins(ply)
        net.Start("fin3_networkfinids")
        net.WriteUInt(table.Count(Fin3.fins), 10)

        for _, fin in pairs(Fin3.fins) do
            net.WriteUInt(fin.ent:EntIndex(), 13)
        end

        net.Send(ply)
    end

    function Fin3.transmitPropeller(ent)
        net.Start("fin3_networkpropellerids")
        net.WriteUInt(1, 10)
        net.WriteUInt(ent:EntIndex(), 13)
        net.Broadcast()
    end

    function Fin3.transmitAllPropellers(ply)
        net.Start("fin3_networkpropellerids")
        net.WriteUInt(table.Count(Fin3.propellers), 10)

        for _, propeller in pairs(Fin3.propellers) do
            net.WriteUInt(propeller.ent:EntIndex(), 13)
        end

        net.Send(ply)
    end

    function Fin3.calcCenterOfLift(contraption)
        local centerOfLift = vector_origin
        local totalArea = 0

        local ents = istable(contraption) and contraption.ents or {[contraption] = true}

        for ent in pairs(ents) do
            local fin = Fin3.fins[ent]

            if fin then
                local pos = fin.ent:LocalToWorld(fin.massCenter)
                local area = fin.surfaceArea * fin.efficiency
                local upAxisWorld = Fin3.localToWorldVector(fin.ent, fin.upAxis)
                local upFactor = sign(upAxisWorld:Dot(vector_up)) -- Only factor in the up facing components

                centerOfLift = centerOfLift + pos * area * upFactor
                totalArea = totalArea + area * upFactor
            end
        end

        if totalArea > 0 then
            centerOfLift = centerOfLift / totalArea
        end

        return centerOfLift
    end
else
    function Fin3.requestAllFins()
        net.Start("fin3_networkfinids")
        net.SendToServer()
    end
    function Fin3.requestAllPropellers()
        net.Start("fin3_networkpropellerids")
        net.SendToServer()
    end
end