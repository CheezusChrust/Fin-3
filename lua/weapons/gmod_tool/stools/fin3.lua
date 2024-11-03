TOOL.Category = "Construction"
TOOL.Name = "#tool.fin3.name"

if CLIENT then
    TOOL.Information = {
        { name = "left", stage = 0 },
        { name = "right", stage = 0 },
        { name = "reload", stage = 0 },
        { name = "centeroflift", stage = 0, icon = "gui/lmb.png", icon2 = "gui/info" },

        { name = "stage1.definefwd", icon = "gui/lmb.png", stage = 1 },
        { name = "stage1.definefwd2", icon = "gui/lmb.png", icon2 = "gui/info", stage = 1 },
        { name = "stage1.reload", icon = "gui/r.png", stage = 1 }
    }
end

function TOOL:SelectEntity(ent)
    self.selectedEntity = ent

    if SERVER then
        self:GetOwner():SetNW2Entity("fin3_selectedEntity", ent)
        self.lastColor = ent:GetColor()
        ent:SetColor(Color(0, 0, 255))
    end
end

function TOOL:ClearSelection()
    if IsValid(self.selectedEntity) and SERVER then
        self.selectedEntity:SetColor(self.lastColor)
    end

    self.selectedEntity = nil
    self.tempUpAxis = nil
    self.tempForwardAxis = nil

    local owner = self:GetOwner()

    if SERVER then
        owner:SetNW2Vector("fin3_tempUpAxis", nil)
        owner:SetNW2Vector("fin3_tempForwardAxis", nil)
        owner:SetNW2Entity("fin3_selectedEntity", nil)
    end
end

function TOOL:LeftClick(trace)
    local ent = trace.Entity
    local owner = self:GetOwner()

    if owner:KeyDown(IN_SPEED) and IsValid(ent) then
        if SERVER and CFW then
            local centerOfLift = Fin3.calcCenterOfLift(ent:GetContraption() or ent)

            if centerOfLift ~= vector_origin then
                net.Start("fin3_centeroflift")
                net.WriteFloat(centerOfLift.x)
                net.WriteFloat(centerOfLift.y)
                net.WriteFloat(centerOfLift.z)
                net.Send(owner)
            end
        end

        if CLIENT and not CFW and IsFirstTimePredicted() then
            chat.AddText(Color(255, 0, 0), "[Fin 3] Contraption Framework is required to calculate the center of lift.")
        end

        return true
    end

    local stage = self:GetStage()

    if stage == 0 and (not IsValid(ent) or not Fin3.allowedClasses[ent:GetClass()]) then
        return false
    end

    local finType = owner:GetInfo("fin3_fintype")

    if stage == 0 then
        if SERVER and Fin3.fins[ent] then
            Fin3.fin:new(owner, ent, {
                upAxis = Fin3.fins[ent].upAxis,
                forwardAxis = Fin3.fins[ent].forwardAxis,
                finType = finType,
                zeroLiftAngle = finType == "cambered" and owner:GetInfoNum("fin3_zeroliftangle", 1) or 0,
                efficiency = owner:GetInfoNum("fin3_efficiency", 1),
                inducedDrag = owner:GetInfoNum("fin3_induceddrag", 1),
                lowpass = owner:GetInfoNum("fin3_lowpass", 0) == 1
            })

            return true
        elseif ent:GetNW2String("fin3_finType", "") ~= "" then
            return true
        end

        self:SelectEntity(ent)
        self:SetStage(1)

        if SERVER then
            self.tempUpAxis = Fin3.roundVectorToAxis(Fin3.worldToLocalVector(ent, trace.HitNormal))
            owner:SetNW2Vector("fin3_tempUpAxis", self.tempUpAxis)
        end

        return true
    else
        if CLIENT then return true end

        local upAxis = self.tempUpAxis
        local forwardAxis = self.tempForwardAxis

        if forwardAxis == vector_origin or forwardAxis == upAxis then
            self:ClearSelection()
            self:SetStage(0)

            return true
        end

        Fin3.fin:new(owner, self.selectedEntity, {
            upAxis = upAxis,
            forwardAxis = forwardAxis,
            finType = finType,
            zeroLiftAngle = finType == "cambered" and owner:GetInfoNum("fin3_zeroliftangle", 1) or 0,
            efficiency = owner:GetInfoNum("fin3_efficiency", 1),
            inducedDrag = owner:GetInfoNum("fin3_induceddrag", 1),
            lowpass = owner:GetInfoNum("fin3_lowpass", 0) == 1
        })

        self:ClearSelection()
        self:SetStage(0)

        return true
    end
end

function TOOL:Think()
    if self:GetStage() == 0 then return end
    if CLIENT then return end

    local selected = self.selectedEntity

    if not IsValid(selected) then
        self:ClearSelection()
        self:SetStage(0)

        return
    end

    local owner = self:GetOwner()

    local holdingShift = owner:KeyDown(IN_SPEED)

    local tr = owner:GetEyeTrace()
    if not holdingShift then
        local obbCenterWorld = selected:LocalToWorld(selected:OBBCenter())
        local dirFromCenter = Fin3.worldToLocalVector(selected, (tr.HitPos - obbCenterWorld):GetNormalized())
        local upAxis = self.tempUpAxis
        local projectedVector = Fin3.projectVector(dirFromCenter, upAxis)
        self.tempForwardAxis = Fin3.roundVectorToAxis(projectedVector)
        owner:SetNW2Vector("fin3_tempForwardAxis", self.tempForwardAxis)
    else
        self.tempForwardAxis = Fin3.projectVector(Fin3.worldToLocalVector(selected, tr.HitNormal), self.tempUpAxis):GetNormalized()
        owner:SetNW2Vector("fin3_tempForwardAxis", self.tempForwardAxis)
    end
end

function TOOL:RightClick(trace)
    if self:GetStage() == 1 then return false end

    local ent = trace.Entity
    local class = ent:GetClass()

    if CLIENT then
        return Fin3.allowedClasses[class]
    end

    local fin = Fin3.fins[ent]

    if fin then
        local owner = self:GetOwner()
        owner:ConCommand("fin3_fintype " .. fin.finType)

        if fin.zeroLiftAngle and fin.zeroLiftAngle ~= 0 then
            owner:ConCommand("fin3_zeroliftangle " .. fin.zeroLiftAngle)
        end

        owner:ConCommand("fin3_efficiency " .. fin.efficiency)
        owner:ConCommand("fin3_induceddrag " .. fin.inducedDrag)
        owner:ConCommand("fin3_lowpass " .. (fin.lowpass and 1 or 0))
    end

    return Fin3.allowedClasses[class]
end

function TOOL:Reload(trace)
    if self:GetStage() == 1 then
        self:ClearSelection()
        self:SetStage(0)

        return true
    end

    local ent = trace.Entity

    if SERVER and Fin3.fins[ent] then
        Fin3.fins[ent]:remove()
    end

    return (SERVER and Fin3.fins[ent]) or ent:GetNW2String("fin3_finType", "") ~= ""
end

function TOOL:Holster()
    self:ClearSelection()
    self:SetStage(0)
end


if SERVER then return end

function TOOL.BuildCPanel(cp)
    local panel = vgui.Create("fin3_panel", cp)
    panel:Dock(TOP)
    panel:DockMargin(10, 0, 10, 0)

    panel:AddInfoBox("#tool.fin3.info")

    -- Fin type selection and per-type settings
    do
        local currentFinType = GetConVar("fin3_fintype"):GetString()
        local finTypeSelection = panel:AddComboBox("#tool.fin3.fintype", "#tool.fin3.fintype." .. currentFinType)

        for name in pairs(Fin3.models) do
            finTypeSelection:AddChoice("#tool.fin3.fintype." .. name, name)
        end

        local finTypeHelpText = panel:AddHelpText("#tool.fin3.fintype." .. currentFinType .. ".info")
        finTypeHelpText:DockMargin(10, 10, 10, 0)
        local camberedSettingsContainer = panel:AddHideableContainer()
        camberedSettingsContainer:AddLabel("#tool.fin3.fintype.specificsettings"):DockMargin(5, 5, 5, 0)
        camberedSettingsContainer:AddSlider("#tool.fin3.fintype.specificsettings.zeroliftangle", 1, 8, 1, "fin3_zeroliftangle"):DockMargin(5, 0, 0, 0)
        camberedSettingsContainer:SetVisible(currentFinType == "cambered")

        function finTypeSelection:OnSelect(_, _, data)
            finTypeHelpText:SetText("#tool.fin3.fintype." .. data .. ".info")
            camberedSettingsContainer:SetVisible(data == "cambered")
            RunConsoleCommand("fin3_fintype", data)
        end

        cvars.RemoveChangeCallback("fin3_fintype", "fin3_fintype_callback")
        cvars.AddChangeCallback("fin3_fintype", function(_, oldFinType, newFinType)
            if not Fin3.models[newFinType] then
                MsgC(Color(255, 0, 0), "Invalid fin type: ", newFinType, "\n")
                RunConsoleCommand("fin3_fintype", oldFinType)
            else
                finTypeSelection:SetValue("#tool.fin3.fintype." .. newFinType)
                finTypeHelpText:SetText("#tool.fin3.fintype." .. newFinType .. ".info")

                camberedSettingsContainer:SetVisible(newFinType == "cambered")
            end
        end, "fin3_fintype_callback")
    end

    panel:AddSlider("#tool.fin3.efficiency", 0.1, 1.5, 2, "fin3_efficiency"):DockMargin(0, 0, 0, 0)
    panel:AddHelpText("#tool.fin3.efficiency.info")

    panel:AddSlider("#tool.fin3.induceddrag", 0, 1, 2, "fin3_induceddrag"):DockMargin(0, 0, 0, 0)
    panel:AddHelpText("#tool.fin3.induceddrag.info")

    -- Debug settings
    do
        local showVectors = panel:AddCheckbox("#tool.fin3.debug.showvectors", "fin3_debug_showvectors")
        local showForces = panel:AddCheckbox("#tool.fin3.debug.showforces", "fin3_debug_showforces")

        function showVectors:OnChange(val)
            if val then
                Fin3.requestAllFins()
            end
        end

        function showForces:OnChange(val)
            if val then
                Fin3.requestAllFins()
            end
        end
    end

    -- Advanced settings
    do
        local advancedCheckbox = panel:AddCheckbox("#tool.fin3.advanced")
        advancedCheckbox:SetValue(false)
        local advancedSettingsContainer = panel:AddHideableContainer()
        advancedSettingsContainer:AddCheckbox("#tool.fin3.advanced.lowpass", "fin3_lowpass"):DockMargin(5, 5, 5, 0)
        advancedSettingsContainer:AddHelpText("#tool.fin3.advanced.lowpass.info"):DockMargin(10, 5, 10, 5)
        advancedSettingsContainer:SetVisible(false)

        function advancedCheckbox:OnChange()
            advancedSettingsContainer:SetVisible(self:GetChecked())
        end
    end
end