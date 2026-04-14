% check also this example C:\Program Files\MATLAB\R2021b\toolbox\matlab\demos\example.h5
classdef HdfFiveSeqHdl
    properties
        dspcid
        plistid
        dsetid
        fileid
        h5resultsfn
        verbose
    end
    methods
%% constructor
        function obj = HdfFiveSeqHdl(h5fnm, varargin)
            obj.dspcid = -1;
            obj.plistid = -1;
            obj.dsetid = -1;
            obj.fileid = -1;
            obj.h5resultsfn = h5fnm;
            obj.verbose = logical(0);
            if nargin > 1
                if strcmp(varargin, 'verbose')
                    obj.verbose = logical(1);
                end
            end
            % if obj.verbose
            %     disp('Reporting pieces of information relevant for developers');
            % end
        end
%% generic file creation and access
        function r = nexus_create(obj, h5fnm)
            obj.h5resultsfn = h5fnm;
            obj.fileid = H5F.create( obj.h5resultsfn, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT' );
            if H5I.is_valid(obj.fileid)
                H5F.close(obj.fileid);
                r = 'MYHDF5_SUCCESS';
            else                
                r = 'MYHDF5_FCLOSE_FAILED';
            end
        end

        function r = nexus_open(obj, flags )
            obj.fileid = H5F.open(obj.h5resultsfn, flags, 'H5P_DEFAULT');
            if H5I.is_valid(obj.fileid)
                r = 'MYHDF5_SUCCESS';
            else
                r = 'MYHDF5_FOPEN_FAILED';
            end 
        end

        function r = nexus_close(obj)  % , previous_status )
            % low-level function to release dangling object handles correctly to not leave the handle manager polluted after an access to an object
            % current_status = previous_status;
            if H5I.is_valid(obj.dspcid)
                H5S.close(obj.dspcid);
            end
            if H5I.is_valid(obj.plistid)
                H5P.close(obj.plistid);
            end
            if H5I.is_valid(obj.dsetid)
                H5D.close(obj.dsetid);
            end
            if H5I.is_valid(obj.fileid)
                H5F.close(obj.fileid);
            end
            % ##MK::update status
            r = 'MYHDF5_SUCCESS';  %current_status;
        end
%% nexus_write_group
        function r = nexus_write_group(obj, grpnm, attrs)
            obj.fileid = H5F.open(obj.h5resultsfn, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
            if H5I.is_valid(obj.fileid)
                clean_abs_path = clean_h5_path(grpnm);
                level_by_level = split_h5_path(clean_abs_path);
                % start at root
                if obj.verbose
                    disp('Checking a chain of hopefully existing links...');
                end
                curr_loc_id = obj.fileid;
                for i = 1:length(level_by_level)
                    curr_group = level_by_level{i};
                    if obj.verbose
                        disp(['Writing attributes at level: ', curr_group]);
                        disp(['i = ', num2str(i), ', total = ', num2str(length(level_by_level))]);
                        disp(['Currently visiting __', curr_group, '__']);
                    end
                    if H5L.exists(curr_loc_id, curr_group, 'H5P_DEFAULT')
                        if obj.verbose
                            disp([curr_group, ' --> exists']);
                        end
                        next_loc_id = H5G.open(curr_loc_id, curr_group, 'H5P_DEFAULT');
                        if H5I.is_valid(next_loc_id)
                            if curr_loc_id ~= obj.fileid
                                % check if we have arrived at the leaf, write attributes then
                                if H5I.is_valid(curr_loc_id)
                                    if i == length(level_by_level)
                                        obj.nexus_write_attributes( ...
                                            next_loc_id, attrs);
                                    end
                                    H5G.close(curr_loc_id);
                                end
                            end
                            curr_loc_id = next_loc_id;
                        end
                    else
                        next_loc_id = H5G.create(curr_loc_id, curr_group, ...
                            'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT');
                        if obj.verbose
                            disp(['Currently visiting __', curr_group, '__']);
                            disp([curr_group, ' --> created']);
                        end
                        if H5I.is_valid(next_loc_id)
                            if i == length(level_by_level)
                                obj.nexus_write_attributes( ...
                                    next_loc_id, attrs);
                            end
                            if curr_loc_id ~= obj.fileid
                                if H5I.is_valid(curr_loc_id)
                                    H5G.close(curr_loc_id);
                                end
                            end
                            curr_loc_id = next_loc_id;
                        end
                    end
                end
                if H5I.is_valid(obj.fileid)
                    H5F.close(obj.fileid);
                end
            end
            r = 'MYHDF5_SUCCESS';
        end
%% generic write
        function r = nexus_write_attributes(obj, loc_id, attrs)
            % write a collection of attributes at node location call only from 
            % inside nexus_write_group or nexus_write as open instances with
            % valid locids on obj.dsetid are expected!        
            if obj.verbose
                disp('nexus_write_attributes');
            end
            % attrs.report();
            % if isa(attrs, "io_attributes")
                k = {'u08', 'i08', 'u16', 'i16', 'u32', 'i32', ...
                     'u64', 'i64', 'f32', 'f64', 'chr', 'chr_arr'};
                v = {'H5T_STD_U8LE', 'H5T_STD_I8LE', ...
                    'H5T_STD_U16LE', 'H5T_STD_I16LE', ...
                    'H5T_STD_U32LE', 'H5T_STD_I32LE', ...
                    'H5T_STD_U64LE', 'H5T_STD_I64LE', ...
                    'H5T_IEEE_F32LE', 'H5T_IEEE_F64LE', ...
                    'H5T_C_STRING', 'H5T_C_STRING'};
                mapped_h5types = containers.Map(k, v);
                % clearvars k v;                 
                if H5I.is_valid(loc_id)
                    if obj.verbose
                        disp('Attaching to loc_id');
                    end
                    props = properties(attrs);  % typed_attributes);
                    % iterate over all attribute data types, write their 
                    % individual named attributes and values
                    for i = 1:length(props)  
                        if ~strcmp(props{i}, 'unique_attribute_names') & ~strcmp(props{i}, 'verbose')
                            % disp(['Processing property ', props{i}]);

                            attr_dtypid = mapped_h5types(props{i});
                            if strcmp(props{i}, 'chr') || strcmp(props{i}, 'chr_arr')
                                attr_dtypid = H5T.copy('H5T_C_S1');
                                H5T.set_cset(attr_dtypid, 'H5T_CSET_UTF8');
                                H5T.set_size(attr_dtypid, 'H5T_VARIABLE');
                                
                                if strcmp(props{i}, 'chr')
                                    k = keys(attrs.chr);
                                    v = values(attrs.chr);
                                    % v is character array for chr ...
                                else
                                    k = keys(attrs.chr_arr);
                                    v = values(attrs.chr_arr);
                                    % ... but a cell of character arrays for chr_arr
                                end
                            else
                                % because attributes does not for now work
                                % with multimaps we need an inelegant case
                                % selection, which I don't like ##MK
                                if strcmp(props{i}, 'u08')
                                    k = keys(attrs.u08);
                                    v = values(attrs.u08);
                                elseif strcmp(props{i}, 'i08')
                                    k = keys(attrs.i08);
                                    v = values(attrs.i08);
                                elseif strcmp(props{i}, 'u16')
                                    k = keys(attrs.u16);
                                    v = values(attrs.u16);
                                elseif strcmp(props{i}, 'i16')
                                    k = keys(attrs.i16);
                                    v = values(attrs.i16);
                                elseif strcmp(props{i}, 'u32')
                                    k = keys(attrs.u32);
                                    v = values(attrs.u32);
                                elseif strcmp(props{i}, 'i32')
                                    k = keys(attrs.i32);
                                    v = values(attrs.i32);
                                elseif strcmp(props{i}, 'u64')
                                    k = keys(attrs.u64);
                                    v = values(attrs.u64);
                                elseif strcmp(props{i}, 'i64')
                                    k = keys(attrs.i64);
                                    v = values(attrs.i64);
                                elseif strcmp(props{i}, 'f32')
                                    k = keys(attrs.f32);
                                    v = values(attrs.f32);
                                elseif strcmp(props{i}, 'f64')
                                    k = keys(attrs.f64);
                                    v = values(attrs.f64);
                                else
                                end
                            end
                            for j = 1:length(k)
                                attrib_name = k{j};
                                attrib_value = v{j};
                                % for chr_arr one keyword with a cell
                                % character array value set
                                if strcmp(props{i}, 'chr') || isscalar(attrib_value)   % ##?????
                                    attr_spcid = H5S.create('H5S_SCALAR');     
                                    if H5I.is_valid(attr_spcid)
                                        attr_id = H5A.create(loc_id, attrib_name, attr_dtypid, attr_spcid, 'H5P_DEFAULT');
                                        if H5I.is_valid(attr_id)
                                            H5A.write(attr_id, attr_dtypid, attrib_value);
                                            if obj.verbose
                                                disp(['Wrote attribute named ', attrib_name]);
                                            end
                                            H5A.close(attr_id);
                                        end
                                        H5S.close(attr_spcid);
                                    end
                                else
                                    if obj.verbose
                                        disp(['Considering non-scalar attribute named ', attrib_name]);
                                    end
                                    rank = 1;
                                    dims = 1;
                                    maxdims = dims;
                                    %if strcmp(props{i}, 'chr')
                                    %    dims = 1;
                                    %    maxdims = dims;
                                    %end
                                    if strcmp(props{i}, 'chr_arr')
                                        dims = length(v{1});
                                        maxdims = dims;
                                    end
                                    attr_spcid = H5S.create_simple(rank, dims, maxdims);
                                    if H5I.is_valid(attr_spcid)
                                        attr_id = H5A.create(loc_id, attrib_name, attr_dtypid, ...
                                            attr_spcid, 'H5P_DEFAULT', 'H5P_DEFAULT');
                                        if H5I.is_valid(attr_id)
                                            if strcmp(props{i}, 'chr_arr')
                                                H5A.write(attr_id, attr_dtypid, attrib_value); %{'parting'; 'is'; 'such'; 'sweet sorrow'}); % attrib_value);
                                            else
                                               H5A.write(attr_id, attr_dtypid, attrib_value);
                                            end
                                            if obj.verbose
                                                disp(['Wrote attribute named ', attrib_name]);
                                            end
                                            H5A.close(attr_id);
                                        end
                                        H5S.close(attr_spcid);
                                    end
                                end
                            end
                        end
                    end
                % end
                r = 'MYHDF5_SUCCESS';  % ##MK
            end
        end
        function r = nexus_write(obj, dsnm, val, attrs, varargin)
            % disp(['dst: ' dsnm]);
            if ~isa(dsnm, "char") || length(dsnm) == 0
                if obj.verbose
                    disp('Argument dsnm must not be an empty character array!');
                end
                r = 'MYHDF5_FAILED';
            end
            ifo = io_info(val, 1);  % 0);  % 1); 
            % default is fastest compression (loss-less, gzip) as a
            % compromise between speed and dataset size reduction
            if ~ifo.is_valid
                if obj.verbose
                    disp('Argument val has to be valid and supported!');
                end
                r = 'MYHDF5_FAILED';
            end
            % ##MK::only single character_array for char supported currently
            % special data type handling needed for character array to be
            % stored as ASCII C-style string
            dtyp = ifo.dtype;
            if isa(val, "char")
                max_characters = length(val);  % no null terminator! // + 1; //include null terminator
                if obj.verbose
                    disp(['Argument val is a string with ', max_characters]);
                end
                if max_characters >= 1
                    if obj.verbose
                        disp('max_characters >= 1');
                    end
                    dtyp = H5T.copy('H5T_C_S1');
                    if H5I.is_valid(dtyp)
                        if obj.verbose
                            disp('H5I.is_valid(dtyp)');
                        end
                        if nargin > 4
                            tmp = split(varargin, '_');
                            if strcmp(tmp{1}, 'fix')
                                H5T.set_size(dtyp, max_characters);
                            else
                                H5T.set_size(dtyp, 'H5T_VARIABLE');
                            end
                            if strcmp(tmp{2}, 'nlp')
                                H5T.set_strpad(dtyp, 'H5T_STR_NULLPAD');
                            elseif strcmp(tmp{2}, 'spc')
                                H5T.set_strpad(dtyp, 'H5T_STR_SPACEPAD');
                            else
                                H5T.set_strpad(dtyp, 'H5T_STR_NULLTERM');
                            end
                            if strcmp(tmp{3}, 'asc')
                                H5T.set_cset(dtyp, 'H5T_CSET_ASCII');
                            else
                                H5T.set_cset(dtyp, 'H5T_CSET_UTF8');
                            end
                        else
                            % default to align with h5py in Python
                            H5T.set_size(dtyp, 'H5T_VARIABLE');
                            H5T.set_strpad(dtyp, 'H5T_STR_NULLTERM');
                            H5T.set_cset(dtyp, 'H5T_CSET_UTF8');
                        end
                    else
                        r = 'MYHDF5_FAILED';
                    end
                else
                    r = 'MYHDF5_FAILED';
                end
            end

            clean_abs_path = clean_h5_path(dsnm);
            % obj.nexus_open('H5F_ACC_RDWR');
            if obj.verbose
                disp('Opening file');
            end
            obj.fileid = H5F.open(obj.h5resultsfn, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
            if H5I.is_valid(obj.fileid)
                r = 'MYHDF5_SUCCESS';
            else
                r = 'MYHDF5_FOPEN_FAILED';
            end
            if H5I.is_valid(obj.fileid)
                if obj.verbose
                    disp('H5I.is_valid(obj.fileid)');
                end
                % if ( nexus_link_exists( dsnm, true ) == false ) {
                if ifo.dims == 0
                    if obj.verbose
                        disp('ifo.dims == 0');
                    end
                    % scalar or char array, contiguous layout, never chunked
                    % Be careful and mind the documentation
                    % The HDF5 library uses C-style ordering for multidimensional arrays, while MATLAB uses FORTRAN-style ordering.
                    % The dims and maxdims parameters assume C-style ordering
                    % rank = 1;
                    % dims = [1]; 
                    % maxdims = [1];
                    if isa(val, "char") || isstring(val)
                        obj.dspcid = H5S.create('H5S_SCALAR');
                    else
                        if isscalar(val)
                            obj.dspcid = H5S.create('H5S_SCALAR');
                        else
                            obj.dspcid = H5S.create_simple(1, 1, []);
                        end
                    end
                    if H5I.is_valid(obj.dspcid)
                        if obj.verbose
                            disp('H5I.is_valid(obj.dspcid)');
                        end
                        %if ~islogical(val)
                        obj.dsetid = H5D.create( ...
                            obj.fileid, clean_abs_path, dtyp, ...
                            obj.dspcid, 'H5P_DEFAULT', ...
                            'H5P_DEFAULT', 'H5P_DEFAULT');
                        %else
                        %    obj.dsetid = H5D.create(fid,'/bool',type,space,'H5P_DEFAULT');
                        %end

                        if H5I.is_valid(obj.dsetid)
                            if obj.verbose
                                disp('H5I.is_valid(obj.dsetid)');
                            end
                            H5D.write(obj.dsetid, dtyp, 'H5S_ALL', obj.dspcid, 'H5P_DEFAULT', val);
                            if obj.verbose
                                disp(['Writing ', clean_abs_path, ' scalar success']);
                            end
                            obj.nexus_write_attributes(obj.dsetid, attrs);
                        end
                    end
                elseif ifo.dims == 1
                    if obj.verbose
                        disp('ifo.dims == 1');
                    end
                    % 1d, contiguous or chunked?
                    if ifo.is_chunked
                        if obj.verbose
                            disp('ifo.is_chunked true');
                        end
                        obj.plistid = H5P.create('H5P_DATASET_CREATE');
                        if H5I.is_valid(obj.plistid)
                            if obj.verbose
                                disp('H5I.is_valid(obj.plistid)');
                            end
                            % chunk_rank = ifo.dims;
                            chunk_dims = [max(ifo.chunk)];
                            H5P.set_chunk(obj.plistid, chunk_dims );
                            H5P.set_deflate(obj.plistid, ifo.compression_opts);
                        end
                    end

                    rank = 1;
                    dims = [max(ifo.shape)];
                    maxdims = [max(ifo.shape)]; % ##MK >1 shape value can be on the first or second entry
                    obj.dspcid = H5S.create_simple(rank, dims, maxdims);
                    if H5I.is_valid(obj.dspcid)
                        if obj.verbose
                            disp('H5I.is_valid(obj.dspcid)');
                        end
                        if ifo.is_chunked
                            if obj.verbose
                                disp('ifo.is_chunked true');
                            end
                            obj.dsetid = H5D.create(obj.fileid, clean_abs_path, dtyp, ...
                                obj.dspcid, 'H5P_DEFAULT', obj.plistid, 'H5P_DEFAULT');
                        else
                            if obj.verbose
                                disp('ifo.is_chunked false');
                            end
                            obj.dsetid = H5D.create(obj.fileid, clean_abs_path, dtyp, ...
                                obj.dspcid, 'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT');
                        end
                        if H5I.is_valid(obj.dsetid)
                            if obj.verbose
                                disp('H5I.is_valid(obj.dsetid)');
                            end
                            H5D.write(obj.dsetid, dtyp, obj.dspcid, obj.dspcid, 'H5P_DEFAULT', val);
                            if obj.verbose
                                disp(['Writing ', clean_abs_path, ' 1d success']);
                            end
                            obj.nexus_write_attributes(obj.dsetid, attrs);
                        end
                    end
                elseif ifo.dims >= 2
                    if obj.verbose
                        disp('ifo.dims >= 2');
                    end
                    % 2d or 3d, contiguous or chunked?
                    if ifo.is_chunked  % & ifo.dims == 2
                        if obj.verbose
                            disp('ifo.is_chunked true');
                        end
                        obj.plistid = H5P.create('H5P_DATASET_CREATE');
                        if H5I.is_valid(obj.plistid)
                            if obj.verbose
                                disp('H5I.is_valid(obj.plistid)');
                            end
                            % chunk_rank = ifo.dims;
                            chunk_dims = fliplr(ifo.chunk);
                            H5P.set_chunk(obj.plistid, chunk_dims );
                            H5P.set_deflate(obj.plistid, ifo.compression_opts);
                        end
                    end
                    % do not currently use chunking for 3d datasets because on my R2021b it randomly works on Windows at times
                    % but sometimes it takes just forever if not hangs completely for no clear reason
                    % forever for even for 83x84x3 tiny datasets uint8 which should an SSD although these should fit into the chunk cache... mhhh??
                    % workaround used contiguous layout currently
                    % it was related to the hyperslab selection, something
                    % going wrong with this now we do not use a hyperslab
                    % selection but instead write everything at once!
                    rank = ifo.dims;
                    dims = fliplr(ifo.shape);
                    maxdims = dims;
                    %offs = zeros([1, ifo.dims]);  % using hyperslabs
                    %cnt = fliplr(ifo.shape);
                    %strd = ones([1, ifo.dims]);
                    %blck = ones([1, ifo.dims]);
                    obj.dspcid = H5S.create_simple(rank, dims, maxdims);
                    if H5I.is_valid(obj.dspcid)
                        if obj.verbose
                            disp('H5I.is_valid(obj.dspcid)');
                        end
                        if ifo.is_chunked   % & ifo.dims == 2
                            if obj.verbose
                                disp('ifo.is_chunked true');
                                disp(clean_abs_path);
                            end
                            obj.dsetid = H5D.create(obj.fileid, clean_abs_path, dtyp, ...
                                obj.dspcid, 'H5P_DEFAULT', obj.plistid, 'H5P_DEFAULT');
                        else
                            if obj.verbose
                                disp('ifo.is_chunked false');
                            end
                            obj.dsetid = H5D.create(obj.fileid, clean_abs_path, dtyp, ...
                                obj.dspcid, 'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT');
                        end
                        if H5I.is_valid(obj.dsetid)
                           if obj.verbose
                               disp('H5I.is_valid(obj.dsetid)');
                           end
                           %H5S.select_hyperslab(obj.dspcid, 'H5S_SELECT_SET', offs, strd, cnt, blck);
                           %disp('H5S.select_hyperslab');
                           H5D.write(obj.dsetid, dtyp, obj.dspcid, obj.dspcid, 'H5P_DEFAULT', val);
                           if obj.verbose
                               disp(['Writing ', clean_abs_path, ' 2d success']);
                           end
                           obj.nexus_write_attributes(obj.dsetid, attrs);
                        end
                    end
                % ##MK::implement 3d
                end
            end
            if obj.verbose
                disp('Cleaning up');
            end
            % r = obj.nexus_close();
            if H5I.is_valid(obj.dspcid)
                H5S.close(obj.dspcid);
            end
            if H5I.is_valid(obj.plistid)
                H5P.close(obj.plistid);
            end
            if H5I.is_valid(obj.dsetid)
                H5D.close(obj.dsetid);
            end
            if H5I.is_valid(obj.fileid)
                H5F.close(obj.fileid);
            end

            r = 'MYHDF5_SUCCESS';
            if obj.verbose
                disp([dsnm ' write ' r]);
            end
        end
    end
end
