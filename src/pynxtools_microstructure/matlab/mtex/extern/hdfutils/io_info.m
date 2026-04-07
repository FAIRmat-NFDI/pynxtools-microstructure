classdef io_info
    properties
        shape
        chunk
        compression
        compression_opts
        is_valid
        is_chunked
        dims
        n_values
        dtype
        verbose
    end
    methods
        %% constructor, ##MK::use the most frequently one first 
        function obj = io_info( buf, cmprss_opts )  % chk, cmprss
            % simplified for now 
            obj.shape = [];
            obj.chunk = [];
            obj.compression = 'MYHDF5_COMPRESSION_NONE';
            obj.compression_opts = uint8(0);
            obj.is_chunked = false;
            obj.is_valid = true;
            obj.dims = -1; % unknown number of dimensions
            obj.n_values = 0;
            obj.dtype = '';
            obj.verbose = logical(0);

            if nargin == 2
                supported_dtypes = ["uint8", "int8", ...
                    "uint16", "int16", ...
                    "uint32", "int32", ...
                    "uint64", "int64", ...                    
                    "single", "double", ...
                    "char"];
                mapped_h5types = ["H5T_STD_U8LE", "H5T_STD_I8LE", ...
                    "H5T_STD_U16LE", "H5T_STD_I16LE", ...
                    "H5T_STD_U32LE", "H5T_STD_I32LE", ...
                    "H5T_STD_U64LE", "H5T_STD_I64LE", ...
                    "H5T_IEEE_F32LE", "H5T_IEEE_F64LE", ...
                    "H5T_C_STRING"];
                for i = 1:length(supported_dtypes)
                    if isa(buf, supported_dtypes(i)) == true
                        obj.dtype = convertStringsToChars(mapped_h5types(i));
                        break;
                    end
                end

                if ~strcmp(obj.dtype, '')
                    shp = size(buf);

                    if isa(buf, "char")
                        obj.dims = 0;
                        obj.shape = shp;
                        obj.n_values = prod(shp);
                        if obj.shape < 1
                            obj.is_valid = false;
                        end
                    else
                        if isscalar(buf)
                            obj.dims = 0;
                        end
                        if length(shp) == 2 || length(shp) == 3  % currently supporting scalar, 1d, 2d, and 3d
                            obj.shape = shp;
                            obj.n_values = prod(shp);
                            if numel(unique(shp)) == 1 && shp(1) == 1
                                % no chunking for scalar or single value 1d array
                            else
                                if any(shp == 1) % check 
                                    obj.dims = 1;
                                else
                                    if numel(shp) == 2
                                        obj.dims = 2;
                                    end
                                    if numel(shp) == 3
                                        obj.dims = 3;
                                    end
                                end
                                % 1d, 2d, ... and not all dimensions of length 1
                                % if length(shp) > 1 && length(shp) == length(chk)
                                % no chunking for scalars
                                % for i = 1:length(shp)
                                %     if mod(shp(i), chk(i)) ~= 0
                                %         obj.chunk = [obj.chunk, shp(i)];
                                %     else
                                %         obj.chunk = [obj.chunk, chk(i)];
                                %     end
                                % end
                                if ismember(uint8(cmprss_opts), uint8([linspace(1, 9, 9)]))
                                    if ~isa(buf, "char")
                                        obj.compression = 'MYHDF5_COMPRESSION_GZIP';
                                        obj.compression_opts = uint8(cmprss_opts);                    
                                        obj.is_chunked = true;
                                        obj.chunk = obj.shape;
                                    end
                                end                 
                            end
                        else
                            obj.is_valid = false;
                        end
                    end
                    % else
                    % obj.is_valid = false;
                end
                if obj.n_values == 0
                    obj.is_valid = false;
                end
            end
            if obj.verbose
                obj.report();
            end
        end

        function report(obj)
            disp('Shape');
            disp(obj.shape);
            disp('Compression');
            disp(obj.compression);
            disp('Compression option');
            disp(obj.compression_opts);
            disp('Chunk');
            disp(obj.chunk);
            disp('is_chunked');
            disp(obj.is_chunked);
            disp('is_valid');
            disp(obj.is_valid);
            disp('dimensionality');
            disp(obj.dims);
            disp('n_values');
            disp(obj.n_values);
            disp('mapped hdf5 type');
            disp(obj.dtype(1:end));
            disp('verbose');
            disp(num2str(obj.verbose));
        end
    end
end