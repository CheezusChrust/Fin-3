local deg, rad, asin, cos, abs, sign, pi = math.deg, math.rad, math.asin, math.cos, math.abs, Fin3.sign, math.pi
local localToWorldVector = Fin3.localToWorldVector
local roundVectorToAxis = Fin3.roundVectorToAxis
local applyForceOffsetFixed = Fin3.applyForceOffsetFixed
local getRootParent = Fin3.getRootParent
local getRotInducedVel = Fin3.getRotInducedVel
local calcLinearInterp = Fin3.calcLinearInterp
local dt = engine.TickInterval()

--[[
Fin creation data table structure:
    finType: string [model name]
    upAxis: vector
    forwardAxis: vector
    inducedDrag: boolean
    zeroLiftAngle: number [1 - 8]
    efficiency: number [0.1 - 1.5]
--]]

--- Adds a new fin to an entity
---@param ply Player Player that created the fin
---@param ent Entity Entity to add the fin to
---@param data table Fin creation data table
function Fin3.new(ply, ent, data)
    if not Fin3.fins[ent] then
        local finLimit = GetConVar("sbox_max_fin3"):GetInt()
        local currentFinCount = Fin3.playerFinCount[ply] or 0

        if currentFinCount >= finLimit then
            ply:LimitHit("Fin3")

            return
        end

        Fin3.playerFinCount[ply] = currentFinCount + 1
    end

    local fin = {}

    fin.ent = ent
    fin.massCenter = ent:GetPhysicsObject():GetMassCenter()
    fin.upAxis = data.upAxis
    fin.forwardAxis = data.forwardAxis
    fin.rightAxis = data.forwardAxis:Cross(data.upAxis)
    fin.root = getRootParent(ent)
    fin.finType = data.finType
    if fin.finType == "cambered" then
        fin.zeroLiftAngle = data.zeroLiftAngle or 5
    else
        fin.zeroLiftAngle = 0
    end
    fin.efficiency = data.efficiency or data.forceMultiplier -- Account for old versions

    if data.inducedDrag == nil then
        fin.inducedDrag = true
    else
        fin.inducedDrag = GetConVar("fin3_forceinduceddrag"):GetBool() and true or data.inducedDrag
    end

    local obbSize = ent:OBBMaxs() - ent:OBBMins()

    local span = abs(obbSize:Dot(roundVectorToAxis(fin.rightAxis)))
    local chord = abs(obbSize:Dot(roundVectorToAxis(fin.forwardAxis)))

    fin.surfaceArea = span * chord * 0.00064516 -- in^2 to m^2
    fin.aspectRatio = span / chord
    fin.invAspectRatio = 1 / fin.aspectRatio

    fin.velVector = vector_origin
    fin.velNorm = vector_origin
    fin.velMsSqr = 0
    fin.fwdVelRatio = 0

    fin.liftVector = vector_origin
    fin.liftForceNewtons = 0
    fin.liftInducedDragCoef = 0
    fin.dragForceNewtons = 0

    fin.lastPos = ent:GetPos()

    fin.angleOfAttack = 0

    local phys = fin.root:GetPhysicsObject()

    if not IsValid(ent) or not IsValid(phys) or not Fin3.allowedClasses[ent:GetClass()] then return end

    phys:EnableDrag(false)
    local _, rotDamping = phys:GetDamping()
    phys:SetDamping(0, rotDamping)

    ent:SetNW2String("fin3_finType", fin.finType)
    ent:SetNW2Vector("fin3_upAxis", fin.upAxis)
    ent:SetNW2Vector("fin3_forwardAxis", fin.forwardAxis)
    ent:SetNW2Vector("fin3_rightAxis", fin.rightAxis)
    ent:SetNW2Float("fin3_zeroLiftAngle", fin.zeroLiftAngle)
    ent:SetNW2Float("fin3_efficiency", fin.efficiency)
    ent:SetNW2Float("fin3_surfaceArea", fin.surfaceArea)
    ent:SetNW2Float("fin3_aspectRatio", fin.aspectRatio)
    ent:SetNW2Bool("fin3_inducedDrag", fin.inducedDrag)

    fin.phys = phys

    function fin:getVelocity()
        local curPos = self.ent:GetPos()
        local vel = (curPos - self.lastPos) / dt

        self.lastPos = curPos

        return vel + getRotInducedVel(self.phys, self.ent:WorldToLocal(curPos))
    end

    --- Calculates velocity, angle of attack, and lift vector
    function fin:calcBaseData()
        local newRoot = getRootParent(self.ent) -- TODO: optimize this

        if newRoot ~= self.root then
            self.root = newRoot
            self.phys = self.root:GetPhysicsObject()
        end

        self.velVector = self:getVelocity()

        if self.velVector == vector_origin then return end

        self.forwardVel = self.velVector:Dot(localToWorldVector(self.ent, self.forwardAxis))
        self.rightVel = self.velVector:Dot(localToWorldVector(self.ent, self.rightAxis))

        local forwardAndRightVel = abs(self.forwardVel) + abs(self.rightVel)
        self.fwdVelRatio = self.forwardVel / forwardAndRightVel

        self.velNorm = self.velVector:GetNormalized()
        self.velMsSqr = (self.velVector:Length() / 39.3701) ^ 2

        local worldUpAxis = localToWorldVector(self.ent, self.upAxis):GetNormalized()
        local upVelNorm = self.velNorm:Dot(worldUpAxis)

        if abs(upVelNorm) > 0.999 then
            self.angleOfAttack = 90 * sign(upVelNorm)
        else
            self.angleOfAttack = -deg(asin(self.velNorm:Dot(worldUpAxis)))
        end

        local side = self.velNorm:Cross(worldUpAxis)
        self.liftVector = -self.velNorm:Cross(side)
    end

    function fin:calcLiftForceNewtons()
        local flatModel = Fin3.models.flat
        local curModel = Fin3.models[self.finType]
        local liftCoef = 0
        local liftCoefFlat = calcLinearInterp(flatModel.interpolatedCurves.lift, self.angleOfAttack + 91)
        local fwdVelRatio = 0

        if self.forwardVel > 0 and self.finType ~= "flat" then
            fwdVelRatio = self.fwdVelRatio

            local AoA = self.angleOfAttack
            local AoAFinal = AoA

            if curModel.isCambered then
                local AoAShiftFactor = cos(rad(AoAFinal))
                AoAFinal = Lerp(fwdVelRatio, AoAFinal, AoAFinal + AoAShiftFactor * self.zeroLiftAngle)
            end

            local liftCoefForward = calcLinearInterp(curModel.interpolatedCurves.lift, AoAFinal + 91)

            liftCoef = Lerp(fwdVelRatio, liftCoefFlat, liftCoefForward)
        else
            liftCoef = liftCoefFlat
        end

        -- Cdi = (Cl^2) / (pi * AR * e)
        if self.inducedDrag then
            local aspectRatio = Lerp(fwdVelRatio, self.invAspectRatio, self.aspectRatio)
            fin.liftInducedDragCoef = (liftCoef ^ 2) / (pi * aspectRatio * Fin3.finEfficiency)
        end

        fin.liftForceNewtons = 0.5 * liftCoef * Fin3.airDensity * self.surfaceArea * self.velMsSqr * self.efficiency
    end

    function fin:calcDragForceNewtons()
        local flatModel = Fin3.models.flat
        local curModel = Fin3.models[self.finType]
        local dragCoef = 0
        local dragCoefFlat = calcLinearInterp(flatModel.interpolatedCurves.drag, self.angleOfAttack + 91)

        if self.forwardVel > 0 and self.finType ~= "flat" then
            local fwdVelRatio = self.fwdVelRatio

            local AoA = self.angleOfAttack
            local AoAFinal = AoA

            if curModel.isCambered then
                local AoAShiftFactor = cos(rad(AoAFinal))
                AoAFinal = Lerp(fwdVelRatio, AoAFinal, AoAFinal + AoAShiftFactor * self.zeroLiftAngle)
            end

            local dragCoefForward = calcLinearInterp(curModel.interpolatedCurves.drag, AoAFinal + 91)

            dragCoef = abs((dragCoefForward * fwdVelRatio) + (dragCoefFlat * (1 - fwdVelRatio)))
        else
            dragCoef = dragCoefFlat
        end

        dragCoef = dragCoef + self.liftInducedDragCoef

        fin.dragForceNewtons = 0.5 * dragCoef * Fin3.airDensity * self.surfaceArea * self.velMsSqr * self.efficiency
    end

    function fin:applyForce(force)
        applyForceOffsetFixed(self.phys, force, self.ent:LocalToWorld(self.massCenter))
    end

    function fin:think()
        self:calcBaseData()

        if self.velVector == vector_origin then
            self.ent:SetNW2Vector("fin3_liftVector", vector_origin)
            self.ent:SetNW2Vector("fin3_dragVector", vector_origin)

            return
        end

        self:calcLiftForceNewtons()
        self:calcDragForceNewtons()

        local finalLiftVector = self.liftVector * self.liftForceNewtons
        self.ent:SetNW2Vector("fin3_liftVector", finalLiftVector)

        local finalDragVector = -self.velNorm * self.dragForceNewtons
        self.ent:SetNW2Vector("fin3_dragVector", finalDragVector)

        local totalForce = finalLiftVector + finalDragVector

        self:applyForce(totalForce * 39.3701 * dt)
    end

    function fin:remove()
        if IsValid(self.ent) then
            self.ent:SetNW2String("fin3_finType", nil)
            self.ent:SetNW2Vector("fin3_upAxis", nil)
            self.ent:SetNW2Vector("fin3_forwardAxis", nil)
            self.ent:SetNW2Vector("fin3_rightAxis", nil)
            self.ent:SetNW2Float("fin3_efficiency", nil)
            self.ent:SetNW2Float("fin3_surfaceArea", nil)

            if IsValid(self.phys) then
                self.phys:EnableDrag(true)
            end
        end

        Fin3.fins[self.ent] = nil

        if IsValid(ply) and Fin3.playerFinCount[ply] then
            Fin3.playerFinCount[ply] = Fin3.playerFinCount[ply] - 1
        end

        duplicator.ClearEntityModifier(self.ent, "fin3")
    end

    Fin3.fins[ent] = fin

    duplicator.StoreEntityModifier(ent, "fin3", data)
end

duplicator.RegisterEntityModifier("fin3", Fin3.new)

hook.Add("Think", "fin3_think", function()
    for _, fin in pairs(Fin3.fins) do
        if not IsValid(fin.ent) or not IsValid(fin.root) then
            fin:remove()
        else
            fin:think()
        end
    end
end)

util.AddNetworkString("fin3_sendfins")
timer.Create("fin3_sendfins", 1, 0, function()
    local fins = {}

    for _, fin in pairs(Fin3.fins) do
        if IsValid(fin.ent) then
            fins[#fins + 1] = fin.ent
        end
    end

    net.Start("fin3_sendfins")
    net.WriteUInt(#fins, 12)

    for _, ent in ipairs(fins) do
        net.WriteEntity(ent)
    end

    net.Broadcast()
end)