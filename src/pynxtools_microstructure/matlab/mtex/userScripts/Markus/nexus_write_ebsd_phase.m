function status = nexus_write_ebsd_phase(ebsd_orig, fpath, parent, perform_io)
% Write list of phases to NeXus/HDF5 file

% ebsd_orig:
% fpath: path and filename of NeXus/HDF5 results file
% parent: parent HDF5 group below which to write

% as white is a valid color in typical IPF plots black is used to mark
% pixel which have no associated IPF color value
if ~perform_io
    return;
end
h5w = HdfFiveSeqHdl(fpath);


if strcmp(ebsd_orig.scanUnit, 'um')
    scan_unit = 'µm';
else
    scan_unit = lower(ebsd_orig.scanUnit);
end

n_phases = length(ebsd_orig.CSList);
if n_phases ~= length(ebsd_orig.mineralList)
    status = false;
    return;
end

n_count_orig_total = length(ebsd_orig);
% total number of scan points in the original mapping
dsnm = [parent '/number_of_scan_points'];
attr = io_attributes();
h5w.nexus_write(dsnm, uint64(n_count_orig_total), attr);
dsnm = [parent '/pixel_unit_cell'];
attr = io_attributes();
attr.add('units', scan_unit);
h5w.nexus_write(dsnm, ebsd_orig.unitCell.xy', attr);
dsnm = [parent '/pixel_shape'];
attr = io_attributes();
if length(ebsd_orig.unitCell.x) == 4
    h5w.nexus_write(dsnm, 'square', attr);
elseif length(ebsd_orig.unitCell.x) == 6
    h5w.nexus_write(dsnm, 'hexagon', attr);
else
    h5w.nexus_write(dsnm, 'other', attr);
end

phase_id = 0;
for phase_idx = 1:1:n_phases
    % there are more optional fields in the
    % NXem_ebsd_crystal_structure_model base class

    grpnm = [parent '/phase' num2str(phase_id)];
    attr = io_attributes();
    attr.add('NX_class', 'NXphase');
    h5w.nexus_write_group(grpnm, attr);

    dsnm = [grpnm '/name'];
    attr = io_attributes();
    h5w.nexus_write(dsnm, ebsd_orig.mineralList{phase_idx}, attr);

    dsnm = [grpnm '/phase_id'];
    attr = io_attributes();
    h5w.nexus_write(dsnm, int32(phase_id), attr);
    % in NeXus 0 is used for not indexed, Cstyle first i.e. 0th phase

    dsnm = [grpnm '/index_offset'];
    attr = io_attributes();
    h5w.nexus_write(dsnm, uint32(1), attr);
    % respecting the assumption that for MTex phase 0
    % is always notIndexed and boundary !

    % additional information for phases that have a point group
    if ~strcmp(ebsd_orig.mineralList{phase_idx}, 'notIndexed')
        grpnm = [parent '/phase' num2str(phase_id) '/unit_cell'];
        attr = io_attributes();
        attr.add('NX_class', 'NXunit_cell');
        h5w.nexus_write_group(grpnm, attr);
        attr = io_attributes();

        dsnm = [grpnm '/point_group'];
        h5w.nexus_write(dsnm, ebsd_orig.CSList{phase_idx}.pointGroup, attr);

        dsnm = [grpnm '/a'];
        attr = io_attributes();
        attr.add('units', 'nm');
        h5w.nexus_write(dsnm, ebsd_orig.CSList{phase_idx}.aAxis.x * 0.1, attr);
        dsnm = [grpnm '/b'];
        attr = io_attributes();
        attr.add('units', 'nm');
        h5w.nexus_write(dsnm, ebsd_orig.CSList{phase_idx}.bAxis.y * 0.1, attr);
        dsnm = [grpnm '/c'];
        attr = io_attributes();
        attr.add('units', 'nm');
        h5w.nexus_write(dsnm, ebsd_orig.CSList{phase_idx}.cAxis.z * 0.1, attr);
        % angstroem to nm

        dsnm = [grpnm '/alpha'];
        attr = io_attributes();
        attr.add('units', 'degree');
        h5w.nexus_write(dsnm, ebsd_orig.CSList{phase_idx}.alpha / pi * 180., attr);
        dsnm = [grpnm '/beta'];
        attr = io_attributes();
        attr.add('units', 'degree');
        h5w.nexus_write(dsnm, ebsd_orig.CSList{phase_idx}.beta / pi * 180., attr);
        dsnm = [grpnm '/gamma'];
        attr = io_attributes();
        attr.add('units', 'degree');
        h5w.nexus_write(dsnm, ebsd_orig.CSList{phase_idx}.gamma / pi * 180., attr);
        % rad to deg
        % TODO add all the other fields relevant
    end

    phase_id = phase_id + 1;
end
disp('NeXus/HDF5 exporting of phases: OK');
status = true;
end