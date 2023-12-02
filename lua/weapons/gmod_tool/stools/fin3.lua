TOOL.Category = "Construction"
TOOL.Name = "#tool.fin3.name"

if CLIENT then
    CreateClientConVar("fin3_fintype", "symmetrical", false, true, "The type of airfoil to use for the fin")
    CreateClientConVar("fin3_forcemul", "1", false, true, "The multiplier for the lift and drag forces", 0.1, 1.5)
    CreateClientConVar("fin3_debug", "0", false, true, "Whether or not to draw debug information on all fins owned by you", 0, 1)

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
        "Important Info:\n" ..
        "\"Angle of Attack\", or AoA, refers to the angle of the fin compared to the angle of the airflow.\n\n" ..
        "If the AoA is too high, the fin will begin to stall, and subsequently lose lift and gain drag."
    )

    language.Add("tool.fin3.fintype", "Airfoil Type")

    language.Add("tool.fin3.forcemul", "Force Multiplier")
    language.Add("tool.fin3.forcemul.info", "Calculated lift and drag forces are multiplied by this value. Base lift and drag are determined by the surface area of the fin. 1 is default.")

    language.Add("tool.fin3.debug", "Debug")
    language.Add("tool.fin3.debug.info", "Draws debug information on all fins owned by you.")
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

    Fin3.new(_, ent, {
        upAxis = upAxis,
        forwardAxis = forwardAxis,
        finType = ply:GetInfo("fin3_fintype"),
        forceMultiplier = ply:GetInfoNum("fin3_forcemul", 1)
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
        ply:ConCommand("fin3_forcemul " .. fin.forceMultiplier)
    end

    return Fin3.allowedClasses[class]
end

function TOOL:Reload(trace)
    local ent = trace.Entity
    local class = ent:GetClass()

    if SERVER then
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

    local optionsContainer = vgui.Create("DPanel", cp)
    optionsContainer:Dock(TOP)
    optionsContainer:DockMargin(10, 10, 10, 0)
    optionsContainer:SetTall(16)
    optionsContainer.Paint = function() end

    local optionsLabel = createLabel(optionsContainer, "#tool.fin3.fintype")
    optionsLabel:Dock(LEFT)
    optionsLabel:DockMargin(0, 0, 0, 0)

    local finTypeSelection = vgui.Create("DComboBox", optionsContainer)
    finTypeSelection:SetValue("#tool.fin3.fintype." .. GetConVar("fin3_fintype"):GetString())

    for name in pairs(Fin3.models) do
        finTypeSelection:AddChoice(string.format("#tool.fin3.fintype.%s", name), name)
    end

    finTypeSelection:Dock(RIGHT)
    finTypeSelection:SetWide(160)

    local finTypeHelperText = createLabel(cp, "#tool.fin3.fintype." .. GetConVar("fin3_fintype"):GetString() .. ".info", "DermaDefault")
    finTypeHelperText:DockMargin(20, 10, 20, 0)

    function finTypeSelection:OnSelect(_, _, finType)
        RunConsoleCommand("fin3_fintype", finType)
        finTypeHelperText:SetText("#tool.fin3.fintype." .. finType .. ".info")
    end

    cvars.RemoveChangeCallback("fin3_fintype")
    cvars.AddChangeCallback("fin3_fintype", function(_, oldFinType, newFinType)
        if not Fin3.models[newFinType] then
            MsgC(Color(255, 0, 0), "Invalid fin type: ", newFinType, "\n")
            RunConsoleCommand("fin3_fintype", oldFinType)
        else
            finTypeSelection:SetValue("#tool.fin3.fintype." .. newFinType)
            finTypeHelperText:SetText("#tool.fin3.fintype." .. newFinType .. ".info")
        end
    end)

    local forceSlider = vgui.Create("DNumSlider", cp)
    forceSlider:Dock(TOP)
    forceSlider.Label:SetColor(Color(0, 0, 0))
    forceSlider.Label:SetFont("fin3_labeltext")
    forceSlider:DockMargin(10, 10, 10, 0)
    forceSlider:SetText("#tool.fin3.forcemul")
    forceSlider:SetMin(0.1)
    forceSlider:SetMax(1.5)
    forceSlider:SetDecimals(2)
    forceSlider:SetValue(GetConVar("fin3_forcemul"):GetFloat())
    forceSlider:SetConVar("fin3_forcemul")

    local forceInfo = createLabel(cp, "#tool.fin3.forcemul.info", "DermaDefault")
    forceInfo:DockMargin(20, 0, 20, 10)

    local debugCheckbox = vgui.Create("DCheckBoxLabel", cp)
    debugCheckbox:Dock(TOP)
    debugCheckbox:DockMargin(10, 10, 10, 0)
    debugCheckbox:SetText("#tool.fin3.debug")
    debugCheckbox.Label:SetFont("fin3_labeltext")
    debugCheckbox.Label:SetColor(Color(0, 0, 0))
    debugCheckbox:SetValue(GetConVar("fin3_debug"):GetBool())
    debugCheckbox:SetConVar("fin3_debug")

    local debugCheckboxInfo = createLabel(cp, "#tool.fin3.debug.info", "DermaDefault")
    debugCheckboxInfo:DockMargin(20, 10, 20, 0)
end