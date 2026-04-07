function status = nexus_write_mtex_preferences(fpath, parent, perform_io)
% Export current MTex and Matlab settings to NeXus/HDF5 file

% fpath: path and filename of NeXus/HDF5 results file
% parent: parent HDF5 group below which to write

if ~perform_io
    return;
end
h5w = HdfFiveSeqHdl(fpath);

mtex_pref = getMTEXpref;

grpnm = [parent '/mtex'];
attr = io_attributes();
attr.add('NX_class', 'NXmicrostructure_mtex_config');
ret = h5w.nexus_write_group(grpnm, attr);

% resetting attr and use it until again an HDF5 node with
% attributes is required
%% versions
grpnm = [parent '/mtex/program1']; % matlab
attr = io_attributes();
attr.add('NX_class', 'NXprogram');
ret = h5w.nexus_write_group(grpnm, attr);

dsnm = [grpnm '/program'];
attr = io_attributes();
attr.add('version', version);
ret = h5w.nexus_write(dsnm, 'Matlab', attr);

grpnm = [parent '/mtex/program2']; % mtex
attr = io_attributes();
attr.add('NX_class', 'NXprogram');
ret = h5w.nexus_write_group(grpnm, attr);

dsnm = [grpnm '/program'];
attr = io_attributes();
% generate via CLI command
% git describe --dirty --tags --long --abbrev=8 --match '*[0-9]*' >mtex-version.txt
mtex_version = strtrim(fileread([pwd '/mtex-version.txt']));
attr.add('version', mtex_version);  % mtex_pref.version);
ret = h5w.nexus_write(dsnm, 'MTex', attr);
%% conventions
grpnm = [parent '/mtex/conventions'];
attr = io_attributes();
attr.add('NX_class', 'NXcollection');
ret = h5w.nexus_write_group(grpnm, attr);

% attr = io_attributes();
% dsnm = [grpnm '/x_axis_direction'];
% ret = h5w.nexus_write(dsnm, mtex_pref.xAxisDirection, attr);
% dsnm = [grpnm '/z_axis_direction'];
% ret = h5w.nexus_write(dsnm, mtex_pref.zAxisDirection, attr);
% dsnm = [grpnm '/a_axis_direction'];
% if ~strcmp(mtex_pref.aAxisDirection, '')
%     ret = h5w.nexus_write(dsnm, mtex_pref.aAxisDirection, attr);
% else
%     ret = h5w.nexus_write(dsnm, 'n/a', attr);
% end
% dsnm = [grpnm '/b_axis_direction'];
% ret = h5w.nexus_write(dsnm, mtex_pref.bAxisDirection, attr);
dsnm = [grpnm '/euler_angle'];
if strcmp(mtex_pref.EulerAngleConvention, 'Bunge')
    ret = h5w.nexus_write(dsnm, mtex_pref.EulerAngleConvention, attr);
else
    ret = h5w.nexus_write(dsnm, 'undefined', attr);
end

%% plotting
grpnm = [parent '/mtex/plotting'];
attr = io_attributes();
attr.add('NX_class', 'NXcollection');
ret = h5w.nexus_write_group(grpnm, attr);
attr = io_attributes();
dsnm = [grpnm '/font_size'];
ret = h5w.nexus_write(dsnm, double(mtex_pref.FontSize), attr);
dsnm = [grpnm '/inner_plot_spacing'];
ret = h5w.nexus_write(dsnm, double(mtex_pref.innerPlotSpacing), attr);
dsnm = [grpnm '/outer_plot_spacing'];
ret = h5w.nexus_write(dsnm, double(mtex_pref.outerPlotSpacing), attr);
dsnm = [grpnm '/marker_size'];
ret = h5w.nexus_write(dsnm, double(mtex_pref.markerSize), attr);
dsnm = [grpnm '/figure_size'];
ret = h5w.nexus_write(dsnm, mtex_pref.figSize, attr);
dsnm = [grpnm '/show_micron_bar'];
if strcmp(mtex_pref.showMicronBar, 'on')
    ret = h5w.nexus_write(dsnm, uint8(1), attr);
else
    ret = h5w.nexus_write(dsnm, uint8(0), attr);
end
dsnm = [grpnm '/show_coordinates'];
if strcmp(mtex_pref.showCoordinates, 'on')
    ret = h5w.nexus_write(dsnm, uint8(1), attr);
else
    ret = h5w.nexus_write(dsnm, uint8(0), attr);
end
dsnm = [grpnm '/pf_anno_fun_hdl'];
ret = h5w.nexus_write(dsnm, func2str(mtex_pref.pfAnnotations), attr);
dsnm = [grpnm '/color_map'];
ret = h5w.nexus_write(dsnm, double(mtex_pref.colors), attr);
dsnm = [grpnm '/default_map'];
ret = h5w.nexus_write(dsnm, double(mtex_pref.defaultColorMap), attr);
dsnm = [grpnm '/color_palette'];
ret = h5w.nexus_write(dsnm, mtex_pref.colorPalette, attr);
dsnm = [grpnm '/degree_character'];
% TODO add PhaseColorOrder
ret = h5w.nexus_write(dsnm, mtex_pref.degreeChar, attr);
dsnm = [grpnm '/arrow_character'];
ret = h5w.nexus_write(dsnm, mtex_pref.arrowChar, attr);
dsnm = [grpnm '/marker'];
ret = h5w.nexus_write(dsnm, mtex_pref.annotationStyle{2}, attr);
dsnm = [grpnm '/marker_edge_color'];
ret = h5w.nexus_write(dsnm, mtex_pref.annotationStyle{4}, attr);
dsnm = [grpnm '/marker_face_color'];
ret = h5w.nexus_write(dsnm, mtex_pref.annotationStyle{6}, attr);
dsnm = [grpnm '/hit_test'];
if strcmp(mtex_pref.annotationStyle{8}, 'off')
    ret = h5w.nexus_write(dsnm, uint8(0), attr);
else
    ret = h5w.nexus_write(dsnm, uint8(1), attr);
end
% phaseColorOrder

%% others
grpnm = [parent '/mtex/miscellaneous'];
attr.add('NX_class', 'NXcollection');
ret = h5w.nexus_write_group(grpnm, attr);
attr = io_attributes();
dsnm = [grpnm '/mosek'];
if mtex_pref.mosek
    ret = h5w.nexus_write(dsnm, uint8(1), attr);
else
    ret = h5w.nexus_write(dsnm, uint8(0), attr);
end
dsnm = [grpnm '/generating_help_mode'];
ret = h5w.nexus_write(dsnm, mtex_pref.generatingHelpMode, attr);
dsnm = [grpnm '/methods_advise'];
if mtex_pref.mtexMethodsAdvise
    ret = h5w.nexus_write(dsnm, uint8(1), attr);
else
    ret = h5w.nexus_write(dsnm, uint8(0), attr);
end
dsnm = [grpnm '/stop_on_symmetry_mismatch'];
if mtex_pref.stopOnSymmetryMissmatch
    ret = h5w.nexus_write(dsnm, uint8(1), attr);
else
    ret = h5w.nexus_write(dsnm, uint8(0), attr);
end
dsnm = [grpnm '/inside_poly'];
if mtex_pref.insidepoly
    ret = h5w.nexus_write(dsnm, uint8(1), attr);
else
    ret = h5w.nexus_write(dsnm, uint8(0), attr);
end
dsnm = [grpnm '/text_interpreter'];
ret = h5w.nexus_write(dsnm, mtex_pref.textInterpreter, attr);
dsnm = [grpnm '/voronoi_method'];
ret = h5w.nexus_write(dsnm, mtex_pref.voronoiMethod, attr);

%% numerics
grpnm = [parent '/mtex/numerics'];
attr.add('NX_class', 'NXcollection');
ret = h5w.nexus_write_group(grpnm, attr);
attr = io_attributes();
dsnm = [grpnm '/eps'];
ret = h5w.nexus_write(dsnm, double(eps), attr);
dsnm = [grpnm '/fft_accuracy'];
ret = h5w.nexus_write(dsnm, double(mtex_pref.FFTAccuracy), attr);
dsnm = [grpnm '/max_sone_bandwidth'];
ret = h5w.nexus_write(dsnm, double(mtex_pref.maxS1Bandwidth), attr);
dsnm = [grpnm '/max_stwo_bandwidth'];
ret = h5w.nexus_write(dsnm, double(mtex_pref.maxS2Bandwidth), attr);
dsnm = [grpnm '/max_sothree_bandwidth'];
ret = h5w.nexus_write(dsnm, double(mtex_pref.maxSO3Bandwidth), attr);

%% system
grpnm = [parent '/mtex/system'];
attr.add('NX_class', 'NXcollection');
ret = h5w.nexus_write_group(grpnm, attr);
attr = io_attributes();
dsnm = [grpnm '/memory'];
attr.add('unit', 'MiB');
ret = h5w.nexus_write(dsnm, double(mtex_pref.memory), attr);
% attr = io_attributes();
% dsnm = [grpnm '/open_gl_bug'];
% if mtex_pref.openglBug
%     ret = h5w.nexus_write(dsnm, uint8(1), attr);
% else
%     ret = h5w.nexus_write(dsnm, uint8(0), attr);
% end
attr = io_attributes();
dsnm = [grpnm '/save_to_file'];
if mtex_pref.SaveToFile
    ret = h5w.nexus_write(dsnm, uint8(1), attr);
else
    ret = h5w.nexus_write(dsnm, uint8(0), attr);
end

%% paths
% switch off these annotations as I do not want share my local system configuration
if 1 == 0
    grpnm = [parent '/mtex/path'];
    attr.add('NX_class', 'NXcollection');
    ret = h5w.nexus_write_group(grpnm, attr);
    attr = io_attributes();

    dsnm = [grpnm '/mtex'];
    ret = h5w.nexus_write(dsnm, mtex_pref.mtexPath, attr);
    dsnm = [grpnm '/data'];
    ret = h5w.nexus_write(dsnm, mtex_pref.DataPath, attr);
    dsnm = [grpnm '/cif'];
    ret = h5w.nexus_write(dsnm, mtex_pref.CIFPath, attr);
    dsnm = [grpnm '/ebsd'];
    ret = h5w.nexus_write(dsnm, mtex_pref.EBSDPath, attr);
    dsnm = [grpnm '/pf'];
    ret = h5w.nexus_write(dsnm, mtex_pref.PoleFigurePath, attr);
    dsnm = [grpnm '/odf'];
    ret = h5w.nexus_write(dsnm, mtex_pref.ODFPath, attr);
    dsnm = [grpnm '/tensor'];
    ret = h5w.nexus_write(dsnm, mtex_pref.TensorPath, attr);
    dsnm = [grpnm '/example'];
    ret = h5w.nexus_write(dsnm, mtex_pref.ExamplePath, attr);
    dsnm = [grpnm '/import_wizard'];
    ret = h5w.nexus_write(dsnm, mtex_pref.ImportWizardPath, attr);
    dsnm = [grpnm '/pf_extensions'];
    ret = h5w.nexus_write(dsnm, strjoin(mtex_pref.poleFigureExtensions, ';'), attr);
    dsnm = [grpnm '/ebsd_extensions'];
    ret = h5w.nexus_write(dsnm, strjoin(mtex_pref.EBSDExtensions, ';'), attr);
end

disp('NeXus/HDF5 exporting of MTex configuration: OK');
status = logical(1);
end