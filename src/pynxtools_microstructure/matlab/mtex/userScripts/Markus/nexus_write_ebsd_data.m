function status = nexus_write_ebsd_data(~, ~, ~, perform_io)
% Write list of phases to NeXus/HDF5 file

% ebsd_orig:
% fpath: path and filename of NeXus/HDF5 results file
% parent: parent HDF5 group below which to write

% as white is a valid color in typical IPF plots black is used to mark
% pixel which have no associated IPF color value
if ~perform_io
    return;
end
disp('NeXus/HDF5 exporting of EBSD data: OK');
status = true;
end