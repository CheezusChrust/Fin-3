Fin3.models = {
    flat = {
        liftCurve = {
            [0] = 0,
            [5] = 0.55,
            [10] = 0.35,
            [20] = 0.68,
            [30] = 0.9,
            [40] = 1.05,
            [50] = 1,
            [60] = 0.88,
            [70] = 0.65,
            [80] = 0.35,
            [90] = 0
        },
        dragCurve = {
            [0] = 0.03,
            [5] = 0.05,
            [8] = 0.07,
            [10] = 0.12,
            [20] = 0.3,
            [30] = 0.6,
            [40] = 0.9,
            [50] = 1.25,
            [60] = 1.5,
            [70] = 1.7,
            [80] = 1.8,
            [90] = 1.82
        }
    },

    symmetrical = {
        liftCurve = {},
        dragCurve = {},
    },

    cambered = {
        liftCurve = {},
        dragCurve = {},
    }
}

if CLIENT then
    language.Add("tool.fin3.fintype.flat", "Flat Plate")
    language.Add("tool.fin3.fintype.flat.info",
        "Flat plates stall at a very low AoA, and have much higher drag than conventional airfoils when at any AoA higher than 0. " ..
        "Generally not recommended for most aircraft as flat plates have poor flight characteristics."
    )

    language.Add("tool.fin3.fintype.symmetrical", "Symmetrical (NACA 0015)")
    language.Add("tool.fin3.fintype.symmetrical.info",
        "Symmetrical airfoils do not produce lift at 0 AoA, and can resist stalling up to around 15 degrees. " ..
        "Recommended for any non-lifting fins such as control surfaces."
    )

    language.Add("tool.fin3.fintype.cambered", "Cambered (NACA 4412)")
    language.Add("tool.fin3.fintype.cambered.info",
        "Cambered airfoils produce a lifting force at 0 AoA, and can resist stalling up to around 15 degrees. " ..
        "Recommended for the main wing of an aircraft."
    )
end