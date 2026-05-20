% have MTex started, I used MTex v6.1.1 and Matlab 2025b
clear; clc;

ifpath_main = fullfile(pwd, 'examples', '162.f75d30a7c21369a2b4ef68264ca0656463d4c0094474a0687122efda3254b394.ctf');
ebsd_raw = EBSD.load(ifpath_main, 'convertSpatial2EulerReferenceFrame', 'setting 2');

phase_idx = 9;
phase_name = ebsd_raw.mineralList{phase_idx};
cs = ebsd_raw.CSList{phase_idx};
ss = specimenSymmetry('triclinic');
kernel_type = SO3DeLaValleePoussinKernel('halfwidth', 5. * degree);

odf = calcDensity(ebsd_raw(phase_name).orientations, ...
    'kernel', kernel_type, 'resolution', 2.5 * degree);

% kth_extrema_io
[intensity, maxima] = max(odf, 'numLocal', 3);
V = zeros([1, length(maxima)]);
for i = 1:1:length(maxima)
    V(i) = volume(odf, maxima(i), 10.*degree);
    % breaks here with the following exception
    % Operands to the logical AND (&&) and OR (||) operators must be convertible to logical scalar values. Use the ANY or ALL functions to reduce operands to logical scalar values.
    % Error in SO3FunHarmonic/volume (line 48)
    % radius>minAngle || SO3F.antipodal
    % ^^^^^^
end

% ...
% non circular components
% [ori_nc, vol_nc] = calcComponents(odf);
% e1_e2_e3 = zeros(3, length(ori_nc));
% e1_e2_e3(1, :) = ori_nc(:).phi1 / degree;
% ...

