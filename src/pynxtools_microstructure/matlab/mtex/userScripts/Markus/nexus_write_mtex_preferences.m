function status = nexus_write_mtex_preferences(fpath, parent, perform_io, mtexdir)
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
h5w.nexus_write_group(grpnm, attr);

% resetting attr and use it until again an HDF5 node with
% attributes is required
%% versions
grpnm = [parent '/mtex/program1']; % matlab
attr = io_attributes();
attr.add('NX_class', 'NXprogram');
h5w.nexus_write_group(grpnm, attr);

dsnm = [grpnm '/program'];
attr = io_attributes();
attr.add('version', version);
h5w.nexus_write(dsnm, 'Matlab', attr);

grpnm = [parent '/mtex/program2']; % mtex
attr = io_attributes();
attr.add('NX_class', 'NXprogram');
h5w.nexus_write_group(grpnm, attr);

dsnm = [grpnm '/program'];
attr = io_attributes();
% generated via ./scripts/mtex.sh
mtex_version = strtrim(fileread(fullfile(mtexdir, 'src', 'pynxtools_microstructure', 'mtex-version.txt')));
attr.add('version', mtex_version);
h5w.nexus_write(dsnm, 'MTex', attr);

grpnm = [parent '/mtex/program3']; % Matlab-internal HDF5
attr = io_attributes();
attr.add('NX_class', 'NXprogram');
h5w.nexus_write_group(grpnm, attr);

dsnm = [grpnm '/program'];
attr = io_attributes();
[major, minor, revision] = H5.get_libversion();
hfive_version = [num2str(major) '.' num2str(minor) '.' num2str(revision)];
clearvars major minor revision;
attr.add('version', hfive_version);
h5w.nexus_write(dsnm, 'HDF5', attr);


%% conventions
grpnm = [parent '/mtex/conventions'];
attr = io_attributes();
attr.add('NX_class', 'NXcollection');
h5w.nexus_write_group(grpnm, attr);

% attr = io_attributes();
% dsnm = [grpnm '/x_axis_direction'];
% h5w.nexus_write(dsnm, mtex_pref.xAxisDirection, attr);
% dsnm = [grpnm '/z_axis_direction'];
% h5w.nexus_write(dsnm, mtex_pref.zAxisDirection, attr);
% dsnm = [grpnm '/a_axis_direction'];
% if ~strcmp(mtex_pref.aAxisDirection, '')
%     h5w.nexus_write(dsnm, mtex_pref.aAxisDirection, attr);
% else
%     h5w.nexus_write(dsnm, 'n/a', attr);
% end
% dsnm = [grpnm '/b_axis_direction'];
% h5w.nexus_write(dsnm, mtex_pref.bAxisDirection, attr);
dsnm = [grpnm '/euler_angle'];
if strcmp(mtex_pref.EulerAngleConvention, 'Bunge')
    h5w.nexus_write(dsnm, 'bunge', attr);
else
    h5w.nexus_write(dsnm, 'undefined', attr);
end

%% plotting
grpnm = [parent '/mtex/plotting'];
attr = io_attributes();
attr.add('NX_class', 'NXcollection');
h5w.nexus_write_group(grpnm, attr);
attr = io_attributes();
dsnm = [grpnm '/font_size'];
h5w.nexus_write(dsnm, double(mtex_pref.FontSize), attr);
dsnm = [grpnm '/inner_plot_spacing'];
h5w.nexus_write(dsnm, double(mtex_pref.innerPlotSpacing), attr);
dsnm = [grpnm '/outer_plot_spacing'];
h5w.nexus_write(dsnm, double(mtex_pref.outerPlotSpacing), attr);
dsnm = [grpnm '/marker_size'];
h5w.nexus_write(dsnm, double(mtex_pref.markerSize), attr);
dsnm = [grpnm '/figure_size'];
h5w.nexus_write(dsnm, mtex_pref.figSize, attr);
dsnm = [grpnm '/show_micron_bar'];
if strcmp(mtex_pref.showMicronBar, 'on')
    h5w.nexus_write(dsnm, uint8(1), attr);
else
    h5w.nexus_write(dsnm, uint8(0), attr);
end
dsnm = [grpnm '/show_coordinates'];
if strcmp(mtex_pref.showCoordinates, 'on')
    h5w.nexus_write(dsnm, uint8(1), attr);
else
    h5w.nexus_write(dsnm, uint8(0), attr);
end
dsnm = [grpnm '/pf_anno_fun_hdl'];
h5w.nexus_write(dsnm, func2str(mtex_pref.pfAnnotations), attr);
dsnm = [grpnm '/color_map'];
h5w.nexus_write(dsnm, double(mtex_pref.colors), attr);
dsnm = [grpnm '/default_map'];
h5w.nexus_write(dsnm, double(mtex_pref.defaultColorMap), attr);
dsnm = [grpnm '/color_palette'];
h5w.nexus_write(dsnm, mtex_pref.colorPalette, attr);
dsnm = [grpnm '/degree_character'];
% TODO add PhaseColorOrder
h5w.nexus_write(dsnm, mtex_pref.degreeChar, attr);
dsnm = [grpnm '/arrow_character'];
h5w.nexus_write(dsnm, mtex_pref.arrowChar, attr);
dsnm = [grpnm '/marker'];
h5w.nexus_write(dsnm, mtex_pref.annotationStyle{2}, attr);
dsnm = [grpnm '/marker_edge_color'];
h5w.nexus_write(dsnm, mtex_pref.annotationStyle{4}, attr);
dsnm = [grpnm '/marker_face_color'];
h5w.nexus_write(dsnm, mtex_pref.annotationStyle{6}, attr);
dsnm = [grpnm '/hit_test'];
if strcmp(mtex_pref.annotationStyle{8}, 'off')
    h5w.nexus_write(dsnm, uint8(0), attr);
else
    h5w.nexus_write(dsnm, uint8(1), attr);
end
% phaseColorOrder

%% others
grpnm = [parent '/mtex/miscellaneous'];
attr.add('NX_class', 'NXcollection');
h5w.nexus_write_group(grpnm, attr);
attr = io_attributes();
dsnm = [grpnm '/mosek'];
h5w.nexus_write(dsnm, logical(mtex_pref.mosek), attr);
dsnm = [grpnm '/generating_help_mode'];
h5w.nexus_write(dsnm, logical(mtex_pref.generatingHelpMode), attr);
dsnm = [grpnm '/methods_advise'];
h5w.nexus_write(dsnm, logical(mtex_pref.mtexMethodsAdvise), attr);
dsnm = [grpnm '/stop_on_symmetry_mismatch'];
h5w.nexus_write(dsnm, logical(mtex_pref.stopOnSymmetryMissmatch), attr);
dsnm = [grpnm '/inside_poly'];
h5w.nexus_write(dsnm, logical(mtex_pref.insidepoly), attr);
dsnm = [grpnm '/text_interpreter'];
h5w.nexus_write(dsnm, mtex_pref.textInterpreter, attr);
dsnm = [grpnm '/voronoi_method'];
h5w.nexus_write(dsnm, mtex_pref.voronoiMethod, attr);

%% numerics
grpnm = [parent '/mtex/numerics'];
attr.add('NX_class', 'NXcollection');
h5w.nexus_write_group(grpnm, attr);
attr = io_attributes();
dsnm = [grpnm '/eps'];
h5w.nexus_write(dsnm, double(eps), attr);
dsnm = [grpnm '/fft_accuracy'];
h5w.nexus_write(dsnm, double(mtex_pref.FFTAccuracy), attr);
dsnm = [grpnm '/max_sone_bandwidth'];
h5w.nexus_write(dsnm, double(mtex_pref.maxS1Bandwidth), attr);
dsnm = [grpnm '/max_stwo_bandwidth'];
h5w.nexus_write(dsnm, double(mtex_pref.maxS2Bandwidth), attr);
dsnm = [grpnm '/max_sothree_bandwidth'];
h5w.nexus_write(dsnm, double(mtex_pref.maxSO3Bandwidth), attr);

%% system
grpnm = [parent '/mtex/system'];
attr.add('NX_class', 'NXcollection');
h5w.nexus_write_group(grpnm, attr);
attr = io_attributes();
dsnm = [grpnm '/memory'];
attr.add('units', 'MiB');
h5w.nexus_write(dsnm, double(mtex_pref.memory), attr);
% attr = io_attributes();
% dsnm = [grpnm '/open_gl_bug'];
% if mtex_pref.openglBug
%     h5w.nexus_write(dsnm, uint8(1), attr);
% else
%     h5w.nexus_write(dsnm, uint8(0), attr);
% end
attr = io_attributes();
dsnm = [grpnm '/save_to_file'];
h5w.nexus_write(dsnm, logical(mtex_pref.SaveToFile), attr);

%% paths
% switch off these annotations as I do not want share my local system configuration
if 1 == 0
    grpnm = [parent '/mtex/path'];
    attr.add('NX_class', 'NXcollection');
    h5w.nexus_write_group(grpnm, attr);
    attr = io_attributes();

    dsnm = [grpnm '/mtex'];
    h5w.nexus_write(dsnm, mtex_pref.mtexPath, attr);
    dsnm = [grpnm '/data'];
    h5w.nexus_write(dsnm, mtex_pref.DataPath, attr);
    dsnm = [grpnm '/cif'];
    h5w.nexus_write(dsnm, mtex_pref.CIFPath, attr);
    dsnm = [grpnm '/ebsd'];
    h5w.nexus_write(dsnm, mtex_pref.EBSDPath, attr);
    dsnm = [grpnm '/pf'];
    h5w.nexus_write(dsnm, mtex_pref.PoleFigurePath, attr);
    dsnm = [grpnm '/odf'];
    h5w.nexus_write(dsnm, mtex_pref.ODFPath, attr);
    dsnm = [grpnm '/tensor'];
    h5w.nexus_write(dsnm, mtex_pref.TensorPath, attr);
    dsnm = [grpnm '/example'];
    h5w.nexus_write(dsnm, mtex_pref.ExamplePath, attr);
    dsnm = [grpnm '/import_wizard'];
    h5w.nexus_write(dsnm, mtex_pref.ImportWizardPath, attr);
    dsnm = [grpnm '/pf_extensions'];
    h5w.nexus_write(dsnm, strjoin(mtex_pref.poleFigureExtensions, ';'), attr);
    dsnm = [grpnm '/ebsd_extensions'];
    h5w.nexus_write(dsnm, strjoin(mtex_pref.EBSDExtensions, ';'), attr);
end

disp('NeXus/HDF5 exporting of MTex configuration: OK');
status = true;
end