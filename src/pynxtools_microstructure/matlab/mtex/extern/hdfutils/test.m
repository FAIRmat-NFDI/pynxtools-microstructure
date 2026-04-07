% https://github.com/RolandRitt/Matlab-NestedMap
a = single(fact(6));
if isa(a, "string") == true
    disp("Yes");
else
    disp("No");
end


keys = ["uint8", "int8", "uint16", "int16", "uint32", "int32", "uint64", "int64", "single", "double", "char"];
values = [+8, -8, +16, -16, +32, -32, +64, -64, 128, 256, 1000]; 
% d = dictionary(keys, values); % only supported with >=v2022b :(
for i = 1:length(keys)
    if isa(a, keys(i))  % == true
        %disp(values(i));
        disp(class(a));
    end
end

%% generate test data,example arrays
n = 1000;
nul_d = 1;
one_d = reshape(linspace(1, n*1, n*1), [n, 1]); %repmat(255, 5, 1));
two_d = reshape(linspace(1, n*3, n*3), [n, 3]); %repmat(255, 5, 3));
thr_d = reshape(linspace(1, n*3*2, n*3*2), [n, 3, 2]); %repmat(255, 5, 3, 2));

u08_0d = uint8(nul_d);
u08_1d = uint8(one_d);
u08_2d = uint8(two_d); 
u08_3d = uint8(thr_d);
i08_0d = int8(nul_d);
i08_1d = int8(one_d);
i08_2d = int8(two_d); 
i08_3d = int8(thr_d);
u16_0d = uint16(nul_d);
u16_1d = uint16(one_d);
u16_2d = uint16(two_d); 
u16_3d = uint16(thr_d);
i16_0d = int16(nul_d);
i16_1d = int16(one_d);
i16_2d = int16(two_d); 
i16_3d = int16(thr_d);
u32_0d = uint32(nul_d);
u32_1d = uint32(one_d);
u32_2d = uint32(two_d); 
u32_3d = uint32(thr_d);
i32_0d = int32(nul_d);
i32_1d = int32(one_d);
i32_2d = int32(two_d); 
i32_3d = int32(thr_d);
u64_0d = uint64(nul_d);
u64_1d = uint64(one_d);
u64_2d = uint64(two_d); 
u64_3d = uint64(thr_d);
i64_0d = int64(nul_d);
i64_1d = int64(one_d);
i64_2d = int64(two_d); 
i64_3d = int64(thr_d);
f32_0d = single(nul_d);
f32_1d = single(one_d);
f32_2d = single(two_d); 
f32_3d = single(thr_d);
f64_0d = double(nul_d);
f64_1d = double(one_d);
f64_2d = double(two_d); 
f64_3d = double(thr_d);
char_1d = 'char_1d';

% isscalar(f64_3d)
% isstring(f64_3d)
% size(f64_3d)
% length(f64_3d)


% aa = io_info();
% aa = io_info( [], [5, 1], 'MYHDF5_COMPRESSION_GZIP', 9);
aa = io_info( char_1d, 9 )
aa = io_info( u08_0d, 9 )
aa = io_info( u08_1d, 9 )
aa = io_info( u08_2d, 9 )
aa = io_info( u08_3d, 9 )

%% nexus_write

a = 'entry/group/////   subgroup/subsubgroup//////                ';
h5fn = 'test.nxs';
h5w = HdfFiveSeqHdl(h5fn);
ret = h5w.nexus_create(h5fn);
ret = h5w.nexus_open('H5F_ACC_RDWR');
ret = h5w.nexus_close();
attr = io_attributes();
attr.magic();
%attr.report();
ret = h5w.nexus_write_group(a, attr);
dsnm = [clean_h5_path(a), '/u08_0d'];
vals = u08_0d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(a), '/u08_1d'];
vals = u08_1d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(a), '/u08_2d'];
vals = u08_2d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(a), '/char_1d'];
vals = char_1d;
ret = h5w.nexus_write(dsnm, vals, attr);

%% attribute dictionaries
a = 'entry/group/////   subgroup/subsubgroup//////                ';
attr = io_attributes();
attr.magic();
% attr.magic(); % called twice to proof that attribute keyword unique checks work correctly
attr.report();
h5fn = 'test.nxs';
h5w = HdfFiveSeqHdl(h5fn);
ret = h5w.nexus_create(h5fn);
ret = h5w.nexus_open('H5F_ACC_RDWR');
ret = h5w.nexus_close();
ret = h5w.nexus_write_group(a);
ret = h5w.nexus_write_attributes(a, attr);

mymap = MapNested(); %generate a new object
mymap('u08', 'a') = uint8(1);


mp = findobj(attrPropertyList,'Name','u08');
fh = mp.GetMethod;

k = keys(attr.u08);
v = values(attr.u08);
for i = 1:length(attr.u08)
    disp(k{i});
    disp(v{i});
end
length(attr.u16)>=1

%% add support for scalar attributes
%% add support for character arrays
%% bugfixing



