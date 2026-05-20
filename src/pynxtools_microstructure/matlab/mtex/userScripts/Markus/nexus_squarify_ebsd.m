function out = nexus_squarify_ebsd(ebsd_orig, varargin)

nlimit = get_option(varargin,'h5web_max_size');

if strcmp(ebsd_orig.scanUnit, 'um')
    scan_unit = 'µm'; 
else
    scan_unit = lower(ebsd_orig.scanUnit);
end
% get roi extent assuming x and y are scan point center positions 
% individually exact details depend on the flight plan of the scan box
% from the microscope
xmin = min(ebsd_orig.pos.x);
xmax = max(ebsd_orig.pos.x);
ymin = min(ebsd_orig.pos.y);
ymax = max(ebsd_orig.pos.y);
% zmin = min(ebsd_orig.pos.z);
% zmax = max(ebsd_orig.pos.z);

% sz = size(ebsd_orig.unitCell);
% sz(1) == 4 for square grid and sz(1) == 6 for (flat-top?) hexagon grid
dx0 = abs(median(diff(unique(ebsd_orig.pos.x, 'stable'))));
dy0 = abs(median(diff(unique(ebsd_orig.pos.y, 'stable'))));
% dz0 = abs(median(diff(unique(ebsd_orig.pos.z, 'stable'))));

% estimate resulting size of the grid when staying close to original uc
nx0 = ceil((xmax - xmin) / dx0);
ny0 = ceil((ymax - ymin) / dy0);
% nz0 = ceil((zmax - zmin) / dz0);

% H5Web has a maximum edge number in pixel along for each image axis for
% the contrast image of the ROI we use a heatmap which has a larger limit
% do not upscale smaller maps but scale down larger maps
% 3D maps are technically typically not exceeding the rendering
% capabilities of H5Web 3D RGB plots
scaler = 1.;
if nx0 > nlimit || ny0 > nlimit
    if nx0 > ny0
        scaler = nlimit / nx0;
    else
        scaler = nlimit / ny0;
    end
end

% decide the rediscretization grid
hx = 0.5 * (dx0 / scaler);
hy = 0.5 * (dy0 / scaler);
nx = 1 + round(nx0 * scaler);
ny = 1 + round(ny0 * scaler);

% generate interpolation grid
[x, y] = meshgrid( ...
    linspace(xmin, xmax, nx), ...
    linspace(ymin, ymax, ny));
% TODO extent to 3D

kdtree = KDTreeSearcher([ebsd_orig.pos.x, ebsd_orig.pos.y]);
closest_scan_point_id = uint64(knnsearch(kdtree, [x(:), y(:)]));
np = length(closest_scan_point_id);
clearvars kdtree;

out = EBSD();
out.x = x;
out.y = y;
out.z = zeros([np, 1]);
out.how2plot = ebsd_orig(closest_scan_point_id).how2plot;
out.id = int64(linspace(1, np, np)');
out.rotations = ebsd_orig(closest_scan_point_id).rotations;
out.unitCell = [+hx, +hy; -hx, +hx; -hx, -hy; +hx, -hy];
out.phaseId = ebsd_orig(closest_scan_point_id).phaseId;
out.CSList = ebsd_orig(closest_scan_point_id).CSList;
out.phaseMap = ebsd_orig(closest_scan_point_id).phaseMap;
out.phase = ebsd_orig(closest_scan_point_id).phase;
out.scanUnit = scan_unit;
out.opt.nx = nx;
out.opt.ny = ny;
out.opt.hx = hx;
out.opt.hy = hy;
out.opt.nlimit = nlimit;
out.opt.kdtree = closest_scan_point_id;
out.opt.descriptor_name = 'undefined';
for descriptor = {'bc', 'ci', 'confidenceindex', 'mad'}
    if isfield(ebsd_orig.prop, char(descriptor))
        out.opt.descriptor_name = char(descriptor);
        out.opt.descriptor_value = ebsd_orig(closest_scan_point_id).getProp(char(descriptor));
        break;
    end
end
% no z 2D-case for now
disp(['NeXus/HDF5 regridding for H5Web ' num2str(scaler) ', ' num2str(nx) ', ' num2str(ny) ': OK']);
end