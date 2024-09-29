local rad2deg = 180 / math.pi
local pi = math.pi
local tan = math.tan
local round = math.Round

TOOL.Category = "Construction"
TOOL.Name = "#tool.fin3_propeller.name"

if CLIENT then
    TOOL.Information = {
        { name = "left", stage = 0 },
        { name = "right", stage = 0 },
        { name = "reload", stage = 0 },
    }
end

function TOOL:LeftClick(trace)
    local ent = trace.Entity

    if not IsValid(ent) or not Fin3.allowedClasses[ent:GetClass()] then
        return false
    end

    if SERVER then
        local forwardAxis

        if Fin3.propellers[ent] then
            forwardAxis = Fin3.propellers[ent].forwardAxis
        else
            forwardAxis = Fin3.roundVectorToAxis(Fin3.worldToLocalVector(ent, trace.HitNormal))
        end

        local owner = self:GetOwner()

        Fin3.propeller:new(owner, ent, {
            forwardAxis = forwardAxis,
            bladeCount = owner:GetInfoNum("fin3_propeller_bladecount", 2),
            diameter = owner:GetInfoNum("fin3_propeller_diameter", 2),
            bladeAngle = owner:GetInfoNum("fin3_propeller_bladeangle", 15),
            invertRotation = owner:GetInfoNum("fin3_propeller_invert", 0) == 1
        })
    end

    return true
end

function TOOL:RightClick(trace)
    local ent = trace.Entity
    local class = ent:GetClass()

    if CLIENT then
        return Fin3.allowedClasses[class]
    end

    local propeller = Fin3.propellers[ent]

    if propeller then
        local owner = self:GetOwner()
        owner:ConCommand("fin3_propeller_bladecount " .. propeller.bladeCount)
        owner:ConCommand("fin3_propeller_diameter " .. propeller.diameter)
        owner:ConCommand("fin3_propeller_bladeangle " .. propeller.bladeAngle)
        owner:ConCommand("fin3_propeller_invert " .. (propeller.invertRotation and 1 or 0))
    end

    return Fin3.allowedClasses[class]
end

function TOOL:Reload(trace)
    local ent = trace.Entity

    if SERVER and Fin3.propellers[ent] then
        Fin3.propellers[ent]:remove()

        return true
    end

    return ent:GetNW2Int("fin3_propeller_bladecount", 0) ~= 0
end

if SERVER then return end

local propInfoString = "Pitch: %.1f inches\n" ..
    "Max Speed @ 500RPM: %dkm/h\n" ..
    "Max Speed @ 1500RPM: %dkm/h\n" ..
    "Max Speed @ 2500RPM: %dkm/h"

local function updatePropellerInfo(panel, pitch, speed500, speed1500, speed2500)
    panel:SetText(string.format(propInfoString, pitch, speed500, speed1500, speed2500))
end

function TOOL.BuildCPanel(cp)
    local panel = vgui.Create("fin3_panel", cp)
    panel:Dock(TOP)
    panel:DockMargin(10, 0, 10, 0)

    panel:AddSlider("Blade Count", 2, 6, 0, "fin3_propeller_bladecount"):DockMargin(0, 0, 0, 0)
    panel:AddHelpText("The number of blades on the propeller.")

    local diameterSlider = panel:AddSlider("Diameter", 0.1, 6, 2, "fin3_propeller_diameter")
    diameterSlider:DockMargin(0, 0, 0, 0)
    panel:AddHelpText("The diameter of the propeller, in meters.")

    local angleSlider = panel:AddSlider("Blade Angle", 0, 60, 0, "fin3_propeller_bladeangle")
    angleSlider:DockMargin(0, 0, 0, 0)
    panel:AddHelpText(
        "The angle of the blades on the propeller, in degrees.\n" ..
        "90 degrees is feathered (aligned forwards airflow, minimal forwards drag).\n" ..
        "Propellers at 0 or 90 degrees cannot produce thrust.\n" ..
        "Low angles will have a lot of low speed thrust, but a low top speed.\n" ..
        "High angles will have a high top speed, but low overall thrust."
    ):DockMargin(10, 0, 10, 0)

    local propellerInfo = panel:AddInfoBox(string.format(propInfoString, 0, 0, 0, 0))
    propellerInfo:DockMargin(0, 10, 0, 10)

    function diameterSlider:OnValueChanged(value)
        local pitch = pi * 0.75 * value * tan(angleSlider:GetValue() / rad2deg)
        local speed500 = round(pitch * 500 * 0.06)
        local speed1500 = round(pitch * 1500 * 0.06)
        local speed2500 = round(pitch * 2500 * 0.06)
        updatePropellerInfo(propellerInfo, pitch * 39.3701, speed500, speed1500, speed2500)
    end

    function angleSlider:OnValueChanged(value)
        local pitch = pi * 0.75 * diameterSlider:GetValue() * tan(value / rad2deg)
        local speed500 = round(pitch * 500 * 0.06)
        local speed1500 = round(pitch * 1500 * 0.06)
        local speed2500 = round(pitch * 2500 * 0.06)
        updatePropellerInfo(propellerInfo, pitch * 39.3701, speed500, speed1500, speed2500)
    end

    panel:AddCheckbox("Invert Spin Direction", "fin3_propeller_invert"):DockMargin(0, 0, 0, 7)
    panel:AddHelpText("Spin the propeller clockwise (when viewed from behind) if this is disabled, counter-clockwise if enabled."):DockMargin(10, 0, 10, 5)

    -- Debug settings
    do
        panel:AddCheckbox("Display propeller debug info", "fin3_propeller_debug_showforces")

        cvars.RemoveChangeCallback("fin3_propeller_debug_showforces", "fin3_debug_callback")
        cvars.AddChangeCallback("fin3_propeller_debug_showforces", function(_, _, debug)
            local enable = debug == "1"

            if enable then
                Fin3.requestAllPropellers()
            end
        end, "fin3_debug_callback")
    end
end