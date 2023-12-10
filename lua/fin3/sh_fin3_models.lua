Fin3.models = {
    -- https://aviation.stackexchange.com/questions/21391/what-is-the-performance-of-a-flat-plate-wing
    flat = {
        curves = {
            lift = {
                {x = 0, y = 0},
                {x = 5, y = 0.55},
                {x = 10, y = 0.35},
                {x = 20, y = 0.68},
                {x = 30, y = 0.9},
                {x = 40, y = 1.05},
                {x = 50, y = 1},
                {x = 60, y = 0.88},
                {x = 70, y = 0.65},
                {x = 80, y = 0.35},
                {x = 90, y = 0}
            },
            drag = {
                {x = 0, y = 0.03},
                {x = 5, y = 0.05},
                {x = 8, y = 0.07},
                {x = 10, y = 0.12},
                {x = 20, y = 0.3},
                {x = 30, y = 0.6},
                {x = 40, y = 0.9},
                {x = 50, y = 1.25},
                {x = 60, y = 1.5},
                {x = 70, y = 1.7},
                {x = 80, y = 1.8},
                {x = 90, y = 1.82}
            }
        }
    },

    -- https://web.archive.org/web/20041101225159/http://www.prod.sandia.gov/cgi-bin/techlib/access-control.pl/1980/802114.pdf
    -- "Aerodynamic Characteristics of Seven Symmetrical Airfoil Sections Through 180-Degree Angle of Attack"
    symmetrical = {
        curves = {
            lift = {
                {x = 0, y = 0},
                {x = 5, y = 0.6},
                {x = 10, y = 0.9},
                {x = 15, y = 1.1},
                {x = 20, y = 0.68},
                {x = 30, y = 0.9},
                {x = 40, y = 1.05},
                {x = 50, y = 1},
                {x = 60, y = 0.88},
                {x = 70, y = 0.65},
                {x = 80, y = 0.35},
                {x = 90, y = 0}
            },
            drag = {
                {x = 0, y = 0.01},
                {x = 5, y = 0.02},
                {x = 10, y = 0.03},
                {x = 15, y = 0.06},
                {x = 17, y = 0.15},
                {x = 20, y = 0.3},
                {x = 30, y = 0.6},
                {x = 40, y = 0.9},
                {x = 50, y = 1.25},
                {x = 60, y = 1.5},
                {x = 70, y = 1.7},
                {x = 80, y = 1.8},
                {x = 90, y = 1.82}
            }
        }
    },

    -- http://airfoiltools.com/airfoil/details?airfoil=naca4412-il
    cambered = {
        curves = {
            lift = {
                {x = -90, y = 0},
                {x = -75, y = -0.83},
                {x = -65, y = -1.01},
                {x = -55, y = -1.05},
                {x = -45, y = -0.9},
                {x = -35, y = -0.68},
                {x = -25, y = -0.35},
                {x = -15, y = -0.55},
                {x = -5, y = 0},
                {x = 0, y = 0.5},
                {x = 5, y = 1},
                {x = 10, y = 1.4},
                {x = 17, y = 1.6},
                {x = 23, y = 0.8},
                {x = 30, y = 0.9},
                {x = 40, y = 1.05},
                {x = 50, y = 1},
                {x = 60, y = 0.88},
                {x = 70, y = 0.65},
                {x = 80, y = 0.35},
                {x = 90, y = 0}
            },
            drag = {
                {x = -90, y = 1.82},
                {x = -80, y = 1.8},
                {x = -70, y = 1.65},
                {x = -60, y = 1.15},
                {x = -50, y = 0.8},
                {x = -40, y = 0.5},
                {x = -30, y = 0.3},
                {x = -20, y = 0.09},
                {x = -15, y = 0.04},
                {x = -5, y = 0.02},
                {x = 0, y = 0.02},
                {x = 5, y = 0.02},
                {x = 10, y = 0.04},
                {x = 15, y = 0.12},
                {x = 23, y = 0.3},
                {x = 30, y = 0.6},
                {x = 40, y = 0.9},
                {x = 50, y = 1.25},
                {x = 60, y = 1.5},
                {x = 70, y = 1.7},
                {x = 80, y = 1.8},
                {x = 90, y = 1.82}
            },
        },
        isCambered = true
    }
}

if Fin3.createInterpolatedCurves then Fin3.createInterpolatedCurves() end

if CLIENT then
    language.Add("tool.fin3.fintype.flat", "Flat Plate")
    language.Add("tool.fin3.fintype.flat.info",
        "Flat plates stall at a very low AoA (around 5 degrees), and have much higher drag than conventional airfoils when at any AoA higher than 0. " ..
        "Generally not recommended for most aircraft as flat plates have poor flight characteristics."
    )

    language.Add("tool.fin3.fintype.symmetrical", "Symmetrical")
    language.Add("tool.fin3.fintype.symmetrical.info",
        "Symmetrical airfoils do not produce lift at 0 AoA, and can resist stalling up to around 15 degrees. " ..
        "Recommended for any non-lifting fins such as control surfaces."
    )

    language.Add("tool.fin3.fintype.cambered", "Cambered")
    language.Add("tool.fin3.fintype.cambered.info",
        "Cambered airfoils produce a lifting force at 0 AoA, and can resist stalling up to around 15 degrees. " ..
        "Recommended for the main wing of an aircraft.\n" ..
        "The zero lift angle determines the AoA at which the wing produces no lift.\n(SLIDER CURRENTLY DOES NOTHING)"
    )
end