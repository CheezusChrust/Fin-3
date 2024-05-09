local fins = {}

net.Receive("fin3_networkfinids", function()
    for _ = 1, net.ReadUInt(10) do
        fins[net.ReadUInt(13)] = true
    end
end)

local cvarDebugEnabled = GetConVar("fin3_debug")
local cvarShowVectors = GetConVar("fin3_debug_showvectors")
local cvarShowForces = GetConVar("fin3_debug_showforces")

local RED, GREEN = Color(255, 0, 0), Color(0, 255, 0)
local BACKGROUND = Color(0, 0, 0, 230)

local function getForceString(newtons)
    local kgf = newtons / 15.24 -- GMod's gravity is 15.24m/s²

    if kgf < 1000 then
        return string.format("%dkg", kgf)
    else
        return string.format("%.2ft", kgf / 1000)
    end
end

hook.Add("HUDPaint", "fin3_hud", function()
    if cvarDebugEnabled:GetBool() then
        local showVectors = cvarShowVectors:GetBool()
        local showForces = cvarShowForces:GetBool()

        if showVectors or showForces then
            for index in pairs(fins) do
                local fin = Entity(index)

                if not IsValid(fin) or fin:GetNW2String("fin3_finType") == "" then
                    fins[index] = nil
                else
                    local finPos = fin:LocalToWorld(fin:OBBCenter())

                    if showVectors then
                        local liftVector = fin:GetNW2Vector("fin3_liftVector", vector_origin)
                        local dragVector = fin:GetNW2Vector("fin3_dragVector", vector_origin)

                        if liftVector ~= vector_origin or dragVector ~= vector_origin then
                            cam.Start3D()
                                render.SetColorMaterialIgnoreZ()
                                render.DrawBeam(finPos, finPos + liftVector / 5, 1, 0, 1, GREEN)
                                render.DrawBeam(finPos, finPos + dragVector / 5, 1, 0, 1, RED)
                            cam.End3D()
                        end
                    end

                    if showForces and fin:GetPos():DistToSqr(LocalPlayer():GetPos()) < 400000 then
                        local screenPos = finPos:ToScreen()

                        local liftVector = fin:GetNW2Vector("fin3_liftVector", vector_origin)
                        local dragVector = fin:GetNW2Vector("fin3_dragVector", vector_origin)
                        local liftForceStr = getForceString(liftVector:Length())
                        local dragForceStr = getForceString(dragVector:Length())

                        local text = string.format("Lift: %s\nDrag: %s", liftForceStr, dragForceStr)
                        surface.SetFont("Trebuchet18")
                        local textWidth, textHeight = surface.GetTextSize(text)
                        textWidth = textWidth + 10
                        textHeight = textHeight + 10

                        draw.RoundedBoxEx(8, screenPos.x - textWidth, screenPos.y - textHeight, textWidth, textHeight, BACKGROUND, true, true, true, false)
                        draw.DrawText(text, "Trebuchet18", screenPos.x - 5, screenPos.y - textHeight + 5, color_white, TEXT_ALIGN_RIGHT)
                    end
                end
            end
        end
    end

    local ply = LocalPlayer()
    local wep = ply:GetActiveWeapon()

    if IsValid(wep) and wep:GetClass() == "gmod_tool" and ply:GetInfo("gmod_toolmode") == "fin3" then
        local eyeTrace = ply:GetEyeTrace()
        local selected = ply:GetNW2Entity("fin3_selectedEntity")
        local ent = eyeTrace.Entity

        if IsValid(selected) then
            ent = selected
        end

        if not IsValid(ent) or not Fin3.allowedClasses[ent:GetClass()] then return end

        local fin2Eff = ent:GetNWFloat("efficency", 0)
        if fin2Eff ~= 0 and fin2Eff ~= -99 and fin2Eff ~= -100000000 then
            local drawPos = ent:LocalToWorld(ent:OBBCenter()):ToScreen()
            draw.SimpleTextOutlined("Warning: this entity still has Fin 2 applied!", "DermaLarge", drawPos.x, drawPos.y, RED, 1, 1, 1, color_black)
        end

        local tempUpAxis = ply:GetNW2Vector("fin3_tempUpAxis", vector_origin)
        local tempForwardAxis = ply:GetNW2Vector("fin3_tempForwardAxis", vector_origin)

        local centerPos = ent:LocalToWorld(ent:OBBCenter())
        local entSize = (ent:OBBMaxs() - ent:OBBMins()):Length() / 2

        if tempUpAxis ~= vector_origin then
            local worldTempUpAxis = Fin3.localToWorldVector(ent, tempUpAxis)

            cam.Start3D()
                render.SetColorMaterialIgnoreZ()
                render.DrawBeam(centerPos, centerPos + worldTempUpAxis * 25, 0.5, 0, 1, GREEN)
            cam.End3D()

            local upTextPos = (centerPos + worldTempUpAxis * 25):ToScreen()
            draw.SimpleTextOutlined("Lift Vector", "DermaLarge", upTextPos.x, upTextPos.y, GREEN, 1, 1, 1, color_black)
        end

        if tempForwardAxis ~= vector_origin then
            if tempForwardAxis ~= vector_origin and tempForwardAxis ~= tempUpAxis then
                local worldTempForwardAxis = Fin3.localToWorldVector(ent, tempForwardAxis)

                cam.Start3D()
                    render.SetColorMaterialIgnoreZ()
                    render.DrawBeam(centerPos, centerPos + worldTempForwardAxis * entSize, 0.5, 0, 1, RED)
                cam.End3D()

                local fwdTextPos = (centerPos + worldTempForwardAxis * entSize):ToScreen()
                draw.SimpleTextOutlined("Forward", "DermaLarge", fwdTextPos.x, fwdTextPos.y, RED, 1, 1, 1, color_black)
            else
                local invalidTextPos = centerPos:ToScreen()
                draw.SimpleTextOutlined("Invalid Forward Vector", "DermaLarge", invalidTextPos.x, invalidTextPos.y, RED, 1, 1, 1, color_black)
            end
        end

        local finType = ent:GetNW2String("fin3_finType", "")

        if finType == "" then return end

        local setUpAxis = Fin3.localToWorldVector(ent, ent:GetNW2Vector("fin3_upAxis", vector_origin))
        local setForwardAxis = Fin3.localToWorldVector(ent, ent:GetNW2Vector("fin3_forwardAxis", vector_origin))
        local zeroLiftAngle = ent:GetNW2Float("fin3_zeroLiftAngle", 0)
        local efficiency = ent:GetNW2Float("fin3_efficiency", 0)
        local surfaceArea = ent:GetNW2Float("fin3_surfaceArea", 0)
        local aspectRatio = ent:GetNW2Float("fin3_aspectRatio", 0)
        local inducedDrag = ent:GetNW2Float("fin3_inducedDrag", 0)

        cam.Start3D()
            render.SetColorMaterialIgnoreZ()
            render.DrawBeam(centerPos, centerPos + setForwardAxis * entSize, 0.5, 0, 1, RED)
            render.DrawBeam(centerPos, centerPos + setUpAxis * 25, 0.5, 0, 1, GREEN)
        cam.End3D()

        local fwdTextPos = (centerPos + setForwardAxis * entSize):ToScreen()
        draw.SimpleTextOutlined("Forward", "DermaLarge", fwdTextPos.x, fwdTextPos.y, RED, 1, 1, 1, color_black)

        local upTextPos = (centerPos + setUpAxis * 25):ToScreen()
        draw.SimpleTextOutlined("Lift Vector", "DermaLarge", upTextPos.x, upTextPos.y, GREEN, 1, 1, 1, color_black)

        surface.SetFont("Trebuchet18")
        local infoPos = centerPos:ToScreen()

        local text = string.format("Airfoil Type: %s\n%sEfficiency: %.2fx\nEffective Surface Area: %.2fm²\nAspect Ratio: %.2f\nInduced Drag: %.2fx",
            language.GetPhrase("tool.fin3.fintype." .. finType),
            zeroLiftAngle ~= 0 and string.format("Zero Lift Angle: -%.1f°\n", zeroLiftAngle) or "",
            efficiency,
            surfaceArea * efficiency,
            aspectRatio,
            inducedDrag
        )
        local textWidth, textHeight = surface.GetTextSize(text)

        draw.RoundedBoxEx(8, infoPos.x, infoPos.y, textWidth + 10, textHeight + 10, BACKGROUND, false, true, true, true)
        draw.DrawText(text, "Trebuchet18", infoPos.x + 5, infoPos.y + 5, color_white, TEXT_ALIGN_LEFT)
    end
end)
