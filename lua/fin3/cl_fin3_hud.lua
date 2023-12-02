hook.Add("HUDPaint", "fin3_hud", function()
    local ply = LocalPlayer()
    if not ply:GetActiveWeapon():IsValid() or ply:GetActiveWeapon():GetClass() ~= "gmod_tool" or ply:GetInfo("gmod_toolmode") ~= "fin3" then return end

    local eyeTrace = ply:GetEyeTrace()

    local ent = eyeTrace.Entity
    if not IsValid(ent) or not Fin3.allowedClasses[ent:GetClass()] then return end

    local upAxis, forwardAxis = Fin3.getPropAxesFromTrace(eyeTrace)
    upAxis = Fin3.localToWorldVector(ent, upAxis)
    forwardAxis = Fin3.localToWorldVector(ent, forwardAxis)
    local centerPos = ent:LocalToWorld(ent:OBBCenter())
    local entSize = (ent:OBBMaxs() - ent:OBBMins()):Length() / 2

    local finType = ent:GetNW2String("fin3_finType", "")
    local setUpAxis = Fin3.localToWorldVector(ent, ent:GetNW2Vector("fin3_upAxis", vector_origin))
    local setForwardAxis = Fin3.localToWorldVector(ent, ent:GetNW2Vector("fin3_forwardAxis", vector_origin))
    local forceMultiplier = ent:GetNW2Float("fin3_forceMultiplier", 0)

    local upAxisIndicated = upAxis
    local forwardAxisIndicated = forwardAxis
    if finType ~= "" then
        upAxisIndicated = setUpAxis
        forwardAxisIndicated = setForwardAxis
    end

    local dot = upAxis:Dot(forwardAxis)
    if dot > -0.9 and dot < 0.9 and forwardAxis ~= vector_origin then
        cam.Start3D()
            render.SetColorMaterialIgnoreZ()
            render.DrawBeam(centerPos, centerPos + forwardAxisIndicated * entSize, 1, 0, 1, Color(255, 0, 0))
            render.DrawBeam(centerPos, centerPos + upAxisIndicated * 25, 1, 0, 1, Color(0, 255, 0))
        cam.End3D()

        local fwdTextPos = (centerPos + forwardAxisIndicated * entSize):ToScreen()
        draw.SimpleTextOutlined("Forward", "DermaLarge", fwdTextPos.x, fwdTextPos.y, Color(255, 0, 0), 1, 1, 1, Color(0, 0, 0))

        local upTextPos = (centerPos + upAxisIndicated * 25):ToScreen()
        draw.SimpleTextOutlined("Up", "DermaLarge", upTextPos.x, upTextPos.y, Color(0, 255, 0), 1, 1, 1, Color(0, 0, 0))
    else
        draw.TextShadow({
            text = "Fin's forward axis must be perpendicular to its upward axis!",
            font = "DermaLarge",
            pos = {ScrW() / 2, ScrH() / 2},
            color = Color(255, 0, 0),
            xalign = TEXT_ALIGN_CENTER,
            yalign = TEXT_ALIGN_CENTER
        }, 1, 255)
    end

    if finType ~= "" then
        surface.SetFont("Trebuchet18")
        local infoPos = centerPos:ToScreen()
        local text = string.format("Airfoil Type: %s\nForce Multiplier: %.2fx", language.GetPhrase("tool.fin3.fintype." .. finType), forceMultiplier)
        local textWidth, textHeight = surface.GetTextSize(text)

        draw.RoundedBoxEx(8, infoPos.x, infoPos.y, textWidth + 10, textHeight + 10, Color(0, 0, 0, 230), false, true, true, true)
        draw.DrawText(text, "Trebuchet18", infoPos.x + 5, infoPos.y + 5, Color(255, 255, 255), TEXT_ALIGN_LEFT)
    end
end)
