clc;
clear;

fname = fullfile(mtexDataPath,'EBSD3','SimulatedMultiPhase.h5');
ebsd = loadEBSD_xnovo(fname);

% UNFORTUNATELY calcGrains is not yet a feature of MTex for ESBD3Cube

disorientation_threshold = 15.0*degree;
discretization_threshold = 5;
[grains, ebsd.grainId] = calcGrains( ...
    ebsd('indexed'), ...
    'boundary', 'tight', ...
    'angle', disorientation_threshold, ...
    'minPixel', discretization_threshold);


nexus_fpath = fullfile(mtexDataPath,'EBSD3','SimulatedMultiPhase.h5.nxs');
h5w = HdfFiveSeqHdl(nexus_fpath);
ret = h5w.nexus_create(nexus_fpath);
ret = h5w.nexus_open('H5F_ACC_RDWR');
ret = h5w.nexus_close();

h5w = HdfFiveSeqHdl(nexus_fpath);

grpnm = '/entry1';
attr = io_attributes();
attr.add('NX_class', 'NXentry');
ret = h5w.nexus_write_group(grpnm, attr);
grpnm = ['/entry1/microstructure'];
attr = io_attributes();
attr.add('NX_class', 'NXmicrostructure');
ret = h5w.nexus_write_group(grpnm, attr);

parent = '/entry1/microstructure';
grpnm = [parent '/cg_point'];
attr = io_attributes();
attr.add('NX_class', 'NXcg_point');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [parent  '/cg_point/dimensionality'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(3), attr);
dsnm = [parent  '/cg_point/cardinality'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(length(grains.allV)), attr);
dsnm = [parent  '/cg_point/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
dsnm = [parent  '/cg_point/position'];
attr = io_attributes();
% attr.add("units", "1");
ret = h5w.nexus_write(dsnm, double(grains.allV), attr);

%% find unique triangles that represent the interface network
% TODO does F = grains.boundary.F yield triangles in winding order?
grpnm = [parent '/crystals'];
attr = io_attributes();
attr.add('NX_class', 'NXobject');
ret = h5w.nexus_write_group(grpnm, attr);
grpnm = [parent '/interfaces'];
attr = io_attributes();
attr.add('NX_class', 'NXobject');
ret = h5w.nexus_write_group(grpnm, attr);

grpnm = [parent '/crystals'];
dsnm = [grpnm '/number_of_crystals'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(length(grains), attr);
dsnm = [grpnm '/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);

n_grains = length(grains);
uniq_facets_adjacent_grains = containers.Map;
grain_ids = zeros([1, n_grains]);
phase_ids = zeros([1, n_grains]);
roi_contacts = zeros([1, n_grains]);
vols = zeros([1, n_grains]);
oris = zeros([4, n_grains]);
nbors = zeros([1, n_grains]);

for i = 1:1:n_grains
    g = grains(i);
    grain_id = g.id;
    bnd = g.boundary;
    nbs = uint32(g.numNeighbors);
    nf = uint32(full(g.numFaces));
    triangles_uvw = bnd.F;
    triangles_area = bnd.area;
    triangles_phase = bnd.phaseId; % phaseId == 0 is ROI boundary
    no_boundary_contact = all(triangles_phase, 2);
    roi_contact_area = sum(triangles_area) - sum(triangles_area(no_boundary_contact));
    total_area = sum(triangles_area);
    roi_contact_cnt = length(triangles_area) - length(triangles_area(no_boundary_contact));
    total_cnt = length(triangles_area);
    % disp('Get MTex summary statistics as a proof of understanding');
    % bnd
    % disp(['notIndexed (ROI)/unknown ' num2str(roi_contact_area / total_area)]);
    % disp(['unknown/unknown ' num2str((total_area - roi_contact_area) / total_area)]);
    % disp(['notIndexed (ROI)/unknown cnt ' num2str(roi_contact_cnt)]);
    % disp(['unknown/unknown cnt ' num2str(total_cnt - roi_contact_cnt)]);
    
    grain_ids(i) = g.id;
    phase_ids(i) = g.phaseId;
    roi_contacts(i) = ~all(no_boundary_contact);
    vols(i) = g.volume;
    oris(1, i) = g.meanOrientation.a;
    oris(2, i) = g.meanOrientation.b;
    oris(3, i) = g.meanOrientation.c;
    oris(4, i) = g.meanOrientation.d;
    nbors(i) = g.numNeighbors;
        
    for j = 1:1:length(triangles_uvw)
        triplet = sort([triangles_uvw(j, :)]);
        key = [num2str(triplet(1)) '_' num2str(triplet(2)) '_' num2str(triplet(3))];
        if ~isKey(uniq_facets_adjacent_grains, key)
            uniq_facets_adjacent_grains(key) = [grain_id];
        else
            uniq_facets_adjacent_grains(key) = [uniq_facets_adjacent_grains(key), grain_id];
        end
    end
    clearvars g grain_id bnd nbs nf triangles_uvw triangles_area triangles_phase no_boundary_contact roi_contact_area total_area roi_contact_cnt total_cnt j triplet key;
end
grpnm = [parent '/crystals'];
dsnm = [grpnm '/indices_crystals'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(grain_ids), attr);
dsnm = [grpnm '/indices_phase'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(phase_ids), attr);
dsnm = [grpnm '/boundary_contact'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint8(roi_contact), attr);
dsnm = [grpnm '/volume'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, volume, attr);
dsnm = [grpnm '/number_of_neighbors'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(nbors), attr);
grpnm = [parent '/crystals/orientation'];
attr = io_attributes();
attr.add('NX_class', 'NXrotations');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm =  [grpnm '/parameterization'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, 'quaternion', attr);
dsnm = [grpnm '/orientation'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, orientation, attr);
clearvars grain_ids phase_ids roi_contacts vols oris nbors;

% TODO - DONE until here

boundary_facets = 0;
nf = uint32(full(grains.numFaces));  % is sparse, use full(nf) to convert to full
nbs = uint32(grains.numNeighbors);
% A = grains.boundary.area;
k = keys(unique_triangles);
v = values(unique_triangles);
uniq_facet_ids_of_grains = containers.Map;
for uniq_facet_id = 1:1:length(v)
    % disp(uniq_facet_id);
    tmp = v{uniq_facet_id};
    if length(tmp) == 2
        continue
    else
        boundary_facets = boundary_facets + 1;
        disp(['Not exactly two grains meet ' num2str(uniq_facet_id) ', ' num2str(length(tmp))]);
    end
    % for j = 1:1:length(tmp)
    %     key = num2str(tmp(j));  % grain id is key
    %     if ~isKey(uniq_facet_ids_of_grains, key)
    %         uniq_facet_ids_of_grains(key) = [uniq_facet_id];
    %     else
    %         uniq_facet_ids_of_grains(key) = [uniq_facet_ids_of_grains(key), uniq_facet_id];
    %     end
    % end
    % if length(tmp) == 3
    %     disp(['Triple junction ' num2str(uniq_facet_id) ', ' num2str(length(tmp))]);
    % elseif length(tmp) > 3
    %     disp(['HO junction ' num2str(uniq_facet_id) ', ' num2str(length(tmp))]);
    % end
end
disp(boundary_facets);
grains.boundary
k = keys(uniq_facet_ids_of_grains);
v = values(uniq_facet_ids_of_grains);

        

grpnm = [parent '/cg_triangle'];
attr = io_attributes();
attr.add('NX_class', 'NXcg_triangle');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [parent  '/cg_point/dimensionality'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(3), attr);
dsnm = [parent  '/cg_point/cardinality'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(length(grains.F)), attr);
dsnm = [parent  '/cg_point/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
dsnm = [parent  '/cg_point/position'];
attr = io_attributes();
attr.add( "units", "1");
ret = h5w.nexus_write(dsnm, double(grains.allV), attr);







% get largest grain
[max, gmax_idx] = max(grains.volume);
g = grains(gmax_idx);
% largest boundary face of it
[max, bmax_idx] = max(g.boundary.area);
bnds = g.boundary;
b = bnds(bmax_idx);
V = grains.allV;




f_v_mx = 0;
for i = 1:1:length(grains)
    disp(i);
    g = grains(i);
    if max(max(g.F)) >= f_v_mx
        f_v_mx = max(max(g.F));
    end
end


%% distinguish hex and square

fnm_hex = fullfile(mtexDataPath,'EBSD',['testdata_hex.ctf']);
fnm_sqr = fullfile(mtexDataPath,'EBSD',['testdata_sqr.ctf']);
ebsd_hex = loadEBSD_ctf(fnm_hex);
ebsd_sqr = loadEBSD_ctf(fnm_sqr);
a_hex = ebsd_hex(1);
a_sqr = ebsd_sqr(1);
u_hex = a_hex.unitCell;
u_sqr = a_sqr.unitCell;


