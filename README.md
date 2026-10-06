I've been working on a new Guidance, Navigation, and Control (GNC) project recently: a dynamic orbital mechanics and attitude pointing simulation built entirely in MATLAB.

The goal was to model a Low Earth Orbit (LEO) trajectory, specifically based on the Aqua satellite, and develop a pointing algorithm that continuously reorients the spacecraft to track the Sun and maximize solar exposure.

In the simulation, the satellite dynamically computes its own orientation, adjusting its Roll, Pitch, and Yaw relative to its Local-Vertical Local-Horizontal (LVLH) frame. To ensure the environment was physically accurate, I constrained the target light source to the ecliptic plane, mapping the sun's exact declination based on the time of year rather than allowing arbitrary placement.

The attached video shows the script running across four different views. It features an interactive UI that updates the Earth-Centered Inertial (ECI) frame alongside a heliocentric orbital view, calculating the angular displacement and pointing error in real time.

Translating coordinate transformations, reference frames, and vector mechanics into a functioning, interactive model was a great hands-on challenge in flight control and spatial reasoning. I’m looking forward to applying these principles to more complex path planning and trajectory optimization systems.
