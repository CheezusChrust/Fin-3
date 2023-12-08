Fin3.allowedClasses = {
    prop_physics = true,
    primitive_shape = true,
    primitive_airfoil = true
}

if SERVER then
    Fin3.fins =  Fin3.fins or {}
end

function Fin3.sign(x)
    return x > 0 and 1 or x < 0 and -1 or 0
end

function Fin3.calcCurve(points, pos)
    local count = #points

    if count < 3 then return 0 end

    if pos <= points[1].x then
        return points[1].y
    elseif pos >= points[count].x then
        return points[count].y
    end

    -- Binary search to find the interval - 3x faster than previous method but still not great
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

-- Vector functions
do
    function Fin3.roundVectorToAxis(v)
        local absX, absY, absZ = math.abs(v.x), math.abs(v.y), math.abs(v.z)

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

    -- Returns the local axes that should be used for the fin's up and forward directions based on the player's aim location
    function Fin3.getPropAxesFromTrace(trace)
        local ent = trace.Entity
        local obbCenterWorld = ent:LocalToWorld(ent:OBBCenter())
        local hitNormal = trace.HitNormal
        local upAxis = Fin3.roundVectorToAxis(Fin3.worldToLocalVector(ent, hitNormal))
        local upAxisWorld = Fin3.localToWorldVector(ent, upAxis)

        local directionToHitPos = (trace.HitPos - obbCenterWorld):GetNormalized()
        local projection = directionToHitPos:Dot(upAxisWorld) * upAxisWorld
        local projectedVector = directionToHitPos - projection
        local forwardAxis = Fin3.roundVectorToAxis(Fin3.worldToLocalVector(ent, projectedVector))

        return upAxis, forwardAxis
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

    function Fin3.getRotInducedVel(phys, pos)
        if not IsValid(phys) then return Vector() end

        local p = pos - phys:GetMassCenter()
        local v = (phys:GetAngleVelocity() * 0.0174533):Cross(p)
        v = Fin3.localToWorldVector(phys:GetEntity(), v)
        return v
    end
end

if CLIENT then
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