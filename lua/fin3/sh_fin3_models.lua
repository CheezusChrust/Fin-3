local sin, cos = math.sin, math.cos
local pi = math.pi
local deg2rad = pi / 180

-- https://wilroyj.wordpress.com/wp-content/uploads/2016/04/predictions-of-vortex-lift-characteristics-by-a-leading-edge-suction-analogy.pdf
local fighterKp = 2.3 -- potential lift factor
local fighterKv = 2 -- vortex lift factor

-- keep the drag around 1.35 by the time it reaches 90 deg
local fighterKp_drag = 1.535
local fighterKv_drag = 1.335

Fin3.models = {
    -- https://web.archive.org/web/20240925030114/https://aviation.stackexchange.com/questions/21391/what-is-the-performance-of-a-flat-plate-wing
    flat = {
        stallAngle = 5,
        liftCoefPeakPreStall = 0.55,
        liftCoefPeakPostStall = 1.05,
        dragCoefPeakPreStall = 0.05,
        dragCoefPeakPostStall = 1.82
    },

    standard = {
        stallAngle = 15,
        liftCoefPeakPreStall = 1.5,
        liftCoefPeakPostStall = 1.05,
        dragCoefPeakPreStall = 0.05,
        dragCoefPeakPostStall = 1.82,
        canCamber = true,
        maxCamber = 12, -- Maximum zero-lift angle in degrees, determines how much camber affects lift

        -- Values below are multiplied by camber amount - only used if canCamber is true
        negativeAoACamberPeakLiftCoefPenalty = 0.4, -- Lift coefficient penalty for negative AoA
        negativeAoACamberPeakStallAnglePenalty = 7.5, -- Stall angle penalty for negative AoA
        positiveAoACamberStallAngleBonus = 1.5 -- Increase stall angle for positive AoA
    },

    fighter = {
        customLiftCoef = function(aoa)
            local aoaRad = aoa * deg2rad

            return fighterKp * sin(aoaRad) * cos(aoaRad) ^ 2 + fighterKv * sin(aoaRad) ^ 2 * cos(aoaRad)
        end,

        customDragCoef = function(aoa)
            local aoaRad = aoa * deg2rad

            return fighterKp_drag * sin(aoaRad) ^ 3 * cos(aoaRad) + fighterKv_drag * sin(aoaRad) ^ 3
        end,

        canCamber = true,
        maxCamber = 12
    },

    propeller = {
        stallAngle = 15,
        liftCoefPeakPreStall = 1.15,
        liftCoefPeakPostStall = 0.95,
        dragCoefPeakPreStall = 0.05,
        dragCoefPeakPostStall = 1.82,
        hidden = true
    }
}
