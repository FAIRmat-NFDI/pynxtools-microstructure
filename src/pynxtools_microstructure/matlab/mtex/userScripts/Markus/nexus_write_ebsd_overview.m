function status = nexus_write_ebsd_overview(ebsd_implicit_sqr, fpath, parent, perform_io)
% Generate default plot for H5Wss eb and write data to NeXus/HDF5 file

% ebsd_obj
% fpath: path and filename of NeXus/HDF5 results file
% parent: parent HDF5 group below which to write
if ~perform_io
    return;
end
h5w = HdfFiveSeqHdl(fpath);

grid = fliplr([ebsd_implicit_sqr.opt.nx, ebsd_implicit_sqr.opt.ny]);
scan_unit = ebsd_implicit_sqr.scanUnit;

grpnm = [parent '/roi'];
attr = io_attributes();
attr.add('NX_class', 'NXdata');
attr.add('signal', 'data');
attr.add('axes', {'axis_y', 'axis_x'});
attr.add('axis_y_indices', uint32(1)); % int64 needed?
attr.add('axis_x_indices', uint32(0));
h5w.nexus_write_group(grpnm, attr);

if strcmp(ebsd_implicit_sqr.opt.descriptor_name, 'bc')
    % this will map NaN on zero (i.e. black in a grayscale/RGB color map)
    nxs_roi_map_u8_f = uint8(uint32( ...
        ebsd_implicit_sqr.opt.descriptor_value / ...
        max(max(ebsd_implicit_sqr.opt.descriptor_value)) * 255.));
    descriptor_name = 'band_contrast';
elseif strcmp(ebsd_implicit_sqr.opt.descriptor_name, 'ci')
    nxs_roi_map_u8_f = uint8(uint32( ...
        ebsd_implicit_sqr.opt.descriptor_value / ...
        max(max(ebsd_implicit_sqr.opt.descriptor_value)) * 255.));
    descriptor_name = 'confidence_index';
elseif strcmp(ebsd_implicit_sqr.opt.descriptor_name, 'confidenceindex')
    nxs_roi_map_u8_f = uint8(uint32( ...
        ebsd_implicit_sqr.opt.descriptor_value / ...
        max(max(ebsd_implicit_sqr.opt.descriptor_value)) * 255.));
    descriptor_name = 'confidence_index';
elseif strcmp(ebsd_implicit_sqr.opt.descriptor_name, 'mad')
    nxs_roi_map_u8_f = uint8(uint32( ...
        ebsd_implicit_sqr.opt.descriptor_value / ...
        max(max(ebsd_implicit_sqr.opt.descriptor_value)) * 255.));
    descriptor_name = 'mean_angular_deviation';
else
    error('Which descriptor for overview ROI must not be undefined!')
end
% not thrown ?

dsnm = [grpnm '/descriptor'];
attr = io_attributes();
h5w.nexus_write(dsnm, descriptor_name, attr);

dsnm = [grpnm '/data'];
attr = io_attributes();
attr.add('long_name', 'Signal');
attr.add('CLASS', 'IMAGE');
attr.add('IMAGE_VERSION', '1.2');
attr.add('SUBCLASS_VERSION', uint32(15));
h5w.nexus_write(dsnm, reshape(nxs_roi_map_u8_f, grid)', attr);

% ... and dimension scale axes positions
dsnm = [grpnm '/axis_y'];
nxs_bc_y = ebsd_implicit_sqr.y(:, 1)';
attr = io_attributes();
attr.add('units', scan_unit);
attr.add('long_name', ['Calibrated coordinate along y-axis (', scan_unit, ')']);
h5w.nexus_write(dsnm, nxs_bc_y, attr);
dsnm = [grpnm '/axis_x'];
nxs_bc_x = ebsd_implicit_sqr.x(1, :);
attr = io_attributes();
attr.add('units', scan_unit);
attr.add('long_name', ['Calibrated coordinate along x-axis (', scan_unit, ')']);
h5w.nexus_write(dsnm, nxs_bc_x, attr);

dsnm = [grpnm '/title'];
h5w.nexus_write(dsnm, ['Region-of-interest ', descriptor_name], attr);

disp('NeXus/HDF5 exporting of ROI overview: OK');
status = true;

end