Fin3.models = {
    -- https://web.archive.org/web/20240925030114/https://aviation.stackexchange.com/questions/21391/what-is-the-performance-of-a-flat-plate-wing
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

    -- https://web.archive.org/web/20240925030940/http://airfoiltools.com/airfoil/details?airfoil=naca4412-il
    cambered = {
        curves = {
            lift = {
                {x = -90, y = 0},
                {x = -75, y = -0.83},
                {x = -60, y = -1.01},
                {x = -50, y = -1.05},
                {x = -40, y = -0.9},
                {x = -30, y = -0.68},
                {x = -20, y = -0.35},
                {x = -10, y = -0.55},
                {x = 0, y = 0},
                {x = 5, y = 0.5},
                {x = 10, y = 1},
                {x = 15, y = 1.4},
                {x = 22, y = 1.6},
                {x = 28, y = 0.8},
                {x = 35, y = 0.9},
                {x = 45, y = 1.05},
                {x = 55, y = 1},
                {x = 65, y = 0.88},
                {x = 75, y = 0.65},
                {x = 83, y = 0.35},
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
                {x = -5, y = 0.01},
                {x = 0, y = 0.01},
                {x = 5, y = 0.01},
                {x = 10, y = 0.015},
                {x = 15, y = 0.03},
                {x = 20, y = 0.1},
                {x = 25, y = 0.3},
                {x = 30, y = 0.5},
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