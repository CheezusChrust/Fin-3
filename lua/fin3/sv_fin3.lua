function Fin3.new(_, ent, data)
    local fin = {}

    fin.ent = ent
    fin.upAxis = data.upAxis
    fin.forwardAxis = data.forwardAxis
    fin.root = Fin3.getRootParent(ent)
    fin.forceMultiplier = data.forceMultiplier
    fin.finType = data.finType

    fin.phys = fin.root:GetPhysicsObject()

    if not IsValid(ent) or not IsValid(phys) or not Fin3.allowedClasses[ent:GetClass()] then return end

    phys:EnableDrag(false)
    phys:SetDamping(0, 0)

    ent:SetNW2String("fin3_finType", data.finType)
    ent:SetNW2Vector("fin3_upAxis", data.upAxis)
    ent:SetNW2Vector("fin3_forwardAxis", data.forwardAxis)
    ent:SetNW2Float("fin3_forceMultiplier", data.forceMultiplier)

    function fin:getVelocity()
        if self.ent ~= self.root then
            return phys:GetVelocityAtPoint(ent:GetPos())
        else
            return phys:GetVelocity()
        end
    end

    function fin:calcBaseData()
        self.root = Fin3.getRootParent(self.ent) -- TODO: optimize this please
    end

    function fin:getLiftForceNewtons()
    end

    function fin:getDragForceNewtons()
    end

    function fin:applyForce(force)
        if self.ent ~= self.root then
            Fin3.applyForceOffsetFixed(self.root, force, self.ent:GetPos())
        else
            Fin3.applyForceOffsetFixed(self.root, force, self.root:GetPos())
        end
    end

    function fin:think()
        local vel = self:getVelocity()
    end

    function fin:remove()
        if IsValid(self.ent) then
            self.ent:SetNW2String("fin3_finType", nil)
            self.ent:SetNW2Vector("fin3_upAxis", nil)
            self.ent:SetNW2Vector("fin3_forwardAxis", nil)
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