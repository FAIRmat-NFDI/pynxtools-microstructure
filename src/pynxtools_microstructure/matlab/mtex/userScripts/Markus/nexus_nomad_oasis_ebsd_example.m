%% header
% Markus Kühbach, Humboldt-Universität zu Berlin, Department of Physics,
% NOMAD Oasis, FAIRmat

%% context
% an example that shows how to process MTex class instances such to
% export and map data and metadata conceptually on NeXus class instances
% to work towards standardization in the field of texture analysis,

%% versioning
% make sure that before using the code for production runs to run
% git describe --dirty --tags --long --abbrev=8 --match '*[0-9]*' >mtex-version.txt
% in the mtex home directory to document which version and commit this to
% to know with which specific code the production run was performed

%% init
clear; clc;

%% for Linux might need to use qhull
% setMTEXpref('voronoiMethod','qhull');
% see https://github.com/mtex-toolbox/mtex/discussions/2083 for details

%% load preprocessed color maps for all point groups
% when using pynxtools-microstructure plugin the home directory
% is SOMEPREFIX/pynxtools_microstructure
prefix = fullfile(pwd, 'src', 'pynxtools_microstructure', 'matlab', 'mtex', 'userScripts', 'Markus');
addpath(prefix);
addpath(fullfile(pwd, 'src', 'pynxtools_microstructure', 'matlab', 'mtex', 'extern', 'hdfutils'));

compute_all_legends = 0;
if compute_all_legends
    nexus_preprocess_legends_for_all_combinations(prefix);
else
    load(fullfile(prefix, 'ipf_lgds.mat'));
end

%% define custom mappings for point group whose name differs between TSL/MTex
flip_y = 0;
ipf_lgd_tsl_pg_map = containers.Map();
ipf_lgd_mtx_pg_map = containers.Map();
% https://orix.readthedocs.io/en/latest/tutorials/inverse_pole_figures.html
% customization for specific low-symmetry point groups for which TSL
% has no as ipf legends that are as detailed and perfectly colored
% as those provided by MTex
ipf_lgd_tsl_pg_map('121') = '2';
ipf_lgd_mtx_pg_map('121') = '2';
ipf_lgd_tsl_pg_map('1m1') = 'm';
ipf_lgd_mtx_pg_map('1m1') = 'm';
ipf_lgd_tsl_pg_map('12/m1') = '2/m';
ipf_lgd_mtx_pg_map('12/m1') = '2/m';
ipf_lgd_tsl_pg_map('321') = '32';
ipf_lgd_mtx_pg_map('321') = '32';
ipf_lgd_tsl_pg_map('3m1') = '3m';
ipf_lgd_mtx_pg_map('3m1') = '3m';
ipf_lgd_tsl_pg_map('-3m1') = '-3m';
ipf_lgd_mtx_pg_map('-3m1') = '-3m';
% flip ipf_lgd vertically to have them showing up correctly aligned
% like the IPF RGB colored OIM maps, so far this was only possible
% when setting y-flip on by default
disp('Mapping MTex point group names to closest TSL: OK');
if flip_y  % for some versions of NOMAD and H5Web the RGB widget does not
    % have the flipy button, so we need to flip eventually hard the data
    % that is a workaround
    k = ipf_lgd_tsl_dct.keys;
    v = ipf_lgd_tsl_dct.values;
    for pg = 1:1:length(point_groups)
        tmp = ipf_lgd_tsl_dct(k{pg});
        ny = size(tmp, 3);
        flp = uint8(zeros(size(tmp)));
        for y = 1:1:ny
            flp(:, :, ny - y + 1) = tmp(:, :, y);
        end
        ipf_lgd_tsl_dct(k{pg}) = flp;
    end
    clearvars k v;
    k = ipf_lgd_mtx_dct.keys;
    v = ipf_lgd_mtx_dct.values;
    for pg = 1:1:length(point_groups)
        tmp = ipf_lgd_mtx_dct(k{pg});
        ny = size(tmp, 3);
        flp = uint8(zeros(size(tmp)));
        for y = 1:1:ny
            flp(:, :, ny - y + 1) = tmp(:, :, y);
        end
        ipf_lgd_mtx_dct(k{pg}) = flp;
    end
    clearvars k v pg tmp ny flp y;
    disp('Precomputed IPF legends for all point groups flipped along y: OK');
else
    disp('Use precomputed IPF legends for all point groups unflipped: OK');
end

perform_io = 1;
ebsd_io = 1;
microstructure_io = 1;
odf_io = 1;
pf_io = 0;  % this next function has not been tested enough
project_directory = pwd;
target_directory = fullfile(pwd, 'examples');
mtexdir = fullfile(pwd);
configdir = fullfile(project_directory);
inputdir = fullfile(pwd, 'src', 'pynxtools_microstructure', 'mtex', 'data', 'EBSD');  % 2d
% inputdir = fullfile(pwd, 'src', 'pynxtools_microstructure', 'mtex', 'data', 'EBSD3');  % 3d
outputdir = target_directory;
addpath(mtexdir);
addpath(configdir);
addpath(inputdir);
addpath(outputdir);
mtex_pref = configure_mtex_preferences();
mtex_plot_default = plottingConvention();

% run the example
mime_type = 'ang';
ifpath_main = fullfile(outputdir, '063.0e9b32c0f2082b86ca5cc30fa683107e1d824dd6ecc7cb25e40210640b40b898.ang');
ofpath = fullfile([ifpath_main '.mtex.h5']);
%mime_type = 'ctf';
%ifpath_main = fullfile(outputdir, '162.f75d30a7c21369a2b4ef68264ca0656463d4c0094474a0687122efda3254b394.ctf');
%ofpath = fullfile([ifpath_main '.mtex.h5']);

%mime_type = 'ctf';
%ifpath_main = fullfile(inputdir, 'Forsterite.ctf');
%token = replace(ifpath_main, inputdir, ''); 
%ofpath = fullfile(outputdir, [token '.mtex.h5']);
%clearvars token;

ifpath_supp = '';
disp(['ifpath_main: ' ifpath_main]);
disp(['ifpath_supp: ' ifpath_supp]);
disp(['ofpath: ' ofpath]);

% parent = '/entry1/roi1/ebsd/indexing';

% check ctf header line of 'Channel Text File' to spot problems
if strcmp(mime_type, 'ctf')
    header = textread(ifpath_main,'%s', 1, ...
        'delimiter', newline, 'whitespace','');
    if ~startsWith("Channel Text File", header{1})
        % nothing
    end
end

%%

gtic = tic;
load_tic = tic;
status = nexus_write_init(ofpath, perform_io);
status = nexus_write_mtex_preferences( ...
        ofpath, ...
        '/entry1/roi1/ebsd/indexing', ...
        perform_io, ...
        mtexdir);
return

reference_frame_convention = 's2e';
disp(['reference_frame_convention: ' reference_frame_convention]);
if strcmp(reference_frame_convention, 's2e')
    % assuming just setting 2 is a very strong if not a wrong assumption
    if strcmp(mime_type, 'crc')
        ebsd_raw = loadEBSD_crc(ifpath_supp, ifpath_main, ...
            'convertSpatial2EulerReferenceFrame', 'setting 2');
    else
        ebsd_raw = EBSD.load(ifpath_main, ...
            'convertSpatial2EulerReferenceFrame', 'setting 2');
    end
elseif strcmp(reference_frame_convention, 'e2s')
    if strcmp(mime_type, 'crc')
        ebsd_raw = loadEBSD_crc(ifpath_supp, ifpath_main, ...
            'convertEuler2SpatialReferenceFrame', 'setting 2');
    else
        ebsd_raw = EBSD.load(input, ...
            'convertEuler2SpatialReferenceFrame');
    end
else
    ebsd_raw = EBSD.load(input);
end

h5w = HdfFiveSeqHdl(ofpath);
dsnm = ['/entry1/profiling/load_elapsed_time'];
load_wall_clock = toc(load_tic);
attr = io_attributes();
attr.add('units', 's');
h5w.nexus_write(dsnm, double(load_wall_clock), attr);

% ebsd_raw 2D EBSD scan point set, arbitrary ROI shapes
% plot(ebsd_raw);
ebsd_tic = tic;

if ebsd_io    
    status = nexus_write_ebsd_phase( ...
        ebsd_raw, ...
        ofpath, ...
        '/entry1/roi1/ebsd/indexing', ...
        perform_io);
    
    status = nexus_write_ebsd_data( ...
        ebsd_raw, ...
        ofpath, ...
        '/entry1/roi1/ebsd/indexing', ...
        perform_io);
    
    % prepare a default plot on a square grid but represented
    % as an implicit array instead of an EBSDsquare object
    ebsd_sqr_roi_hweb = nexus_squarify_ebsd( ...
        ebsd_raw, ...
        'h5web_max_size', 2^14 - 1);
    
    status = nexus_write_ebsd_overview( ...
        ebsd_sqr_roi_hweb, ...
        ofpath, ...
        '/entry1/roi1/ebsd/indexing', ...
        perform_io);
    
    ebsd_sqr_ipf_hweb = nexus_squarify_ebsd( ...
        ebsd_raw, ...
        'h5web_max_size', 2^11 - 1);
    
    status = nexus_write_ebsd_phase_ipf( ...
        ebsd_raw, ...
        ebsd_sqr_ipf_hweb, ...
        ofpath, ...
        '/entry1/roi1/ebsd/indexing', ...
        perform_io, ...
        ipf_lgd_tsl_dct, ...
        ipf_lgd_mtx_dct, ...
        ipf_lgd_tsl_pg_map, ...
        ipf_lgd_mtx_pg_map);
    
    h5w = HdfFiveSeqHdl(ofpath);
    dsnm = '/entry1/profiling/ebsd_elapsed_time';
    ebsd_wall_clock = toc(ebsd_tic);
    attr = io_attributes();
    attr.add('units', 's');
    h5w.nexus_write(dsnm, double(ebsd_wall_clock), attr);
end

if microstructure_io
    status = nexus_write_ebsd_microstructure( ...
        ebsd_raw, ...
        ofpath, ...
        '/entry1/roi1/ebsd/indexing', ...
        perform_io);
end

if odf_io
    status = nexus_write_ebsd_odf( ...
        ebsd_raw, ...
        ofpath, ...
        '/entry1/roi1/ebsd/indexing', ...
        perform_io);
end

if pf_io
    % this next function has not been tested enough
    status = nexus_write_ebsd_pf( ...
        ebsd_raw, ...
        ofpath, ...
        '/entry1/roi1/ebsd/indexing', ...
        perform_io);
end

h5w = HdfFiveSeqHdl(ofpath);
host_info = nexus_nomad_get_host_info();
attr = io_attributes();
h5w.nexus_write('/entry1/profiling/model', host_info.model, attr);
h5w.nexus_write('/entry1/profiling/operating_system', host_info.ostype, attr);
h5w.nexus_write('/entry1/profiling/architecture', host_info.architecture, attr);
h5w.nexus_write('/entry1/profiling/max_processes', uint32(1), attr);  % MTex is a single process app
h5w.nexus_write('/entry1/profiling/max_threads', uint32(host_info.max_threads), attr);
h5w.nexus_write('/entry1/profiling/max_gpus', uint32(0), attr);  % no GPUs yet by MTex

wall_clock = toc(gtic);
attr = io_attributes();
attr.add('units', 's');
h5w.nexus_write('/entry1/profiling/total_elapsed_time', double(wall_clock), attr);
disp('Processing completed');
