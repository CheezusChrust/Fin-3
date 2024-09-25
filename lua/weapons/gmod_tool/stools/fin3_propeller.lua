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
end

function TOOL:Think()
end

function TOOL:RightClick(trace)
end

function TOOL:Reload(trace)
end

if SERVER then return end

local propInfoString = "Propeller Info:\n" ..
    "Pitch: %.1f inches\n" ..
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

    local propellerInfo

    panel:AddSlider("Blade Count", 2, 6, 0, "fin3_propeller_bladecount"):DockMargin(0, 0, 0, 0)
    panel:AddHelpText("The number of blades on the propeller.")

    panel:AddSlider("Diameter", 0.1, 6, 2, "fin3_propeller_diameter"):DockMargin(0, 0, 0, 0)
    panel:AddHelpText("The diameter of the propeller, in meters.")

    panel:AddSlider("Blade Angle", 0, 90, 0, "fin3_propeller_bladeangle"):DockMargin(0, 0, 0, 0)
    panel:AddHelpText(
        "The angle of the blades on the propeller, in degrees.\n" ..
        "90 degrees is feathered (aligned forwards airflow, minimal forwards drag).\n" ..
        "Propellers at 0 or 90 degrees cannot produce thrust.\n" ..
        "Low angles will have a lot of low speed thrust, but a low top speed.\n" ..
        "High angles will have a high top speed, but low overall thrust."
    )

    panel:AddCheckbox("Invert Spin Direction", "fin3_propeller_invert"):DockMargin(0, 0, 0, 7)
    panel:AddHelpText("Spin the propeller clockwise (when viewed from behind) if this is disabled, counter-clockwise if enabled."):DockMargin(10, 0, 10, 5)

    propellerInfo = panel:AddInfoBox(string.format(propInfoString, 68, 51, 154, 257))
end