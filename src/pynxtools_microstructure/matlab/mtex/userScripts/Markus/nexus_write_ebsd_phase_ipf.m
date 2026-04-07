function status = nexus_write_ebsd_phase_ipf(ebsd_orig, ebsd_grd, fpath, parent, perform_io, ipf_lgd_tsl_dct, ipf_lgd_mtx_dct, ipf_lgd_tsl_pg_map, ipf_lgd_mtx_pg_map)
% Generate default inverse pole figure plot (for each phase) for H5Web and write data to NeXus/HDF5 file

% ebsd_orig, ebsd_grd
% fpath: path and filename of NeXus/HDF5 results file
% parent: parent HDF5 group below which to write
% ebsd_orig = ebsd_raw;
% ebsd_grd = ebsd_sqr_ipf_hweb;
% fpath = ofpath;

% as white is a valid color in typical IPF plots, black is used to mark
% pixels which were not indexed to belong to the phase in question

if ~perform_io
    return;
end
h5w = HdfFiveSeqHdl(fpath);

n_phases = length(ebsd_grd.CSList);
if n_phases ~= length(ebsd_grd.mineralList)
    status = logical(0);
    return;
end

grid = fliplr([ebsd_grd.opt.nx, ebsd_grd.opt.ny]);
scan_unit = ebsd_grd.scanUnit;
n_count_orig_indexed = 0;
n_count_orig_total = length(ebsd_orig);

phase_id = 0;
for phase_idx = 1:1:n_phases

    % TODO: add a map for all those points not indexed

    grpnm = [parent '/phase' num2str(phase_id)];
    dsnm = [grpnm '/number_of_scan_points'];
    % for some examples the phaseMap starts at -1 for the notIndex
    % how many scan points of that phase in original EBSD map
    if min(ebsd_orig.phaseMap) == -1
        n_count_orig = sum(ebsd_orig.phase == (phase_id - 1));
    elseif min(ebsd_orig.phaseMap) == 0 || min(ebsd_orig.phaseMap) == 1
        n_count_orig = sum(ebsd_orig.phase == phase_id);
    else
        error('ERROR: The phaseMap for this EBSD map uses an unexpected indexing!');
    end
    attr = io_attributes();
    ret = h5w.nexus_write(dsnm, uint64(n_count_orig), attr);
    if ~strcmp(ebsd_orig.mineralList{phase_idx}, 'notIndexed')
        n_count_orig_indexed = n_count_orig_indexed + n_count_orig;
    end

    % how many scan points of that phase in eventually downsampled H5Web
    % preview of that IPF if any?
    if min(ebsd_grd.phaseMap) == -1
        n_count = sum(sum(ebsd_grd.phase == (phase_id - 1)));
    elseif min(ebsd_grd.phaseMap) == 0 || min(ebsd_grd.phaseMap) == 1
        n_count = sum(sum(ebsd_grd.phase == phase_id));
    else
        error('ERROR: The phaseMap for this EBSD map uses an unexpected indexing!');
    end

    if ~strcmp(ebsd_grd.mineralList{phase_idx}, 'notIndexed') & n_count > 0
        % the null-phase, for MTex @EBSD.phase == 0 but confusingly @EBSD.phaseId == 1 !
        % proj_vector = [vector3d.X, vector3d.Y, vector3d.Z];
        % proj_name = ['x', 'y', 'z'];
        phase_name = ebsd_grd.mineralList{phase_idx};
        disp(['nexus_write_ebsd_ipf ' num2str(phase_idx) '/' num2str(length(ebsd_grd.mineralList)) ' ' phase_name ' phase_id ' num2str(phase_id)]);
        % for proj_idx = 1:1:3
        color_models = {'tsl', 'mtex'};
        for cm = 1:1:2
            clearvars ipf_key pg colors nx_ipf_map_u8_f nxs_ipf_y nxs_ipf_x phase_i_idx low_level idx;
            % ipf_hsv_key = ipfHSVKey(ebsd_grd(phase_name));
            if cm == 1
                ipf_key = ipfTSLKey(ebsd_grd(phase_name));
            else
                ipf_key = ipfColorKey(ebsd_grd(phase_name));
            end
            ipf_key.inversePoleFigureDirection = vector3d.X;  % proj_idx);
            pg = ipf_key.CS1.pointGroup;
            disp(['pg ' pg]);
            colors = ipf_key.orientation2color(ebsd_grd(phase_name).orientations);
            % from normalized colors to RGB colors
            colors = uint8(uint32(colors * 255.)); % base color is black
            nxs_ipf_map_u8_f = uint8(uint32(zeros([3, grid(1) * grid(2)]) * 255.));
            nxs_ipf_y = ebsd_grd.y(:, 1)';
            nxs_ipf_x = ebsd_grd.x(1, :);

            % get array indices of all pixels that were indexed phase phase_idx
            if min(ebsd_grd.phaseMap) == -1
                phase_i_idx = uint32(ebsd_grd.id(ebsd_grd.phase == (phase_id - 1)));
            else
                phase_i_idx = uint32(ebsd_grd.id(ebsd_grd.phase == phase_id));
            end
            nxs_ipf_map_u8_f(:, phase_i_idx) = colors(1:length(phase_i_idx), :)';

            grpnm = [parent '/phase' num2str(phase_id) '/ipf' num2str(cm)];
            attr = io_attributes();
            attr.add('NX_class', 'NXmicrostructure_ipf');
            ret = h5w.nexus_write_group(grpnm, attr);

            dsnm = [grpnm '/projection_direction'];
            attr = io_attributes();
            % v = proj_vector(proj_idx);
            ret = h5w.nexus_write(dsnm, double(vector3d.X.xyz), attr);
            dsnm = [grpnm '/color_model'];
            attr = io_attributes();
            % v = proj_vector(proj_idx);
            ret = h5w.nexus_write(dsnm, color_models{cm}, attr);

            grpnm = [parent '/phase' num2str(phase_id) '/ipf' num2str(cm) '/map'];
            attr = io_attributes();
            attr.add('NX_class', 'NXdata');
            attr.add('signal', 'data');
            attr.add('axes', {'axis_y', 'axis_x'});
            attr.add('axis_y_indices', uint32(1));
            attr.add('axis_x_indices', uint32(0));
            ret = h5w.nexus_write_group(grpnm, attr);

            dsnm = [grpnm '/data'];
            % low_level = uint8(uint32(zeros([3 grid(2) grid(1)])));
            for x = 1:1:grid(2)
                offset = (x - 1) * grid(1);
                % for y = 1:1:grid(1)
                %     idx = y + offset;
                %     low_level(:, x, y) = nxs_ipf_map_u8_f(:, idx);
                % end
                % three-times faster than with the loop above
                low_level(:, x, 1:1:grid(1)) = nxs_ipf_map_u8_f(:, offset+1:1:offset+grid(1));
            end
            attr = io_attributes();
            attr.add('long_name', 'IPF color-coded orientation mapping');
            attr.add('CLASS', 'IMAGE');
            attr.add('IMAGE_VERSION', '1.2');
            attr.add('SUBCLASS_VERSION', uint32(15));
            ret = h5w.nexus_write(dsnm, low_level, attr);
            dsnm = [grpnm '/axis_y'];
            attr = io_attributes();
            attr.add('units', scan_unit);
            attr.add('long_name', ['Calibrated coordinate along y-axis (' scan_unit ')']);
            ret = h5w.nexus_write(dsnm, nxs_ipf_y, attr);
            dsnm = [grpnm '/axis_x'];
            attr = io_attributes();
            attr.add('units', scan_unit);
            attr.add('long_name', ['Calibrated coordinate along x-axis (' scan_unit ')']);
            ret = h5w.nexus_write(dsnm, nxs_ipf_x, attr);
            dsnm = [grpnm '/title'];
            ret = h5w.nexus_write(dsnm, ['IPF, X, ' pg ', ' color_models{cm} ', phase' num2str(phase_id) ', ' phase_name], attr);

            %% add specific IPF color key used
            grpnm = [parent '/phase' num2str(phase_id) '/ipf' num2str(cm) '/legend'];
            attr = io_attributes();
            attr.add('NX_class', 'NXdata');
            attr.add('signal', 'data');
            attr.add('axes', {'axis_y', 'axis_x'});
            attr.add('axis_y_indices', uint32(1));
            attr.add('axis_x_indices', uint32(0));
            ret = h5w.nexus_write_group(grpnm, attr);
            attr = io_attributes();
            % load precomputed data
            if cm == 1
                if isKey(ipf_lgd_tsl_dct, pg)
                    low_level = ipf_lgd_tsl_dct(pg);
                else
                    if isKey(ipf_lgd_tsl_pg_map, pg)
                        pg = ipf_lgd_tsl_pg_map(pg);
                        low_level = ipf_lgd_tsl_dct(pg);
                    else
                        msg = ['Unable to find ' pg ' in ipf_lgd_tsl_pg_map !'];
                        error msg;
                    end
                end
            else
                if isKey(ipf_lgd_mtx_dct, pg)
                    low_level = ipf_lgd_mtx_dct(pg);
                else
                    if isKey(ipf_lgd_mtx_pg_map, pg)
                        pg = ipf_lgd_mtx_pg_map(pg);
                        low_level = ipf_lgd_mtx_dct(pg);
                    else
                        msg = ['Unable to find ' pg ' in ipf_lgd_tsl_pg_map !'];
                        error msg;
                    end
                end
            end

            dsnm = [grpnm '/title'];
            ret = h5w.nexus_write(dsnm, ['IPF, X, ' pg ', ' color_models{cm} ', phase' num2str(phase_id) ', ' phase_name], attr);

            dsnm = [grpnm '/data'];
            attr = io_attributes();
            attr.add('long_name', 'Signal');
            attr.add('CLASS', 'IMAGE');
            attr.add('IMAGE_VERSION', '1.2');
            attr.add('SUBCLASS_VERSION', uint32(15));
            ret = h5w.nexus_write(dsnm, low_level, attr);
            % sz = size(im);
            sz = size(low_level); % 3 --> 0, x --> 1, y --> 2
            dsnm = [grpnm '/axis_y'];
            nxs_px_y = linspace(1, sz(3), sz(3));
            attr = io_attributes();
            attr.add('long_name', 'Pixel along y-axis');
            ret = h5w.nexus_write(dsnm, nxs_px_y, attr);
            dsnm = [grpnm '/axis_x'];
            nxs_px_x = linspace(1, sz(2), sz(2));
            attr = io_attributes();
            attr.add('long_name', 'Pixel along x-axis');
            ret = h5w.nexus_write(dsnm, nxs_px_x, attr);
        end
    end

    phase_id = phase_id + 1;
end

dsnm = [parent '/indexing_rate'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, ...
    double(double(n_count_orig_indexed) / ...
    double(n_count_orig_total)), attr);

disp('NeXus/HDF5 exporting of phase-specific IPFs: OK');
status = logical(1);

end
