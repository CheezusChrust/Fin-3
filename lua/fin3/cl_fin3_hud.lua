local fins = {}

net.Receive("fin3_sendfins", function()
    fins = {}

    local count = net.ReadUInt(12)

    for _ = 1, count do
        fins[#fins + 1] = net.ReadEntity()
    end
end)

hook.Add("HUDPaint", "fin3_hud", function()
    if GetConVar("fin3_debug"):GetBool() then
        if not GetConVar("fin3_debug"):GetBool() then return end

        cam.Start3D()
            for _, sentFin in pairs(fins) do
                if not IsValid(sentFin) then continue end

                local liftVector = sentFin:GetNW2Vector("fin3_liftVector", vector_origin)
                local dragVector = sentFin:GetNW2Vector("fin3_dragVector", vector_origin)

                if liftVector == vector_origin and dragVector == vector_origin then continue end

                render.SetColorMaterialIgnoreZ()
                render.DrawBeam(sentFin:GetPos(), sentFin:GetPos() + liftVector / 5, 1, 0, 1, Color(0, 255, 0))
                render.DrawBeam(sentFin:GetPos(), sentFin:GetPos() + dragVector / 5, 1, 0, 1, Color(255, 0, 0))
            end
        cam.End3D()
    end

    local ply = LocalPlayer()

    if ply:GetActiveWeapon():IsValid() and ply:GetActiveWeapon():GetClass() == "gmod_tool" and ply:GetInfo("gmod_toolmode") == "fin3" then
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
        local efficiency = ent:GetNW2Float("fin3_efficiency", 0)
        local surfaceArea = ent:GetNW2Float("fin3_surfaceArea", 0)
        local aspectRatio = ent:GetNW2Float("fin3_aspectRatio", 0)

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
            local text = string.format("Airfoil Type: %s\nEfficiency: %.2fx\nEffective Surface Area: %.2fm^2\nAspect Ratio: %.2f",
                language.GetPhrase("tool.fin3.fintype." .. finType),
                efficiency,
                surfaceArea * efficiency,
                aspectRatio
            )
            local textWidth, textHeight = surface.GetTextSize(text)

            draw.RoundedBoxEx(8, infoPos.x, infoPos.y, textWidth + 10, textHeight + 10, Color(0, 0, 0, 230), false, true, true, true)
            draw.DrawText(text, "Trebuchet18", infoPos.x + 5, infoPos.y + 5, Color(255, 255, 255), TEXT_ALIGN_LEFT)
        end
    end
end)
