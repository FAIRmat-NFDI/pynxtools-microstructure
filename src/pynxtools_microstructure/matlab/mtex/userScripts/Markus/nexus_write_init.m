function status = nexus_write_init(fpath, perform_io)
% init fresh NeXus/HDF5 file with path and file name given by fpath

% disp(['Reporting results to NeXus/HDF5 to ' fpath]);
if ~perform_io
    return;
end
h5w = HdfFiveSeqHdl(fpath);
h5w.nexus_create(fpath);
h5w.nexus_open('H5F_ACC_RDWR');
h5w.nexus_close();

% all root-level annotations will be added by pynxtools/em parser
grpnm = '/entry1';
attr = io_attributes();
attr.add('NX_class', 'NXentry');
h5w.nexus_write_group(grpnm, attr);

grpnm = '/entry1/roi1';
attr = io_attributes();
attr.add('NX_class', 'NXroi_process');
h5w.nexus_write_group(grpnm, attr);

grpnm = '/entry1/roi1/ebsd';
attr = io_attributes();
attr.add('NX_class', 'NXem_ebsd');
h5w.nexus_write_group(grpnm, attr);

grpnm = '/entry1/roi1/ebsd/indexing';
attr = io_attributes();
attr.add('NX_class', 'NXprocess');
h5w.nexus_write_group(grpnm, attr);

grpnm = '/entry1/profiling';
attr = io_attributes();
attr.add('NX_class', 'NXcs_profiling');
h5w.nexus_write_group(grpnm, attr);

disp('NeXus/HDF5 initializing file: OK');
status = true;

end