local PANEL = {}

surface.CreateFont("fin3_labeltext", {
    font = "Roboto",
    size = 16,
    weight = 550
})

function PANEL:Init()
    self.Panels = {}
end

function PANEL:AddPanel(type)
    local panel = vgui.Create(type, self)
    panel:Dock(TOP)
    panel:DockMargin(0, 10, 0, 0)
    table.insert(self.Panels, panel)
    self:InvalidateLayout()

    return panel
end

function PANEL:AddLabel(text)
    local panel = self:AddPanel("DLabel")
    panel:SetText(text)
    panel:SetFont("fin3_labeltext")
    panel:SetColor(Color(0, 0, 0))
    panel:SetWrap(true)
    panel:SetAutoStretchVertical(true)

    return panel
end

function PANEL:AddHelpText(text)
    local panel = self:AddLabel(text)
    panel:SetFont("DermaDefault")
    panel:DockMargin(10, 0, 10, 15)

    return panel
end

function PANEL:AddInfoBox(text)
    local panel = self:AddPanel("fin3_panel")

    local text = panel:AddLabel(text)

    function panel:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(225, 225, 225))
    end

    text:DockMargin(5, 5, 5, 5)

    function panel:SetText(str)
        text:SetText(str)
    end

    return panel
end

function PANEL:AddSlider(title, min, max, decimals, convar)
    local panel = self:AddPanel("DNumSlider")
    panel:SetText(title)
    panel:SetMin(min)
    panel:SetMax(max)
    panel:SetDecimals(decimals)
    if convar then panel:SetConVar(convar) end

    panel.Label:SetColor(Color(0, 0, 0))
    panel.Label:SetFont("fin3_labeltext")

    return panel
end

function PANEL:AddCheckbox(title, convar)
    local panel = self:AddPanel("DCheckBoxLabel")
    panel:SetText(title)
    panel.Label:SetFont("fin3_labeltext")
    panel.Label:SetColor(Color(0, 0, 0))
    if convar then panel:SetConVar(convar) end

    return panel
end

function PANEL:AddComboBox(label, default)
    local container = self:AddPanel("fin3_panel")
    container:SetTall(16)

    local label = container:AddLabel(label)
    label:Dock(LEFT)
    label:DockMargin(0, 0, 20, 0)

    local selection = container:AddPanel("DComboBox")
    selection:SetValue(default)
    selection:Dock(FILL)
    selection:DockMargin(0, 0, 0, 0)

    function container:PerformLayout()
        local _, labelHeight = label:GetTextSize()
        local _, selectionHeight = selection:GetTextSize()

        container:SetTall(math.max(labelHeight, selectionHeight))
    end

    return selection
end

function PANEL:AddHideableContainer()
    local panel = self:AddPanel("fin3_panel")
    panel:DockMargin(10, 10, 10, 0)

    function panel:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(225, 225, 225))
    end

    panel.OldSetVisible = panel.SetVisible

    function panel:SetVisible(visible)
        self:OldSetVisible(visible)
        self:InvalidateParent()
    end

    return panel
end

function PANEL:PerformLayout()
    local totalHeight = 0
    for _, panel in ipairs(self.Panels) do
        if panel:IsVisible() then
            local _, top, _, bottom = panel:GetDockMargin()
            totalHeight = totalHeight + panel:GetTall() + top + bottom
        end
    end

    local _, panelTop, _, panelBottom = self:GetDockPadding()
    self:SetTall(totalHeight + panelTop + panelBottom)
end

function PANEL:Paint() end

vgui.Register("fin3_panel", PANEL, "Panel")