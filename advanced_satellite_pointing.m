function advanced_satellite_pointing()
    fig = figure('Name', 'Aqua Ecliptic & Orbital Simulation', 'Color', 'k', ...
                 'Position', [100, 100, 1400, 600], 'WindowButtonDownFcn', @userClickTarget);
             
    ax1 = subplot(1, 2, 1, 'Parent', fig, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', 'ZColor', 'w');
    hold(ax1, 'on'); grid(ax1, 'on'); axis(ax1, 'equal'); view(ax1, 3);
    set(ax1, 'XLim', [-25000 25000], 'YLim', [-25000 25000], 'ZLim', [-25000 25000]);
    xlabel(ax1, 'ECI X [km]'); ylabel(ax1, 'ECI Y [km]'); zlabel(ax1, 'ECI Z [km]');
    title(ax1, 'ECI View: Aqua Pointing & Sun Vector', 'Color', 'w', 'FontSize', 12);
    
    ax2 = subplot(1, 2, 2, 'Parent', fig, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', 'ZColor', 'w');
    hold(ax2, 'on'); grid(ax2, 'on'); axis(ax2, 'equal'); view(ax2, 3);
    set(ax2, 'XLim', [-1.5 1.5], 'YLim', [-1.5 1.5], 'ZLim', [-1.5 1.5]);
    xlabel(ax2, 'X [AU]'); ylabel(ax2, 'Y [AU]'); zlabel(ax2, 'Z [AU]');
    title(ax2, 'Heliocentric View: Earth Orbit', 'Color', 'w', 'FontSize', 12);

    uicontrol('Style', 'pushbutton', 'String', 'Iso', 'Position', [20 20 60 30], 'Callback', @(~,~) view(ax1, 3));
    uicontrol('Style', 'pushbutton', 'String', 'Top (XY)', 'Position', [90 20 60 30], 'Callback', @(~,~) view(ax1, 0, 90));
    uicontrol('Style', 'pushbutton', 'String', 'Front (XZ)', 'Position', [160 20 70 30], 'Callback', @(~,~) view(ax1, 0, 0));
    uicontrol('Style', 'pushbutton', 'String', 'Side (YZ)', 'Position', [240 20 70 30], 'Callback', @(~,~) view(ax1, 90, 0));
    uicontrol('Style', 'text', 'String', 'Click in the left graph to change the time of year!', ...
              'Position', [320 20 250 25], 'BackgroundColor', 'k', 'ForegroundColor', 'y', 'FontSize', 10);

    mu = 3.986e5;            % Earth gravitational parameter [km^3/s^2]
    R_earth = 6371;          % Earth radius [km]
    a = 7077.6;              % Aqua Semi-major axis [km]
    e = 0.000137;            % Aqua Eccentricity
    i = deg2rad(98.2);       % Aqua Inclination [rad]
    Omega = deg2rad(45);     % RAAN [rad]
    omega = deg2rad(90);     % Argument of perigee [rad]
    p = a * (1 - e^2);       % Semi-latus rectum [km]
    epsilon = deg2rad(23.44); % Obliquity of the Ecliptic

    % ECI Earth (ax1)
    [X_e, Y_e, Z_e] = sphere(50);
    surf(ax1, X_e*R_earth, Y_e*R_earth, Z_e*R_earth, 'EdgeColor', 'none', 'FaceColor', 'b', 'FaceAlpha', 0.6, 'HitTest', 'off');
    
    % Sun and Earth's orbit track in Heliocentric (ax2)
    plot3(ax2, 0, 0, 0, 'y*', 'MarkerSize', 30, 'LineWidth', 3); % Central Sun
    theta_orbit = linspace(0, 2*pi, 100);
    plot3(ax2, cos(theta_orbit), cos(epsilon)*sin(theta_orbit), sin(epsilon)*sin(theta_orbit), 'w--', 'LineWidth', 1);
    helio_earth_plot = plot3(ax2, -1, 0, 0, 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b');

    % Interactive Light Source (ax1)
    sun_dist_vis = 22000; % Visual distance for ECI Sun
    setappdata(fig, 'LambdaSun', 0); % Initial Ecliptic Longitude (Vernal Equinox)
    light_plot = plot3(ax1, sun_dist_vis, 0, 0, 'y*', 'MarkerSize', 20, 'LineWidth', 2, 'HitTest', 'off');
    
    % Ecliptic Plane Indicator (ax1)
    plot3(ax1, sun_dist_vis*cos(theta_orbit), sun_dist_vis*cos(epsilon)*sin(theta_orbit), sun_dist_vis*sin(epsilon)*sin(theta_orbit), 'y:', 'LineWidth', 1, 'HitTest', 'off');
    
    % Bright Neon Satellite Geometry
    sat_hg = hgtransform('Parent', ax1);
    [sX, sY, sZ] = cylinder([0.5, 0], 20);
    surf(sZ*3000, sY*1500, sX*1500, 'Parent', sat_hg, 'FaceColor', '#00FFFF', ...
        'EdgeColor', '#FFFFFF', 'AmbientStrength', 0.9, 'HitTest', 'off');

    % HUD Initialization
    hud = annotation(fig, 'textbox', [0.42, 0.45, 0.16, 0.45], 'Color', 'w', ...
                     'BackgroundColor', 'k', 'EdgeColor', 'cyan', 'FitBoxToText', 'on', ...
                     'FontName', 'Courier', 'FontSize', 9);

    % ECI Transformation Matrix
    R3_W = [cos(Omega) -sin(Omega) 0; sin(Omega) cos(Omega) 0; 0 0 1];
    R1_i = [1 0 0; 0 cos(i) -sin(i); 0 sin(i) cos(i)];
    R3_w = [cos(omega) -sin(omega) 0; sin(omega) cos(omega) 0; 0 0 1];
    T_PQW_ECI = R3_W * R1_i * R3_w;
    
    % Simulation Loop Vars.
    nu = 0;             % Aqua True anomaly [rad]
    dt_nu = 0.04;       % Aqua orbital speed
    dt_lambda = 0.002;  % Earth orbital speed
    
    while ishandle(fig)
        % Keplerian to Cartesian ECI
        r_mag = p / (1 + e * cos(nu)); 
        r_PQW = [r_mag * cos(nu); r_mag * sin(nu); 0]; 
        v_PQW = sqrt(mu/p) * [-sin(nu); e + cos(nu); 0]; 
        
        r_ECI = T_PQW_ECI * r_PQW; % Position [km]
        v_ECI = T_PQW_ECI * v_PQW; % Velocity [km/s]
        
        % Constrained Sun Vector
        lambda = getappdata(fig, 'LambdaSun');

        % Ecliptic coordinates to ECI constraints
        sun_vec_unit = [cos(lambda); cos(epsilon)*sin(lambda); sin(epsilon)*sin(lambda)];
        
        % Sun in ECI (ax1)
        sun_pos_eci = sun_dist_vis * sun_vec_unit;
        set(light_plot, 'XData', sun_pos_eci(1), 'YData', sun_pos_eci(2), 'ZData', sun_pos_eci(3));
        
        % Earth in Heliocentric (ax2)
        set(helio_earth_plot, 'XData', -sun_vec_unit(1), 'YData', -sun_vec_unit(2), 'ZData', -sun_vec_unit(3));
        
        % LVLH Frame Definition
        z_LVLH = -r_ECI / norm(r_ECI);
        y_LVLH = -cross(r_ECI, v_ECI) / norm(cross(r_ECI, v_ECI));
        x_LVLH = cross(y_LVLH, z_LVLH);
        T_ECI_LVLH = [x_LVLH, y_LVLH, z_LVLH]';
        
        % Target Pointing Calculation
        v_targ = sun_pos_eci - r_ECI; 
        v_hat = v_targ / norm(v_targ); 
        
        b_x = v_hat;
        b_y = cross(z_LVLH, b_x); 
        if norm(b_y) < 1e-5
            b_y = cross(x_LVLH, b_x);
        end
        b_y = b_y / norm(b_y);
        b_z = cross(b_x, b_y);
        
        T_ECI_Body = [b_x, b_y, b_z]';
        
        % Roll, Pitch, Yaw
        T_LVLH_Body = T_ECI_Body * T_ECI_LVLH';
        pitch = asin(-T_LVLH_Body(1,3)); 
        roll = atan2(T_LVLH_Body(2,3), T_LVLH_Body(3,3)); 
        yaw = atan2(T_LVLH_Body(1,2), T_LVLH_Body(1,1)); 
        
        % Pointed angular error
        pointing_error = acos(max(min(dot(b_x, v_hat), 1), -1)); 
        
        % Apply Graphics Transform
        M_rot = eye(4);
        M_rot(1:3, 1:3) = T_ECI_Body';
        M_trans = makehgtform('translate', r_ECI');
        set(sat_hg, 'Matrix', M_trans * M_rot);
        
        % 6. Update HUD
        declination = asin(sun_vec_unit(3)); % Sun Declination
        
        hud_str = sprintf([...
            'AQUA TELEMETRY\n', ...
            '===============\n', ...
            'Roll       : %6.2f%c\n', ...
            'Pitch      : %6.2f%c\n', ...
            'Yaw        : %6.2f%c\n', ...
            'Point Error: %6.4f%c\n', ...
            '---------------\n', ...
            'ORBITAL PARAMS\n', ...
            'Inc        : %6.2f%c\n', ...
            'RAAN       : %6.2f%c\n', ...
            'True Anom  : %6.2f%c\n', ...
            '---------------\n', ...
            'SOLAR VECTORS\n', ...
            'Ecliptic Lon: %6.2f%c\n', ...
            'Declination : %6.2f%c\n', ...
            '(Capped at %c23.44%c)\n'], ...
            rad2deg(roll), char(176), rad2deg(pitch), char(176), rad2deg(yaw), char(176), rad2deg(pointing_error), char(176), ...
            rad2deg(i), char(176), rad2deg(Omega), char(176), rad2deg(mod(nu, 2*pi)), char(176), ...
            rad2deg(mod(lambda, 2*pi)), char(176), rad2deg(declination), char(176), char(177), char(176));
        set(hud, 'String', hud_str);
       
        nu = nu + dt_nu;
        lambda = lambda + dt_lambda;
        setappdata(fig, 'LambdaSun', lambda);
        drawnow;
    end
    
    function userClickTarget(~, ~)
        % Ecliptic Longitude
        click_pts = get(ax1, 'CurrentPoint');
        
        % (X,Y) of the ray in the ECI frame
        cx = click_pts(1, 1);
        cy = click_pts(1, 2);
        
        % Lambda from click
        new_lambda = atan2(cy, cx);
        setappdata(gcf, 'LambdaSun', new_lambda);
        fprintf('Time of year shifted! Ecliptic Longitude now %.1f deg.\n', rad2deg(new_lambda));
    end
end