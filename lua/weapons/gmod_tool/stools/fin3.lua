TOOL.Category = "Construction"
TOOL.Name = "#tool.fin3.name"

if CLIENT then
    TOOL.Information = {
        {
            name = "left"
        },
        {
            name = "right"
        },
        {
            name = "reload"
        }
    }

    language.Add("tool.fin3.name", "Fin 3")
    language.Add("tool.fin3.desc", "Turn any prop into a simulated fin")
    language.Add("tool.fin3.left", "Create or update a fin")
    language.Add("tool.fin3.right", "Copy fin settings")
    language.Add("tool.fin3.reload", "Remove fin from prop")

    language.Add("tool.fin3.info",
        "Important Info!\n" ..
        "\"Angle of Attack\", or AoA, refers to the angle of the fin compared to the angle of the airflow.\n\n" ..
        "If the AoA is too high, the fin will begin to stall, and subsequently lose lift and gain drag."
    )

    language.Add("tool.fin3.fintype", "Airfoil Type")

    language.Add("tool.fin3.fintype.specificsettings", "Airfoil settings:")
    language.Add("tool.fin3.fintype.specificsettings.zeroliftangle", "Zero Lift Angle")

    language.Add("tool.fin3.efficiency", "Efficiency")
    language.Add("tool.fin3.efficiency.info",
        "Calculated lift and drag forces are multiplied by this value. " ..
        "Base lift and drag are determined by the surface area of the fin. 1 is default, and is the most realistic."
    )

    language.Add("tool.fin3.induceddrag", "Induced Drag")
    language.Add("tool.fin3.induceddrag.info",
        "Induced drag is a byproduct of lift, and should generally be enabled for aircraft. " ..
        "Fins with a higher aspect ratio (span/chord) will have less induced drag. " ..
        "Server operators can forcibly enable this setting."
    )

    language.Add("tool.fin3.debug", "Debug")
    language.Add("tool.fin3.debug.info", "Draws debug information on all fins.")
    language.Add("tool.fin3.debug.options", "Debug options:")
    language.Add("tool.fin3.debug.showvectors", "Display lift/drag vectors")
    language.Add("tool.fin3.debug.showforces", "Display lift/drag force values")
end

function TOOL:LeftClick(trace)
    local ent = trace.Entity

    if CLIENT then
        return Fin3.allowedClasses[ent:GetClass()]
    end

    if not IsValid(ent) or not Fin3.allowedClasses[ent:GetClass()] then
        return false
    end

    local upAxis, forwardAxis = Fin3.getPropAxesFromTrace(trace)
    local ply = self:GetOwner()

    Fin3.new(ply, ent, {
        upAxis = upAxis,
        forwardAxis = forwardAxis,
        finType = ply:GetInfo("fin3_fintype"),
        zeroLiftAngle = ply:GetInfoNum("fin3_zeroliftangle", 1),
        efficiency = ply:GetInfoNum("fin3_efficiency", 1),
        inducedDrag = ply:GetInfoNum("fin3_induceddrag", 1) == 1
    })

    return true
end

function TOOL:RightClick(trace)
    local ent = trace.Entity
    local class = ent:GetClass()

    if CLIENT then
        return Fin3.allowedClasses[class]
    end

    local fin = Fin3.fins[ent]

    if fin then
        local ply = self:GetOwner()
        ply:ConCommand("fin3_fintype " .. fin.finType)
        ply:ConCommand("fin3_efficiency " .. fin.efficiency)
        ply:ConCommand("fin3_induceddrag " .. (fin.inducedDrag and 1 or 0))
    end

    return Fin3.allowedClasses[class]
end

function TOOL:Reload(trace)
    local ent = trace.Entity
    local class = ent:GetClass()

    if SERVER and Fin3.fins[ent] then
        Fin3.fins[ent]:remove()
    end

    return Fin3.allowedClasses[class]
end


if SERVER then return end


local function createLabel(parent, text, font)
    local label = vgui.Create("DLabel", parent)
    label:SetText(text)
    label:SetFont(font or "fin3_labeltext")
    label:SetColor(Color(0, 0, 0))
    label:Dock(TOP)
    label:SetWrap(true)
    label:DockMargin(10, 10, 10, 0)
    label:SetAutoStretchVertical(true)

    return label
end

local function createSlider(parent, text, min, max, decimals, convar)
    local slider = vgui.Create("DNumSlider", parent)
    slider:Dock(TOP)
    slider.Label:SetColor(Color(0, 0, 0))
    slider.Label:SetFont("fin3_labeltext")
    slider:DockMargin(10, 10, 10, 0)
    slider:SetText(text)
    slider:SetMin(min)
    slider:SetMax(max)
    slider:SetDecimals(decimals)
    slider:SetConVar(convar)

    return slider
end

local function createCheckbox(parent, text, convar)
    local checkbox = vgui.Create("DCheckBoxLabel", parent)
    checkbox:Dock(TOP)
    checkbox:DockMargin(10, 10, 10, 0)
    checkbox:SetText(text)
    checkbox.Label:SetFont("fin3_labeltext")
    checkbox.Label:SetColor(Color(0, 0, 0))
    checkbox:SetConVar(convar)

    return checkbox
end

function TOOL.BuildCPanel(cp)
    createLabel(cp, "#tool.fin3.desc", "fin3_bigtext")

    local infoPanel = vgui.Create("DPanel", cp)
    infoPanel:Dock(TOP)
    infoPanel:DockMargin(10, 10, 10, 0)

    local infoPanelText = createLabel(infoPanel, "#tool.fin3.info")
    infoPanelText:DockMargin(5, 5, 5, 0)

    local oldPerformLayout = infoPanel.PerformLayout
    function infoPanel:PerformLayout()
        oldPerformLayout(self)

        local _, textHeight = infoPanelText:GetTextSize()

        self:SetTall(textHeight + 10)
    end

    do -- Fin type selection and fin type specific settings
        local optionsDropdownContainer = vgui.Create("DPanel", cp)
        optionsDropdownContainer:Dock(TOP)
        optionsDropdownContainer:DockMargin(10, 10, 10, 0)
        optionsDropdownContainer:SetTall(16)
        optionsDropdownContainer.Paint = function() end

        local optionsLabel = createLabel(optionsDropdownContainer, "#tool.fin3.fintype")
        optionsLabel:Dock(LEFT)
        optionsLabel:DockMargin(0, 0, 0, 0)

        local finTypeSelection = vgui.Create("DComboBox", optionsDropdownContainer)
        finTypeSelection:SetValue("#tool.fin3.fintype." .. GetConVar("fin3_fintype"):GetString())

        for name in pairs(Fin3.models) do
            finTypeSelection:AddChoice(string.format("#tool.fin3.fintype.%s", name), name)
        end

        finTypeSelection:Dock(RIGHT)
        finTypeSelection:SetWide(160)

        local finTypeHelperText = createLabel(cp, "#tool.fin3.fintype." .. GetConVar("fin3_fintype"):GetString() .. ".info", "DermaDefault")
        finTypeHelperText:DockMargin(20, 10, 20, 0)

        local camberedWingSettingsContainer = vgui.Create("DPanel", cp)
        camberedWingSettingsContainer:Dock(TOP)
        camberedWingSettingsContainer:DockMargin(20, 10, 20, 0)
        camberedWingSettingsContainer:SetTall(48)

        createLabel(camberedWingSettingsContainer, "#tool.fin3.fintype.specificsettings", "fin3_labeltext"):DockMargin(5, 5, 5, 0)
        createSlider(camberedWingSettingsContainer, "#tool.fin3.fintype.specificsettings.zeroliftangle", 1, 8, 1, "fin3_zeroliftangle"):DockMargin(5, -5, 5, 0)

        local function showCamberedWingSettings(show)
            camberedWingSettingsContainer:SetVisible(show)
            cp:InvalidateLayout()
        end

        showCamberedWingSettings(GetConVar("fin3_fintype"):GetString() == "cambered")

        function finTypeSelection:OnSelect(_, _, finType)
            RunConsoleCommand("fin3_fintype", finType)
            finTypeHelperText:SetText("#tool.fin3.fintype." .. finType .. ".info")

            showCamberedWingSettings(finType == "cambered")
        end

        cvars.RemoveChangeCallback("fin3_fintype", "fin3_fintype_callback")
        cvars.AddChangeCallback("fin3_fintype", function(_, oldFinType, newFinType)
            if not Fin3.models[newFinType] then
                MsgC(Color(255, 0, 0), "Invalid fin type: ", newFinType, "\n")
                RunConsoleCommand("fin3_fintype", oldFinType)
            else
                finTypeSelection:SetValue("#tool.fin3.fintype." .. newFinType)
                finTypeHelperText:SetText("#tool.fin3.fintype." .. newFinType .. ".info")

                showCamberedWingSettings(newFinType == "cambered")
            end
        end, "fin3_fintype_callback")
    end

    createSlider(cp, "#tool.fin3.efficiency", 0.1, 1.5, 2, "fin3_efficiency")
    createLabel(cp, "#tool.fin3.efficiency.info", "DermaDefault"):DockMargin(20, 0, 20, 10)

    local inducedDragCheckbox = createCheckbox(cp, "#tool.fin3.induceddrag", "fin3_induceddrag")
    inducedDragCheckbox:SetDisabled(GetConVar("fin3_forceinduceddrag"):GetBool())

    net.Receive("fin3_forceinduceddrag", function()
        if IsValid(inducedDragCheckbox) then
            inducedDragCheckbox:SetDisabled(net.ReadBool())
        end
    end)

    createLabel(cp, "#tool.fin3.induceddrag.info", "DermaDefault"):DockMargin(20, 10, 20, 10)

    local debugCheckbox = createCheckbox(cp, "#tool.fin3.debug", "fin3_debug")
    createLabel(cp, "#tool.fin3.debug.info", "DermaDefault"):DockMargin(20, 10, 20, 0)

    do -- Options specific to debug mode
        local debugOptionsContainer = vgui.Create("DPanel", cp)
        debugOptionsContainer:Dock(TOP)
        debugOptionsContainer:DockMargin(20, 10, 20, 0)
        debugOptionsContainer:SetTall(80)

        local debugOptionsLabel = createLabel(debugOptionsContainer, "#tool.fin3.debug.options")
        debugOptionsLabel:Dock(TOP)
        debugOptionsLabel:DockMargin(5, 5, 5, 0)

        createCheckbox(debugOptionsContainer, "#tool.fin3.debug.showvectors", "fin3_debug_showvectors")
        createCheckbox(debugOptionsContainer, "#tool.fin3.debug.showforces", "fin3_debug_showforces")

        local function showDebugOptions(show)
            debugOptionsContainer:SetVisible(show)
            cp:InvalidateLayout()
        end

        function debugCheckbox:OnChange()
            showDebugOptions(self:GetChecked())
        end

        cvars.RemoveChangeCallback("fin3_debug", "fin3_debug_callback")
        cvars.AddChangeCallback("fin3_debug", function(_, _, debug)
            debugCheckbox:SetChecked(tobool(debug))
            showDebugOptions(tobool(debug))
        end, "fin3_debug_callback")
    end

    cp:InvalidateLayout()
end