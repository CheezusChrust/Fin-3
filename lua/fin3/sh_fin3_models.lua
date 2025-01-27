Fin3.models = {
    -- https://web.archive.org/web/20240925030114/https://aviation.stackexchange.com/questions/21391/what-is-the-performance-of-a-flat-plate-wing
    flat = {
        stallAngle = 5,
        liftCoefPeakPreStall = 0.55,
        liftCoefPeakPostStall = 1.05,
        dragCoefPeakPreStall = 0.05,
        dragCoefPeakPostStall = 1.82
    },

    -- https://web.archive.org/web/20041101225159/http://www.prod.sandia.gov/cgi-bin/techlib/access-control.pl/1980/802114.pdf
    -- "Aerodynamic Characteristics of Seven Symmetrical Airfoil Sections Through 180-Degree Angle of Attack"
    symmetrical = {
        stallAngle = 16,
        liftCoefPeakPreStall = 1.5,
        liftCoefPeakPostStall = 1.05,
        dragCoefPeakPreStall = 0.05,
        dragCoefPeakPostStall = 1.82
    },

    -- https://web.archive.org/web/20240925030940/http://airfoiltools.com/airfoil/details?airfoil=naca4412-il
    cambered = {
        isCambered = true,
        stallAngle = 16,
        liftCoefPeakPreStall = 1.6,
        liftCoefPeakPostStall = 1.05,
        dragCoefPeakPreStall = 0.05,
        dragCoefPeakPostStall = 1.82
    }
}
