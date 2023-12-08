local deg, asin, abs, sign, pi = math.deg, math.asin, math.abs, Fin3.sign, math.pi
local localToWorldVector = Fin3.localToWorldVector
local applyForceOffsetFixed = Fin3.applyForceOffsetFixed
local getRootParent = Fin3.getRootParent
local dt = engine.TickInterval()
Fin3.airDensity = 1.225 -- kg/m^3
local finEfficiency = 0.9   -- 0.9 is a magic arbitrarily chosen number, sue me
                            -- Used for calculating induced drag coefficient

function Fin3.new(_, ent, data)
    local fin = {}

    fin.ent = ent
    fin.massCenter = ent:GetPhysicsObject():GetMassCenter()
    fin.upAxis = data.upAxis
    fin.forwardAxis = data.forwardAxis
    fin.rightAxis = data.forwardAxis:Cross(data.upAxis)
    fin.root = getRootParent(ent)
    fin.forceMultiplier = data.forceMultiplier
    fin.finType = data.finType

    local obbSize = ent:OBBMaxs() - ent:OBBMins()
    fin.surfaceArea = abs((obbSize:Dot(fin.forwardAxis) * obbSize:Dot(fin.rightAxis)) * 0.00064516) -- in^2 to m^2
    fin.aspectRatio = (abs(obbSize:Dot(fin.rightAxis) * 0.0254) ^ 2) / fin.surfaceArea
    fin.sideAspectRatio = (abs(obbSize:Dot(fin.forwardAxis) * 0.0254) ^ 2) / fin.surfaceArea

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
    ent:SetNW2Float("fin3_forceMultiplier", fin.forceMultiplier)
    ent:SetNW2Float("fin3_surfaceArea", fin.surfaceArea)
    ent:SetNW2Float("fin3_aspectRatio", fin.aspectRatio)

    fin.phys = phys

    function fin:getVelocity()
        local curPos = self.ent:GetPos()
        local vel = (curPos - self.lastPos) / dt

        self.lastPos = curPos

        return vel + Fin3.getRotInducedVel(self.phys, self.ent:WorldToLocal(curPos))
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
        self.liftVector = self.velNorm:Cross(side)
    end

    function fin:calcLiftForceNewtons()
        local flatModel = Fin3.models.flat
        local curModel = Fin3.models[self.finType]
        local liftCoef = 0
        local liftCoefFlat = Fin3.calcCurve(flatModel.curves.lift, abs(self.angleOfAttack))  * -sign(self.angleOfAttack)
        local fwdVelRatio = 0

        if self.forwardVel > 0 then
            fwdVelRatio = self.fwdVelRatio
            local aoaForModel = curModel.isCambered and self.angleOfAttack or abs(self.angleOfAttack)

            local liftCoefForward = -Fin3.calcCurve(curModel.curves.lift, aoaForModel)

            if not curModel.isCambered then
                liftCoefForward = liftCoefForward  * sign(self.angleOfAttack)
            end

            liftCoef = Lerp(fwdVelRatio, liftCoefFlat, liftCoefForward)
        else
            liftCoef = liftCoefFlat
        end

        -- Cdi = (Cl^2) / (pi * AR * e)
        fin.liftInducedDragCoef = (liftCoef ^ 2) / (pi * Lerp(fwdVelRatio, self.sideAspectRatio, self.aspectRatio) * finEfficiency)
        fin.liftForceNewtons = 0.5 * liftCoef * Fin3.airDensity * self.surfaceArea * self.velMsSqr * self.forceMultiplier, dragInduced
    end

    function fin:calcDragForceNewtons()
        local flatModel = Fin3.models.flat
        local curModel = Fin3.models[self.finType]
        local dragCoef = 0
        local dragCoefFlat = Fin3.calcCurve(flatModel.curves.drag, abs(self.angleOfAttack))

        if self.forwardVel > 0 then
            local ratio = self.fwdVelRatio
            local aoaForModel = curModel.isCambered and self.angleOfAttack or abs(self.angleOfAttack)

            local dragCoefForward = Fin3.calcCurve(curModel.curves.drag, aoaForModel)

            dragCoef = abs((dragCoefForward * ratio) + (dragCoefFlat * (1 - ratio)))
        else
            dragCoef = dragCoefFlat
        end

        dragCoef = dragCoef + self.liftInducedDragCoef

        fin.dragForceNewtons = 0.5 * dragCoef * Fin3.airDensity * self.surfaceArea * self.velMsSqr * self.forceMultiplier
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
            self.ent:SetNW2Float("fin3_forceMultiplier", nil)
            self.ent:SetNW2Float("fin3_surfaceArea", nil)

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