%% generate test data, 0d, 1d, 2d example arrays and character array
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
char_2d = {'zpos', 'yp', 'x', 'vvery lllonnng'};
% for Matlab vertcal array has to have same number of characters therefore
% using cell array

%% nexus_write

grpnm = 'entry/group/////   subgroup/subsubgroup//////                ';
h5fn = 'test.nxs';
h5w = HdfFiveSeqHdl(h5fn);
ret = h5w.nexus_create(h5fn);
ret = h5w.nexus_open('H5F_ACC_RDWR');
ret = h5w.nexus_close();
attr = io_attributes();
attr.magic();
% attr.report();
ret = h5w.nexus_write_group(grpnm, attr);

dsnm = [clean_h5_path(grpnm), '/u08_0d']; vals = u08_0d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/u08_1d']; vals = u08_1d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/u08_2d']; vals = u08_2d;
ret = h5w.nexus_write(dsnm, vals, attr);

dsnm = [clean_h5_path(grpnm), '/i08_0d']; vals = i08_0d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/i08_1d']; vals = i08_1d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/i08_2d']; vals = i08_2d;
ret = h5w.nexus_write(dsnm, vals, attr);

dsnm = [clean_h5_path(grpnm), '/u16_0d']; vals = u16_0d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/u16_1d']; vals = u16_1d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/u16_2d']; vals = u16_2d;
ret = h5w.nexus_write(dsnm, vals, attr);

dsnm = [clean_h5_path(grpnm), '/i16_0d']; vals = i16_0d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/i16_1d']; vals = i16_1d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/i16_2d']; vals = i16_2d;
ret = h5w.nexus_write(dsnm, vals, attr);

dsnm = [clean_h5_path(grpnm), '/u32_0d']; vals = u32_0d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/u32_1d']; vals = u32_1d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/u32_2d']; vals = u32_2d;
ret = h5w.nexus_write(dsnm, vals, attr);

dsnm = [clean_h5_path(grpnm), '/i32_0d']; vals = i32_0d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/i32_1d']; vals = i32_1d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/i32_2d']; vals = i32_2d;
ret = h5w.nexus_write(dsnm, vals, attr);

dsnm = [clean_h5_path(grpnm), '/u64_0d']; vals = u64_0d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/u64_1d']; vals = u64_1d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/u64_2d']; vals = u64_2d;
ret = h5w.nexus_write(dsnm, vals, attr);

dsnm = [clean_h5_path(grpnm), '/i64_0d']; vals = i64_0d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/i64_1d']; vals = i64_1d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/i64_2d']; vals = i64_2d;
ret = h5w.nexus_write(dsnm, vals, attr);

dsnm = [clean_h5_path(grpnm), '/f32_0d']; vals = f32_0d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/f32_1d']; vals = f32_1d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/f32_2d']; vals = f32_2d;
ret = h5w.nexus_write(dsnm, vals, attr);

dsnm = [clean_h5_path(grpnm), '/f64_0d']; vals = f64_0d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/f64_1d']; vals = f64_1d;
ret = h5w.nexus_write(dsnm, vals, attr);
dsnm = [clean_h5_path(grpnm), '/f64_2d']; vals = f64_2d;
ret = h5w.nexus_write(dsnm, vals, attr);

dsnm = [clean_h5_path(grpnm), '/char_1d']; vals = char_1d;
ret = h5w.nexus_write(dsnm, vals, attr);

