local floor, ceil, abs = math.floor, math.ceil, math.abs

function Fin3.sign(x)
    return x > 0 and 1 or x < 0 and -1 or 0
end

--- Calculates a value along a Catmull-Rom spline
---@param points table Table of points to interpolate
---@param pos number Position to interpolate at
---@return number
function Fin3.calcCatRomSpline(points, pos)
    local count = #points

    if count < 3 then return 0 end

    if pos <= points[1].x then
        return points[1].y
    elseif pos >= points[count].x then
        return points[count].y
    end

    local left, right = 1, count
    while left + 1 < right do
        local mid = math.floor((left + right) / 2)
        if pos < points[mid].x then
            right = mid
        else
            left = mid
        end
    end

    local current = left

    local t  = (pos - points[current].x) / (points[current + 1].x - points[current].x)
    local p0 = points[current - 1] and points[current - 1].y or points[current].y
    local p1 = points[current].y
    local p2 = points[current + 1].y
    local p3 = points[current + 2] and points[current + 2].y or points[current + 1].y

    return 0.5 * ((2 * p1) +
        (p2 - p0) * t +
        (2 * p0 - 5 * p1 + 4 * p2 - p3) * t ^ 2 +
        (3 * p1 - p0 - 3 * p2 + p3) * t ^ 3)
end

function Fin3.createInterpolatedCurves()
    for _, model in pairs(Fin3.models) do
        if not model.interpolatedCurves then
            model.interpolatedCurves = {}
        end

        for curveType, curveData in pairs(model.curves) do
            local interpolated = {}

            for i = -90, 90 do
                if model.isCambered then
                    interpolated[#interpolated + 1] = Fin3.calcCatRomSpline(curveData, i)
                else
                    local curveSign = (curveType == "lift" and Fin3.sign(i) or 1)
                    interpolated[#interpolated + 1] = Fin3.calcCatRomSpline(curveData, abs(i)) * curveSign
                end
            end

            model.interpolatedCurves[curveType] = interpolated
        end
    end
end

Fin3.createInterpolatedCurves()

--- Calculates a value on an array of points using linear interpolation
---@param points table Table of points to interpolate
---@param pos number Position to interpolate at
---@return number
function Fin3.calcLinearInterp(points, pos)
    local curValue = points[floor(pos)] or points[1]
    local nextValue = points[ceil(pos)] or points[#points]

    local perc = pos % 1

    return Lerp(perc, curValue, nextValue)
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

    --- Gets the linear velocity at a point on a rotating object
    ---@param phys PhysObj Physics object
    ---@param pos Vector Position to get the velocity at, in local space
    ---@return Vector
    function Fin3.getRotInducedVel(phys, pos)
        if not IsValid(phys) then return Vector() end

        local p = pos - phys:GetMassCenter()
        local v = (phys:GetAngleVelocity() * 0.0174533):Cross(p)
        v = Fin3.localToWorldVector(phys:GetEntity(), v)
        return v
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
else
    function Fin3.requestAllFins()
        net.Start("fin3_networkfinids")
        net.SendToServer()
    end
end