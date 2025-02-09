local fins = {}
local propellers = {}

local fin3Models = Fin3.models
local sqrt, abs, max = math.sqrt, math.abs, math.max
local sin, cos, deg2rad = math.sin, math.cos, math.pi / 180
local setFont, getTextSize = surface.SetFont, surface.GetTextSize
local drawRoundedBoxEx, drawText, drawBeam = draw.RoundedBoxEx, draw.DrawText, render.DrawBeam
local drawWireframeSphere = render.DrawWireframeSphere
local drawSimpleTextOutlined = draw.SimpleTextOutlined
local setColorMaterialIgnoreZ = render.SetColorMaterialIgnoreZ
local camStart3D, camEnd3D = cam.Start3D, cam.End3D
local format = string.format
local allowedClasses, localToWorldVector = Fin3.allowedClasses, Fin3.localToWorldVector
local getPhrase = language.GetPhrase

local cvarShowVectors = GetConVar("fin3_debug_showvectors")
local cvarShowData = GetConVar("fin3_debug_showdata")
local cvarPropellerShowData = GetConVar("fin3_propeller_debug_showdata")

local RED, GREEN, LIGHTBLUE = Color(255, 0, 0), Color(0, 255, 0), Color(0, 255, 255)
local BACKGROUND = Color(0, 0, 0, 230)

local centerOfLift = vector_origin
local lastCenterOfLiftTime = 0

net.Receive("fin3_centeroflift", function()
    centerOfLift = Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
    lastCenterOfLiftTime = CurTime()
end)

net.Receive("fin3_networkfinids", function()
    for _ = 1, net.ReadUInt(10) do
        fins[net.ReadUInt(13)] = true
    end
end)

net.Receive("fin3_networkpropellerids", function()
    for _ = 1, net.ReadUInt(10) do
        propellers[net.ReadUInt(13)] = true
    end
end)

local function getForceString(newtons)
    local kgf = newtons / 15.24 -- GMod's gravity is 15.24m/s²

    if kgf < 1000 then
        return format("%dkg", kgf)
    else
        return format("%.2ft", kgf / 1000)
    end
end

local function pushGetAvg(value, tbl, samples)
    tbl[#tbl + 1] = value

    if #tbl > samples then
        table.remove(tbl, 1)
    end

    local sum = 0

    for i = 1, #tbl do
        sum = sum + tbl[i]
    end

    return sum / #tbl
end

local function drawCenterOfLift()
    local textPos = (centerOfLift + Vector(0, 0, 8)):ToScreen()
    drawSimpleTextOutlined("Center of Lift", "DermaDefault", textPos.x, textPos.y, LIGHTBLUE, 1, 1, 1, color_black)

    cam.Start3D()
        drawWireframeSphere(centerOfLift, 4, 8, 8, LIGHTBLUE)
    cam.End3D()
end

local function drawDebugInfo()
    local showVectors = cvarShowVectors:GetBool()
    local showData = cvarShowData:GetBool()

    if showVectors or showData then
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
                        local liftLength = liftVector:Length()
                        local dragLength = dragVector:Length()

                        local scaledLiftVector = liftVector:GetNormalized() * sqrt(liftLength)
                        local scaledDragVector = dragVector:GetNormalized() * sqrt(dragLength)

                        camStart3D()
                            setColorMaterialIgnoreZ()
                            drawBeam(finPos, finPos + scaledLiftVector, 1, 0, 1, GREEN)
                            drawBeam(finPos, finPos + scaledDragVector, 1, 0, 1, RED)
                        camEnd3D()
                    end
                end

                if showData and fin:GetPos():DistToSqr(LocalPlayer():GetPos()) < 400000 then
                    local screenPos = finPos:ToScreen()

                    local liftVector = fin:GetNW2Vector("fin3_liftVector", vector_origin)
                    local dragVector = fin:GetNW2Vector("fin3_dragVector", vector_origin)
                    local liftForceStr = getForceString(liftVector:Length())
                    local dragForceStr = getForceString(dragVector:Length())
                    local AoA = fin:GetNW2Float("fin3_aoa", 0)

                    local text = format("Lift: %s\nDrag: %s\nAoA: %.1f°", liftForceStr, dragForceStr, AoA)
                    setFont("Trebuchet18")
                    local textWidth, textHeight = getTextSize(text)
                    textWidth = textWidth + 10
                    textHeight = textHeight + 10

                    drawRoundedBoxEx(8, screenPos.x - textWidth, screenPos.y - textHeight, textWidth, textHeight, BACKGROUND, true, true, true, false)
                    drawText(text, "Trebuchet18", screenPos.x - 5, screenPos.y - textHeight + 5, color_white, TEXT_ALIGN_RIGHT)
                end
            end
        end
    end
end

local function drawFin3Hud(localPly)
    local eyeTrace = localPly:GetEyeTrace()
    local selected = localPly:GetNW2Entity("fin3_selectedEntity")
    local ent = eyeTrace.Entity

    if IsValid(selected) then
        ent = selected
    end

    if not IsValid(ent) or not allowedClasses[ent:GetClass()] then return end

    local fin2Eff = ent:GetNWFloat("efficency", 0)
    if fin2Eff ~= 0 and fin2Eff ~= -99 and fin2Eff ~= -100000000 then
        local drawPos = ent:LocalToWorld(ent:OBBCenter()):ToScreen()
        drawSimpleTextOutlined("Warning: this entity still has Fin 2 applied!", "DermaLarge", drawPos.x, drawPos.y, RED, 1, 1, 1, color_black)
    end

    local tempUpAxis = localPly:GetNW2Vector("fin3_tempUpAxis", vector_origin)
    local tempForwardAxis = localPly:GetNW2Vector("fin3_tempForwardAxis", vector_origin)

    local centerPos = ent:LocalToWorld(ent:OBBCenter())
    local entSize = (ent:OBBMaxs() - ent:OBBMins()):Length() / 2

    if tempUpAxis ~= vector_origin then
        local worldTempUpAxis = localToWorldVector(ent, tempUpAxis)

        camStart3D()
            setColorMaterialIgnoreZ()
            drawBeam(centerPos, centerPos + worldTempUpAxis * 25, 0.5, 0, 1, GREEN)
        camEnd3D()

        local upTextPos = (centerPos + worldTempUpAxis * 25):ToScreen()
        drawSimpleTextOutlined("Lift Vector", "DermaLarge", upTextPos.x, upTextPos.y, GREEN, 1, 1, 1, color_black)
    end

    if tempForwardAxis ~= vector_origin then
        if tempForwardAxis ~= vector_origin and tempForwardAxis ~= tempUpAxis then
            local worldTempForwardAxis = localToWorldVector(ent, tempForwardAxis)

            camStart3D()
                setColorMaterialIgnoreZ()
                drawBeam(centerPos, centerPos + worldTempForwardAxis * entSize, 0.5, 0, 1, RED)
            camEnd3D()

            local fwdTextPos = (centerPos + worldTempForwardAxis * entSize):ToScreen()
            drawSimpleTextOutlined("Forward", "DermaLarge", fwdTextPos.x, fwdTextPos.y, RED, 1, 1, 1, color_black)
        else
            local invalidTextPos = centerPos:ToScreen()
            drawSimpleTextOutlined("Invalid Forward Vector", "DermaLarge", invalidTextPos.x, invalidTextPos.y, RED, 1, 1, 1, color_black)
        end
    end

    local finType = ent:GetNW2String("fin3_finType", "")

    if finType == "" then return end

    local setUpAxis = localToWorldVector(ent, ent:GetNW2Vector("fin3_upAxis", vector_origin))
    local setForwardAxis = localToWorldVector(ent, ent:GetNW2Vector("fin3_forwardAxis", vector_origin))
    local camber = ent:GetNW2Float("fin3_camber", 0)
    local efficiency = ent:GetNW2Float("fin3_efficiency", 0)
    local surfaceArea = ent:GetNW2Float("fin3_surfaceArea", 0)
    local aspectRatio = ent:GetNW2Float("fin3_aspectRatio", 0)
    local sweepAngle = ent:GetNW2Float("fin3_sweepAngle", 0)
    local inducedDrag = ent:GetNW2Float("fin3_inducedDrag", 0)
    local lowpass = ent:GetNW2Bool("fin3_lowpass", false)

    camStart3D()
        setColorMaterialIgnoreZ()
        drawBeam(centerPos, centerPos + setForwardAxis * entSize, 0.5, 0, 1, RED)
        drawBeam(centerPos, centerPos + setUpAxis * 25, 0.5, 0, 1, GREEN)
    camEnd3D()

    local fwdTextPos = (centerPos + setForwardAxis * entSize):ToScreen()
    drawSimpleTextOutlined("Forward", "DermaLarge", fwdTextPos.x, fwdTextPos.y, RED, 1, 1, 1, color_black)

    local upTextPos = (centerPos + setUpAxis * 25):ToScreen()
    drawSimpleTextOutlined("Lift Vector", "DermaLarge", upTextPos.x, upTextPos.y, GREEN, 1, 1, 1, color_black)

    setFont("Trebuchet18")
    local infoPos = centerPos:ToScreen()

    local text = format("Airfoil Type: %s\n%sEfficiency: %.2fx\nEffective Surface Area: %.2fm²\nAspect Ratio: %.2f\nInduced Drag: %.2fx",
        getPhrase("tool.fin3.fintype." .. finType),
        fin3Models[finType].canCamber and format(getPhrase("tool.fin3.camber") .. ": %d%%\n", camber) or "",
        efficiency,
        surfaceArea * efficiency,
        aspectRatio,
        inducedDrag
    )

    if sweepAngle ~= 0 then
        text = text .. format("\nSweep Angle: %.1f°", sweepAngle)
    end

    if lowpass then
        text = text .. "\nLow-pass filter enabled"
    end

    local textWidth, textHeight = getTextSize(text)

    drawRoundedBoxEx(8, infoPos.x, infoPos.y, textWidth + 10, textHeight + 10, BACKGROUND, false, true, true, true)
    drawText(text, "Trebuchet18", infoPos.x + 5, infoPos.y + 5, color_white, TEXT_ALIGN_LEFT)
end

local thrustAvgs = {}
local rpmAvgs = {}
local torqueAvgs = {}

local function drawPropellerDebugInfo()
    local showData = cvarPropellerShowData:GetBool()

    if showData then
        for index in pairs(propellers) do
            local propeller = Entity(index)

            if not IsValid(propeller) or propeller:GetNW2Int("fin3_propeller_bladeCount") == 0 then
                propellers[index] = nil
                thrustAvgs[index] = nil
                rpmAvgs[index] = nil
                torqueAvgs[index] = nil
            else
                local propellerPos = propeller:LocalToWorld(propeller:OBBCenter())

                if propeller:GetPos():DistToSqr(LocalPlayer():GetPos()) < 400000 then
                    local screenPos = propellerPos:ToScreen()

                    rpmAvgs[index] = rpmAvgs[index] or {}
                    thrustAvgs[index] = thrustAvgs[index] or {}
                    torqueAvgs[index] = torqueAvgs[index] or {}

                    local thrust = getForceString(pushGetAvg(propeller:GetNW2Float("fin3_propeller_thrust"), thrustAvgs[index], 30))
                    local torque = pushGetAvg(abs(propeller:GetNW2Float("fin3_propeller_torque")), torqueAvgs[index], 30)
                    local aoa = propeller:GetNW2Float("fin3_propeller_aoa")
                    local rpm = pushGetAvg(propeller:GetNW2Float("fin3_propeller_rpm"), rpmAvgs[index], 30)
                    local bladePitch = propeller:GetNW2Float("fin3_propeller_bladePitch")

                    if propeller:GetNW2Bool("fin3_propeller_invertRotation") then
                        rpm = -rpm
                    end

                    local text = format("Thrust: %s\nDrag Torque: %dNm\nBlade Pitch: %.1f°\nAoA: %.1f°\nRPM: %d", thrust, torque, bladePitch, aoa, rpm)
                    setFont("Trebuchet18")
                    local textWidth, textHeight = getTextSize(text)
                    textWidth = textWidth + 10
                    textHeight = textHeight + 10

                    drawRoundedBoxEx(8, screenPos.x - textWidth, screenPos.y - textHeight, textWidth, textHeight, BACKGROUND, true, true, true, false)
                    drawText(text, "Trebuchet18", screenPos.x - 5, screenPos.y - textHeight + 5, color_white, TEXT_ALIGN_RIGHT)
                end
            end
        end
    end
end

local vec_x = Vector(1, 0, 0)
local vec_y = Vector(0, 1, 0)

local function drawFin3PropellerHud(localPly)
    local trace = localPly:GetEyeTrace()
    local ent = trace.Entity

    if not IsValid(ent) or not allowedClasses[ent:GetClass()] then return end

    local centerPos = ent:LocalToWorld(ent:OBBCenter())
    local forward = ent:GetNW2Vector("fin3_propeller_forwardAxis", vector_origin)
    local worldForward = localToWorldVector(ent, forward)
    local diameter = ent:GetNW2Float("fin3_propeller_diameter", 0)
    local bladeCount = ent:GetNW2Int("fin3_propeller_bladeCount", 0)
    local invertRotation = ent:GetNW2Bool("fin3_propeller_invertRotation", false)

    local hasPropeller = forward ~= vector_origin

    if not hasPropeller then
        forward = Fin3.roundVectorToAxis(Fin3.worldToLocalVector(ent, trace.HitNormal))
        diameter = localPly:GetInfoNum("fin3_propeller_diameter", 2)
        bladeCount = localPly:GetInfoNum("fin3_propeller_bladecount", 2)
        invertRotation = localPly:GetInfoNum("fin3_propeller_invert", 0) == 1
    end

    local worldForward = localToWorldVector(ent, forward)

    local radiusUnits = diameter * 39.3701 / 2

    local v
    if abs(vec_x:Dot(forward)) == 1 then
        v = vec_y
    elseif abs(vec_y:Dot(forward)) == 1 then
        v = vec_x
    else
        v = vec_x
    end

    local v2 = forward:Cross(v):GetNormalized()

    setColorMaterialIgnoreZ()

    cam.Start3D()
        local div = 360 / bladeCount
        for i = 0, bladeCount - 1 do
            local angle = (-CurTime() * 32 + i * div) * deg2rad
            if invertRotation then angle = -angle end

            drawBeam(centerPos, centerPos + localToWorldVector(ent, v * sin(angle) + v2 * cos(angle)) * radiusUnits, 1, 0, 1, color_white)
        end

        for i = 1, 32 do
            local angle = i / 32 * 2 * math.pi
            local angle2 = (i - 1) / 32 * 2 * math.pi

            local x = math.cos(angle)
            local y = math.sin(angle)
            local x2 = math.cos(angle2)
            local y2 = math.sin(angle2)

            render.DrawLine(centerPos + localToWorldVector(ent, v * x + v2 * y) * radiusUnits, centerPos + localToWorldVector(ent, v * x2 + v2 * y2) * radiusUnits, color_white)
        end

        local forwardSize = max(abs((ent:OBBMaxs() - ent:OBBMins()):Dot(forward)) / 2, 16)
        local forwardPos = centerPos + worldForward * forwardSize

        drawBeam(centerPos, forwardPos, 0.5, 0, 1, GREEN)
    cam.End3D()

    local fwdTextPos = (centerPos + worldForward * forwardSize):ToScreen()
    drawSimpleTextOutlined("Forward", "DermaLarge", fwdTextPos.x, fwdTextPos.y, GREEN, 1, 1, 1, color_black)

    if not hasPropeller then return end

    local bladeCount = ent:GetNW2Int("fin3_propeller_bladeCount", 0)
    local bladePitch = ent:GetNW2Float("fin3_propeller_bladePitch", 0)

    setFont("Trebuchet18")
    local text = format("Blade Count: %d\nDiameter: %.2fm\nBlade Pitch: %.1f°", bladeCount, diameter, bladePitch)

    local textWidth, textHeight = getTextSize(text)
    textWidth = textWidth
    textHeight = textHeight

    local infoPos = centerPos:ToScreen()

    drawRoundedBoxEx(8, infoPos.x, infoPos.y, textWidth + 10, textHeight + 10, BACKGROUND, false, true, true, true)
    drawText(text, "Trebuchet18", infoPos.x + 5, infoPos.y + 5, color_white, TEXT_ALIGN_LEFT)
end

hook.Add("HUDPaint", "fin3_hud", function()
    drawDebugInfo()
    drawPropellerDebugInfo()

    if CurTime() - lastCenterOfLiftTime < 10 then
        drawCenterOfLift()
    end

    local localPly = LocalPlayer()
    local wep = localPly:GetActiveWeapon()
    local toolmode = localPly:GetInfo("gmod_toolmode")

    if not IsValid(wep) or wep:GetClass() ~= "gmod_tool" then return end

    if toolmode == "fin3" then
        drawFin3Hud(localPly)
    elseif toolmode == "fin3_propeller" then
        drawFin3PropellerHud(localPly)
    end
end)
