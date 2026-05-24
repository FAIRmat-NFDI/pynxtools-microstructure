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
    for pg = 1:1:length(point_groups)
        tmp = ipf_lgd_tsl_dct(k{pg});
        ny = size(tmp, 3);
        flp = uint8(zeros(size(tmp)));
        for y = 1:1:ny
            flp(:, :, ny - y + 1) = tmp(:, :, y);
        end
        ipf_lgd_tsl_dct(k{pg}) = flp;
    end
    clearvars k;
    k = ipf_lgd_mtx_dct.keys;
    for pg = 1:1:length(point_groups)
        tmp = ipf_lgd_mtx_dct(k{pg});
        ny = size(tmp, 3);
        flp = uint8(zeros(size(tmp)));
        for y = 1:1:ny
            flp(:, :, ny - y + 1) = tmp(:, :, y);
        end
        ipf_lgd_mtx_dct(k{pg}) = flp;
    end
    clearvars k pg tmp ny flp y;
    disp('Precomputed IPF legends for all point groups flipped along y: OK');
else
    disp('Use precomputed IPF legends for all point groups unflipped: OK');
end

perform_io = 1;
ebsd_io = 1;
microstructure_io = 1;
odf_io = 1;
pf_io = 0;  % not been tested properly enough
project_directory = fullfile(pwd);
source_directory = fgetl(fopen(fullfile(project_directory, 'examples', 'oasisb', 'source_directory.txt'),'r')); fclose('all');
target_directory = fgetl(fopen(fullfile(project_directory, 'examples', 'oasisb', 'target_directory.txt'),'r')); fclose('all');
mtexdir = fullfile(pwd);
configdir = fullfile(project_directory);
% inputdir = fullfile(pwd, 'src', 'pynxtools_microstructure', 'mtex', 'data', 'EBSD');  % 2d
% inputdir = fullfile(pwd, 'src', 'pynxtools_microstructure', 'mtex', 'data', 'EBSD3');  % 3d
outputdir = target_directory;
addpath('data/EBSD');
addpath(mtexdir);
addpath(configdir);
addpath(outputdir);
mtex_pref = configure_mtex_preferences();
mtex_plot_default = plottingConvention();
ebsd_mime_types_to_use_mtex = {'.crc', '.ang', '.ctf', '.osc'};

%% loop over projects
for project = 837:836
    % ignore for now projects with data that are clear slice sets
    % either in time or 3D-EBSD, that have so far just blown up
    % the number of datasets but thereby also biased the collection
    % towards particular studies
    if ismember( ...
            project, ...
            [67, 91, 194, 203, 204, 217, 268, 284, 651, 656, 663, 779])
        continue;
    end

    project_id = sprintf('%03d', project);
    pattern = fullfile(source_directory, [project_id, '.*']);
    files = dir(pattern);
    logpath = fullfile(target_directory, [project_id '.log']);
    if exist("logpath", 'file')
        delete(logpath);
    end
    diary(logpath)
    diary on

    for f = 1:length(files)
        [~, file_name, mime_type] = fileparts(files(f).name);
        if ismember(lower(mime_type), ebsd_mime_types_to_use_mtex)
            file_path = fullfile(files(f).folder, files(f).name);

            clearvars -except ...
                compute_all_legends ...
                configdir ...
                ebsd_io ...
                ebsd_mime_types_to_use_mtex ...
                f ...
                file_name ...
                file_path ...
                files ...
                flip_y ...
                ipf_lgd_mtx_dct ...
                ipf_lgd_tsl_dct ...
                ipf_lgd_mtx_pg_map ...
                ipf_lgd_tsl_pg_map ...
                microstructure_io ...
                mime_type ...
                mtex_plot_default ...
                mtex_pref ...
                mtexdir ...
                odf_io ...
                outputdir ...
                pattern ...
                perform_io ...
                pf_io ...
                prefix ...
                project ...
                project_directory ...
                project_id ...
                source_directory ...
                target_directory ...
                logpath;
            % cnt;

            % TODO configuration table
            % if ~strcmp(files(f).name, '186.f367a28f8b3ad6df24067e22c884dd31f7ff62cb895379a1f18ac7fb031354a3.ctf')
            %    continue
            % end

            ifpath = fullfile(source_directory, files(f).name);
            ofpath = fullfile(target_directory, [file_name, mime_type, '.mtex.h5']);
            dumppath = fullfile(target_directory, [file_name, mime_type, '.mat']);
            disp([project_id, ': ', ifpath]);
            disp([project_id, ': ', ofpath]);

            % check ctf header line of 'Channel Text File' to spot problems
            if strcmp(mime_type, 'ctf')
                headerCell = textscan(fopen(ifpath_main, 'r'), '%s', 1, 'Delimiter', '\n', 'Whitespace', ''); fclose(fid);
                if ~startsWith("Channel Text File", headerCell{1}{1})
                    continue;
                end
                clearvars headerCell;
            end

            gtic = tic;

            try
                load_tic = tic;
                % reference_frame_convention = 's2e';
                % disp(['reference_frame_convention: ' reference_frame_convention]);
                % assuming just setting 2 is a very strong if not a wrong assumption
                if strcmp(mime_type, '.crc')
                    ebsd_raw = loadEBSD_crc(ifpath, 'setting', 2);
                elseif strcmp(mime_type, '.ang')
                    ebsd_raw = loadEBSD_ang(ifpath, 'setting', 2);
                elseif strcmp(mime_type, '.osc')
                    ebsd_raw = loadEBSD_osc(ifpath);
                elseif strcmp(mime_type, '.ctf')
                    ebsd_raw = loadEBSD_ctf(ifpath);
                else
                    continue;
                end

                if ~exist('ebsd_raw', 'var')
                    % avoid writing mtex.h5 files for unimportable data
                    continue;
                end
            catch exception
                disp([project_id, ': exception ', exception.message]);
                continue;
            end

            nexus_write_init(ofpath, perform_io);
            nexus_write_mtex_preferences( ...
                ofpath, ...
                '/entry1/roi1/ebsd/indexing', ...
                perform_io, ...
                mtexdir);

            h5w = HdfFiveSeqHdl(ofpath);
            dsnm = '/entry1/profiling/load_elapsed_time';
            load_wall_clock = toc(load_tic);
            attr = io_attributes();
            attr.add('units', 's');
            h5w.nexus_write(dsnm, double(load_wall_clock), attr);

            % ebsd_raw 2D EBSD scan point set, arbitrary ROI shapes
            % plot(ebsd_raw);
            if ebsd_io
                ebsd_tic = tic;

                nexus_write_ebsd_phase( ...
                    ebsd_raw, ...
                    ofpath, ...
                    '/entry1/roi1/ebsd/indexing', ...
                    perform_io);

                nexus_write_ebsd_data( ...
                    ebsd_raw, ...
                    ofpath, ...
                    '/entry1/roi1/ebsd/indexing', ...
                    perform_io);

                % prepare a default plot on a square grid but represented
                % as an implicit array instead of an EBSDsquare object
                ebsd_sqr_hweb = nexus_squarify_ebsd( ...
                    ebsd_raw, ...
                    'h5web_max_size', 2^14 - 1);

                nexus_write_ebsd_overview( ...
                    ebsd_sqr_hweb, ...
                    ofpath, ...
                    '/entry1/roi1/ebsd/indexing', ...
                    perform_io);

                nexus_write_ebsd_phase_ipf( ...
                    ebsd_raw, ...
                    ebsd_sqr_hweb, ...
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
                nexus_write_ebsd_microstructure( ...
                    ebsd_raw, ...
                    ofpath, ...
                    '/entry1/roi1/ebsd/indexing', ...
                    perform_io);
            end

            if odf_io
                nexus_write_ebsd_odf( ...
                    ebsd_raw, ...
                    ofpath, ...
                    '/entry1/roi1/ebsd/indexing', ...
                    perform_io);
            end

            if pf_io
                % this next function has not been tested enough
                % we do not need it also because ODF gets reported
                nexus_write_ebsd_pf( ...
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
            disp([project_id, ' processed, writing Matlab restart file']);

            % save(dumppath,'-v7.3');

            % cnt = cnt + 1;
            % if cnt > 2
            %     break;
            % end
        end
    end
    diary off;
end
disp('Batch queue completed');
