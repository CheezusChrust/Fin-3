local deg, asin, abs, sign = math.deg, math.asin, math.abs, Fin3.sign
local localToWorldVector = Fin3.localToWorldVector
local applyForceOffsetFixed = Fin3.applyForceOffsetFixed
local getRootParent = Fin3.getRootParent
local dt = engine.TickInterval()
Fin3.airDensity = 1.225 -- kg/m^3

function Fin3.new(_, ent, data)
    local fin = {}

    fin.ent = ent
    fin.upAxis = data.upAxis
    fin.forwardAxis = data.forwardAxis
    fin.rightAxis = data.forwardAxis:Cross(data.upAxis)
    fin.root = getRootParent(ent)
    fin.forceMultiplier = data.forceMultiplier
    fin.finType = data.finType

    local obbSize = ent:OBBMaxs() - ent:OBBMins()
    fin.surfaceArea = abs((obbSize:Dot(fin.forwardAxis) * obbSize:Dot(fin.rightAxis)) * 0.00064516) -- in^2 to m^2

    fin.velVector = vector_origin
    fin.velNorm = vector_origin
    fin.velMsSqr = 0
    fin.fwdVelRatio = 0

    fin.liftVector = vector_origin

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
    ent:SetNW2Float("fin3_forceMultiplier", fin.forceMultiplier)

    fin.phys = phys

    function fin:getVelocity()
        if self.ent ~= self.root then
            return self.phys:GetVelocityAtPoint(self.ent:GetPos())
        else
            return self.phys:GetVelocity()
        end
    end

    -- Calculates velocity vector, squared velocity, angle of attack, and lift vector
    function fin:calcBaseData()
        local newRoot = getRootParent(self.ent) -- TODO: optimize this

        if newRoot ~= self.root then
            self.root = newRoot
            self.phys = self.root:GetPhysicsObject()
        end

        self.velVector = self:getVelocity()

        if self.velVector == vector_origin then return end

        self.forwardVel = abs(self.velVector:Dot(Fin3.localToWorldVector(self.ent, self.forwardAxis)))
        self.rightVel = abs(self.velVector:Dot(Fin3.localToWorldVector(self.ent, self.rightAxis)))

        local forwardAndRightVel = self.forwardVel + self.rightVel
        self.fwdVelRatio = self.forwardVel / forwardAndRightVel

        --print(self.fwdVelRatio)

        self.velNorm = self.velVector:GetNormalized()
        self.velMsSqr = (self.velVector:Length() / 39.3701) ^ 2

        local worldUpAxis = localToWorldVector(self.ent, self.upAxis):GetNormalized()
        local upVelNorm = self.velNorm:Dot(worldUpAxis)

        if abs(upVelNorm) > 0.99 then
            self.angleOfAttack = 90 * sign(upVelNorm)
        else
            self.angleOfAttack = -deg(asin(self.velNorm:Dot(worldUpAxis)))
        end

        local side = self.velNorm:Cross(worldUpAxis)
        self.liftVector = self.velNorm:Cross(side)
        --self.liftVector = self.liftVector * -sign(self.angleOfAttack)

        --print(self.angleOfAttack)
    end

    function fin:getLiftForceNewtons()
        local flatModel = Fin3.models.flat
        local curModel = Fin3.models[self.finType]
        local liftCoef = 0
        local liftCoefFlat = Fin3.calcCurve(flatModel.liftCurveKeys, flatModel.liftCurve, abs(self.angleOfAttack))  * -sign(self.angleOfAttack)

        if self.forwardVel > 0 then
            local ratio = self.fwdVelRatio
            local aoaForModel = curModel.isCambered and self.angleOfAttack or abs(self.angleOfAttack)

            local liftCoefForward = -Fin3.calcCurve(curModel.liftCurveKeys, curModel.liftCurve, aoaForModel)

            if not curModel.isCambered then
                liftCoefForward = liftCoefForward  * sign(self.angleOfAttack)
            end

            liftCoef = Lerp(ratio, liftCoefFlat, liftCoefForward)
        else
            liftCoef = liftCoefFlat
        end

        return 0.5 * liftCoef * Fin3.airDensity * self.surfaceArea * self.velMsSqr * self.forceMultiplier
    end

    function fin:getDragForceNewtons()
        local flatModel = Fin3.models.flat
        local curModel = Fin3.models[self.finType]
        local dragCoef = 0
        local dragCoefFlat = Fin3.calcCurve(flatModel.dragCurveKeys, flatModel.dragCurve, abs(self.angleOfAttack))

        if self.forwardVel > 0 then
            local ratio = self.fwdVelRatio
            local aoaForModel = curModel.isCambered and self.angleOfAttack or abs(self.angleOfAttack)

            local dragCoefForward = Fin3.calcCurve(curModel.dragCurveKeys, curModel.dragCurve, aoaForModel)

            dragCoef = abs((dragCoefForward * ratio) + (dragCoefFlat * (1 - ratio)))
        else
            dragCoef = dragCoefFlat
        end

        return 0.5 * dragCoef * Fin3.airDensity * self.surfaceArea * self.velMsSqr * self.forceMultiplier
    end

    function fin:applyForce(force)
        if self.ent ~= self.root then
            applyForceOffsetFixed(self.phys, force, self.ent:GetPos())
        else
            applyForceOffsetFixed(self.phys, force, self.root:GetPos())
        end
    end

    function fin:think()
        self:calcBaseData()

        if self.velVector == vector_origin then return end

        local finalLiftVector = self.liftVector * self:getLiftForceNewtons()
        self.ent:SetNW2Vector("fin3_liftVector", finalLiftVector)

        local finalDragVector = -self.velNorm * self:getDragForceNewtons()
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
            self.ent:SetNW2Float("fin3_forceMultiplier", nil)

            if IsValid(self.phys) then
                self.phys:EnableDrag(true)
            end
        end

        Fin3.fins[self.ent] = nil

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