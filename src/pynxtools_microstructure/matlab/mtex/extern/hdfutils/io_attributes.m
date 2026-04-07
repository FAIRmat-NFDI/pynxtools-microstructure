% pwd
% addpath(genpath([pwd, '\Matlab-NestedMap']));
% using Roland Ritt's multi-map container to simplify the datatype
% selections when processing HDF5 attributes

classdef io_attributes
    properties
        % map of scalar attributes
        u08
        i08
        u16
        i16
        u32
        i32
        u64
        i64
        f32
        f64
        chr
        chr_arr
        % each attribute in an HDF5 loc_id must have a unique name
        % typed_attributes
        unique_attribute_names
        verbose
    end
    methods
        function obj = io_attributes()
            obj.u08 = containers.Map('KeyType', 'char','ValueType', 'uint8');
            obj.i08 = containers.Map('KeyType', 'char','ValueType', 'int8');
            obj.u16 = containers.Map('KeyType', 'char','ValueType', 'uint16');
            obj.i16 = containers.Map('KeyType', 'char','ValueType', 'int16');
            obj.u32 = containers.Map('KeyType', 'char','ValueType', 'uint32');
            obj.i32 = containers.Map('KeyType', 'char','ValueType', 'int32');
            obj.u64 = containers.Map('KeyType', 'char','ValueType', 'uint64');
            obj.i64 = containers.Map('KeyType', 'char','ValueType', 'int64');
            obj.f32 = containers.Map('KeyType', 'char','ValueType', 'single');
            obj.f64 = containers.Map('KeyType', 'char','ValueType', 'double');
            obj.chr = containers.Map('KeyType', 'char','ValueType', 'char');
            obj.chr_arr = containers.Map('KeyType', 'char', 'ValueType', 'any');
            % obj.typed_attributes = MapNested();
            obj.unique_attribute_names = containers.Map( ...
                'KeyType', 'char', 'ValueType', 'logical');
            obj.verbose = logical(0);
        end
        function add(obj, keyword, value)
            if isa(keyword, "char")
                if ~obj.unique_attribute_names.isKey(keyword)
                    if ~iscell(value) % cell of character arrays
                        if isa(value, "uint8")
                            obj.u08(keyword) = value;
                            % obj.typed_attributes('u08', keyword) = value;
                            obj.unique_attribute_names(keyword) = true;
                        elseif isa(value, "int8")
                            obj.i08(keyword) = value;
                            % obj.typed_attributes('i08', keyword) = value;
                            obj.unique_attribute_names(keyword) = true;
                        elseif isa(value, "uint16")
                            obj.u16(keyword) = value;
                            % obj.typed_attributes('u16', keyword) = value;
                            obj.unique_attribute_names(keyword) = true;
                        elseif isa(value, "int16")
                            obj.i16(keyword) = value;
                            % obj.typed_attributes('i16', keyword) = value;
                            obj.unique_attribute_names(keyword) = true;
                        elseif isa(value, "uint32")
                            obj.u32(keyword) = value;
                            % obj.typed_attributes('u32', keyword) = value;
                            obj.unique_attribute_names(keyword) = true;
                        elseif isa(value, "int32")
                            obj.i32(keyword) = value;
                            % obj.typed_attributes('i32', keyword) = value;
                            obj.unique_attribute_names(keyword) = true;
                        elseif isa(value, "uint64")
                            obj.u64(keyword) = value;
                            % obj.typed_attributes('u64', keyword) = value;
                            obj.unique_attribute_names(keyword) = true;
                        elseif isa(value, "int64")
                            obj.i64(keyword) = value;
                            % obj.typed_attributes('i64', keyword) = value;
                            obj.unique_attribute_names(keyword) = true;
                        elseif isa(value, "single")
                            obj.f32(keyword) = value;
                            % obj.typed_attributes('f32', keyword) = value;
                            obj.unique_attribute_names(keyword) = true;
                        elseif isa(value, "double")
                            obj.f64(keyword) = value;
                            % obj.typed_attributes('f64', keyword) = value;
                            obj.unique_attribute_names(keyword) = true;
                        elseif isa(value, "char")
                            obj.chr(keyword) = value;
                            % obj.typed_attributes('chr', keyword) = value;
                            obj.unique_attribute_names(keyword) = true;
                        end
                    else % cell of character arrays
                        obj.chr_arr(keyword) = value;
                        obj.unique_attribute_names(keyword) = true;
                    end
                else
                    disp(['Attribute with keyword ', keyword, ' exists!']);
                end
            end
        end
        function report(obj)
            % disp(keys(obj.exists));
            % dtyp_map_keys = obj.typed_attributes.keys;
            % dtyp_map_vals = obj.typed_attributes.values;
            % for i = 1:length(dtyp_map_keys)
            %     disp(['Entering datatype outer dict ', dtyp_map_keys{i}]);
            %     typed_map = obj.typed_attributes(dtyp_map_keys{i});
            %     map_keys = typed_map.keys();
            %     map_vals = typed_map.values();
            %     for j = 1:length(map_keys)
            %         disp(['    keyword: ', map_keys{j}, ' value:']);
            %         disp(map_vals{j});
            %     end                    
            % end
            % thought the above solution is more elegant but it does
            % not work, maybe missing copy constructor in NestedMap class?
            disp('uint8-typed attributes');
            k = keys(obj.u08);
            v = values(obj.u08);
            for i = 1:length(k)
                disp(k);
                disp(v);
            end
            disp('int8-typed attributes');
            k = keys(obj.i08);
            v = values(obj.i08);
            for i = 1:length(k)
                disp(k);
                disp(v);
            end
            disp('uint16-typed attributes');
            k = keys(obj.u16);
            v = values(obj.u16);
            for i = 1:length(k)
                disp(k);
                disp(v);
            end
            disp('int16-typed attributes');
            k = keys(obj.i16);
            v = values(obj.i16);
            for i = 1:length(k)
                disp(k);
                disp(v);
            end
            disp('uint32-typed attributes');
            k = keys(obj.u32);
            v = values(obj.u32);
            for i = 1:length(k)
                disp(k);
                disp(v);
            end
            disp('int32-typed attributes');
            k = keys(obj.i32);
            v = values(obj.i32);
            for i = 1:length(k)
                disp(k);
                disp(v);
            end
            disp('uint64-typed attributes');
            k = keys(obj.u64);
            v = values(obj.u64);
            for i = 1:length(k)
                disp(k);
                disp(v);
            end                
            disp('single-typed attributes');
            k = keys(obj.f32);
            v = values(obj.f32);
            for i = 1:length(k)
                disp(k);
                disp(v);
            end
            disp('int64-typed attributes');
            k = keys(obj.i64);
            v = values(obj.i64);
            for i = 1:length(k)
                disp(k);
                disp(v);
            end
            disp('double-typed attributes');
            k = keys(obj.f64);
            v = values(obj.f64);
            for i = 1:length(k)
                disp(k);
                disp(v);
            end
            disp('char-typed attributes');
            k = keys(obj.chr);
            v = values(obj.chr);
            for i = 1:length(k)
                disp(k);
                disp(v);
            end
            disp('cell of char-typed attributes');
            k = keys(obj.chr_arr);
            v = values(obj.chr_arr);
            for i = 1:length(k)
                for j = 1:length(v{i})
                    disp(v{i}{j});
                end
            end
        end
        function magic(obj)
            % some test data for debugging
            obj.add('u08', uint8(1));
            obj.add('i08', int8(1));
            obj.add('u16', uint16(1));
            obj.add('i16', int16(1));
            obj.add('u32', uint32(1));
            obj.add('i32', int32(1));
            obj.add('u64', uint64(1));
            obj.add('i64', int64(1));
            obj.add('f32', single(1.));
            obj.add('f64', double(1.));
            obj.add('chr', 'char_1d');
            obj.add('chr_arr', {'zpos', 'yp', 'x', 'vvery lllonnng'});
        end
    end
end
