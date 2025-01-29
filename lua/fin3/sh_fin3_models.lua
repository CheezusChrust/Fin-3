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
        dragCoefPeakPostStall = 1.82
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
