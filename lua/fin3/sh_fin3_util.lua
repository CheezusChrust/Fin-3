Fin3.allowedClasses = {
    prop_physics = true,
    primitive_shape = true,
    primitive_airfoil = true
}

if SERVER then
    Fin3.fins = {}
end

function Fin3.sign(x)
    return x > 0 and 1 or x < 0 and -1 or 0
end

function Fin3.calcCurve(keys, points, pos)
    local count = #keys

    if count < 3 then return 0 end

    if pos <= keys[1] then
        return points[keys[1]]
    elseif pos >= keys[count] then
        return points[keys[count]]
    end

    local current = 1
    for i = 1, count - 1 do
        if pos >= keys[i] and pos < keys[i + 1] then
            current = i
            break
        end
    end

    local t  = (pos - keys[current]) / (keys[current + 1] - keys[current])
    local p0 = points[keys[current - 1]] or points[keys[current]]
    local p1 = points[keys[current]]
    local p2 = points[keys[current + 1]]
    local p3 = points[keys[current + 2]] or points[keys[current + 1]]

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