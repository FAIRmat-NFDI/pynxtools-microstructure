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
load('userScripts/FairmatNfdi/ipf_lgds.mat');

%% define custom mappings for point group whose name differs between TSL/MTex
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
disp(['Mapping MTex point group names to closest TSL: OK']);
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
disp(['Precomputed IPF legends for all point groups flipped along y: OK']);

project_directory = 'CHANGEME';
target_directory = 'CHANGEME';
mtexdir = [pwd];
configdir = [project_directory];
inputdir = [target_directory '/unpacked'];
outputdir = [target_directory '/mtex'];
addpath('data/EBSD');
addpath(mtexdir);
addpath(configdir);
addpath(inputdir);
addpath(outputdir);
mtex_pref = configure_mtex_preferences();
mtex_plot_default = plottingConvention();

%% load configuration from dataset extraction Python script
perform_io = 1;
case_id = '10';
ebsd_mime_types_to_use_mtex = {'ang', 'osc', 'ctf', 'crc'};
% ang only the first four

% ang, 93 Error in hdf5lib 
% ang, 105, 106 Error in SO3FunHarmonic/volume
% osc, 51, 53, 89, 104:131 (project 063), 161:166, 168, 170:185 Index exceeds array bounds. Error in EBSD/calcGrains, empty maps
% osc, 52 broken osc file
% osc, 85, 86 all chunk dimensions must be positive
% osc, 209 Dimensions of arrays being concatenated are not consistent.
% ctf, 17:20, The logical indices contain a true value outside of the array
% bounds.:2172
% ctf, 30:32, 337:338, 1241, 1244, 1245, 1329:1331, 2021, 2114:2123, 2159:2160, 2167, 2170:2172 Operands to the logical AND (&&) and OR (||) operators must be convertible to logical scalar values. Use the ANY or ALL
% ctf, 352:354 could not detect file format
% ctf, 400 Error using dataread Buffer overflow (bufsize = 4095) while reading string from file (row 1, field 1).
% ctf, 696, 856 all chunk dimensions must be positive
% ctf, 2161 Index in position 1 exceeds array bounds. Index must not exceed <int>. Error in nexus_write_ebsd_phase_ipf (line 94)
% ctf, 953, 2029, 2109, Index in position 1 exceeds array bounds. Index must not exceed Error in nexus_write_ebsd_microstructure (line 360)
% ctf, 954, 957 segfault jcvoronoi when starting up
% ctf, 1438:1443 (project 198), 1915:1922 (project 233), 2114 EBSD format 'CTF' does not match the data
% TODO jumping over 33:144 for these it seems odf (nc) needs to be switched off
% TODO jumping over 339:350 for these it seems odf (nc) needs to be switched off
% TODO jumping over 954:956 forgotten, started with wrong indexing
% TODO jumping over 955:963 for these it seems odf (nc) needs to be switched off
% TODO ctf projects 217, 284 4D datasets
% TODO ctf 400:900 (project 067) is a serial section that should be fused to a 3D dataset
% TODO ctf many from (project 091) is a serial section that should be fused to a 3D dataset
% TODO crc project 203 is a serial section
% TODO crc project 204 is an additive manufacturing different places
% thus sampling three use cases, time-dependent, spatially correlated FIB, spatially correlated non FIB
% TODO crc project 002 12:40
% TODO 51 euler angles too large 

% crc 4,6:8, 54, 224 Operands to the logical AND (&&) and OR (||) operators must be convertible to logical scalar values. Use the ANY or ALL
% crc 55,57, 58, Error in H5P.set_chunk (line 36), Error in H5P.set_chunk (line 36)
% crc, 133:134, 136:138, 159, 225:227:242, 312, 357 Unrecognized function or variable 'Title'. Error in loadEBSD_crc>localCPRParser (line 123)
% TODO: crc 232:242 (project 052) 293:307
% crc, 314 Index in position 1 exceeds array bounds. Index must not exceed 1.
% crc, 336 too small EBSD map Unrecognized function or variable 'p'. Error in nexus_write_ebsd_microstructure (line 376)
% crc, 340, Error using reshape Product of known dimensions, 25715, not
% divisible into total number of elements, 7293510. Error in loadEBSD_crc>localCRCLoader (line 78)
% crc, 923, Error using assert For monoclinic lattices the angles with the
% symmetry axis have to be 90 degree Error in calcAxis (line 40)
% crc, 949 CC BY 4.0 NC SA, https://opendata.ukaea.uk/doi/?id=by8y-tj18&br=2023

row_idx_s = 951;
for mime_type_idx = 4:1:4  %length(ebsd_mime_types_to_use_mtex)
    mime_type = ebsd_mime_types_to_use_mtex{mime_type_idx};
    disp(mime_type);
    cfg_tbl = configure_examples( ...
        [project_directory '/harvest.examples.' ...
         case_id '.em.' mime_type '.unpack.csv'], ...
        [2, Inf]);

    for row_idx = row_idx_s:1:size(cfg_tbl, 1)
        clearvars -except configdir inputdir ipf_lgd_mtx_dct ipf_lgd_mtx_pg_map ...
            ipf_lgd_tsl_dct ipf_lgd_tsl_pg_map mtex_plot_default mtex_pref ...
            mtexdir outputdir point_groups project_directory target_directory ...
            perform_io case_id ebsd_mime_types_to_use_mtex mime_type_idx ...
            mime_type cfg_tbl row_idx_s row_idx;
    % try
        use = cfg_tbl{row_idx, 1};
        if use ~= 1
            continue;
        end
        % if ~ismember(skip_these_map_ids, row_idx)
        %     continue;
        % end
        ifpath_main = cfg_tbl{row_idx, 4}{1};
        ifpath_supp = cfg_tbl{row_idx, 6}{1};
        if strcmp(ifpath_main, '')
            continue;
        end
        if strcmp(mime_type, 'crc')
            if strcmp(ifpath_supp, '')
                continue;
            end
        end
        token = replace( ...
            ifpath_main, ...
            '/media/kaiobach/production/scidat_nomad_em/unpacked/mtex/', ...
            ''); 
        ofpath = [outputdir '/' token '.mtex.h5'];
        clearvars token;
        disp(['row_idx: ' int2str(row_idx)]);
        disp(['ifpath_main: ' ifpath_main]);
        disp(['ifpath_supp: ' ifpath_supp]);
        disp(['ofpath: ' ofpath]);
        
        % for debugging with a simple multi-phase EBSD
        % mime_type = 'ctf';
        % ifpath_main = 'data/EBSD/Forsterite.ctf';
        % ofpath = 'userScripts/FairmatNfdi/test.nxs';
        % parent = '/entry1/roi1/ebsd/indexing';
     
        % check ctf header line of 'Channel Text File' to spot problems
        if strcmp(mime_type, 'ctf')
            header = textread(ifpath_main,'%s', 1, ...
                'delimiter', newline, 'whitespace','');
            if ~startsWith("Channel Text File", header{1})
                continue;
            end
        
            % if row_idx >= 352 && row_idx <= 400
            if (row_idx >= 1458 && row_idx <= 1716) ...
                    || (row_idx >= 1749 && row_idx <= 1909) ...
               || (row_idx >= 2030 && row_idx <= 2108)
                % 217 and 284 in-situ studies respectively
                % if mod(row_idx, 2) == 0
                continue;
                % end
            end
        end
        if strcmp(mime_type, 'crc')
            if (row_idx >= 419 && row_idx <= 645) ...
               || (row_idx >= 666 && row_idx <= 922)
                continue;
            end
        end

        gtic = tic;
        load_tic = tic;
        status = nexus_write_init(ofpath, perform_io);
        status = nexus_write_mtex_preferences( ...
                ofpath, ...
                '/entry1/roi1/ebsd/indexing', ...
                perform_io);

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
        dsnm = ['/entry1/profiling/ebsd_elapsed_time'];
        ebsd_wall_clock = toc(ebsd_tic);
        attr = io_attributes();
        attr.add('units', 's');
        h5w.nexus_write(dsnm, double(ebsd_wall_clock), attr);

        status = nexus_write_ebsd_microstructure( ...
            ebsd_raw, ...
            ofpath, ...
            '/entry1/roi1/ebsd/indexing', ...
            perform_io);
        
        status = nexus_write_ebsd_odf( ...
            ebsd_raw, ...
            ofpath, ...
            '/entry1/roi1/ebsd/indexing', ...
            perform_io);

        % this next function has not been tested enough
        % we do not need it also because ODF gets reported 
        % status = nexus_write_ebsd_pf( ...
        %       ebsd_raw, ...
        %       ofpath, ...
        %       '/entry1/roi1/ebsd/indexing', ...
        %       perform_io);
        % end

        h5w = HdfFiveSeqHdl(ofpath);
        dsnm = ['/entry1/profiling/total_elapsed_time'];
        wall_clock = toc(gtic);
        attr = io_attributes();
        attr.add('units', 's');
        h5w.nexus_write(dsnm, double(wall_clock), attr);
    end
    % catch
    % end
end

% for obsolete code functionalities inspect earlier commits