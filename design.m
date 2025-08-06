function spreader = design ()
%% Inputs 
lengthhs = input('Enter the length of the heat source: ');
widthhs = input('Enter the width of the heat source: ');
heff = input('Enter the effective heat transfer coefficient (h): ');
k = input('Enter the thermal conductivity of the heat spreader (k): ');

%% Heat Spreader Inputs
startlen = input('Enter the start length of the heat spreader: ');
endlen = input('Enter the end length of the heat spreader: ');
n_div_len = input('Enter the divisions: ');
steplen  = (endlen - startlen) / n_div_len;
length_hs = startlen:steplen:endlen;

startwid = input('Enter the start width of the heat spreader: ');
endwid = input('Enter the end width of the heat spreader: ');
stepwid = steplen;  % Assuming square divisions
width_hs = startwid:stepwid:endwid;

startthic = input('Enter the start thickness of the heat spreader: ');
endthic = input('Enter the end thickness of the heat spreader: ');
n_div_thic = input('Enter the divisions of thickness: ');
stepthic  = (endthic - startthic) / n_div_thic;
thic_hs = startthic:stepthic:endthic;

%% r1 (heat source equivalent radius)
A_heatsource = lengthhs * widthhs;
r1 = sqrt(A_heatsource / pi);

%% r2 (heat spreader equivalent radius - all combinations)
% Create grids of all length-width combinations
[L_grid, W_grid] = meshgrid(length_hs, width_hs);
% Calculate equivalent radius for all combinations
r2_matrix = sqrt((L_grid .* W_grid) / pi);

%% epsilon (ratio of r1 to r2)
E = r1 ./ r2_matrix;

%% tau (thickness ratio)
tau = zeros(size(r2_matrix, 1), size(r2_matrix, 2), length(thic_hs));
for k_thic = 1:length(thic_hs)
    t = thic_hs(k_thic);
    tau(:, :, k_thic) = t ./ r2_matrix;
end

%% Biot Number
Bi = (heff .* r2_matrix) ./ k;

%% Lambda
lambda = pi + (1 ./ (E .* sqrt(pi)));  % element-wise division

%% phi (3D)
phi = zeros(size(tau));  % same size as tau
for k_thic = 1:length(thic_hs)
    lam_k = lambda;    
    tau_k = tau(:, :, k_thic);
    Bi_k = Bi;
    numerator = tanh(lam_k .* tau_k) + (lam_k ./ Bi_k);
    denominator = 1 + ((lam_k ./ Bi_k) .* tanh(lam_k .* tau_k));
    phi(:, :, k_thic) = numerator ./ denominator;
end

%% Vmax (3D)
Vmax = zeros(size(phi));
for k_thic = 1:length(thic_hs)
    Vmax(:, :, k_thic) = (E .* tau(:, :, k_thic)) / sqrt(pi) + ...
                         (1 / sqrt(pi)) .* (1 - E) .* phi(:, :, k_thic);
end

%% R_spreading (3D)
R_sp = Vmax ./ (k * r1 * sqrt(pi));  % dimensions match
%% 2D Curve Plot: R_sp vs Area for Different Thicknesses

% Create area matrix and flatten it
A_matrix = L_grid .* W_grid;  % Same as before
A_flat = A_matrix(:);

% Plotting
figure('Name', 'Spreading Resistance vs Area for Thicknesses', ...
       'NumberTitle', 'off', 'Position', [100, 100, 1000, 800]);

hold on;
colors = lines(length(thic_hs));
legend_entries = cell(1, length(thic_hs));

% Loop over each thickness slice
for k_thic = 1:length(thic_hs)
    R_sp_k = R_sp(:, :, k_thic);
    R_sp_flat = R_sp_k(:);
    
    % Sort by area for cleaner plotting
    [A_sorted, idx] = sort(A_flat);
    R_sorted = R_sp_flat(idx);
    
    plot(A_sorted*1e6, R_sorted, '-', 'Color', colors(k_thic,:), 'LineWidth', 2);
    legend_entries{k_thic} = sprintf('t = %.2f mm', thic_hs(k_thic)*1e3);
end

xlabel('Heat Spreader Area (mm²)');
ylabel('Spreading Resistance R_{sp} (K/W)');
title({'Spreading Resistance vs Heat Spreader Area', ...
       sprintf('Heat Source: %.2f x %.2f mm', lengthhs*1000, widthhs*1000)});
grid on;
box on;
legend(legend_entries, 'Location', 'northeast');
xline(A_heatsource*1e6, 'r--', 'LineWidth', 2, 'DisplayName', 'Heat Source Area');

% Enable interactive datacursor for user to pick values
datacursormode on;

text(A_heatsource*1e6, max(R_sp(:))*0.95, sprintf('Heat Source Area: %.2f mm²', A_heatsource*1e6), ...
     'Color', 'r', 'FontSize', 12, 'FontWeight', 'bold', ...
     'HorizontalAlignment', 'center', 'BackgroundColor', 'white');

hold off;
end
