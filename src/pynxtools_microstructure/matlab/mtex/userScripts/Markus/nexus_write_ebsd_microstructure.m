function status = nexus_write_ebsd_microstructure(ebsd_orig, fpath, parent, perform_io)
% Generate extracted grains, grain- and phase boundary and triple point geometry

% ebsd_orig = ebsd_raw;  % array of one EBSD object per scan point
% fpath = ofpath; path and filename of NeXus/HDF5 results file
% parent = '/entry1/roi1/ebsd/indexing'; % parent HDF5 group below which to write

%% generate discretization of crystal interface network
% the idea with this function here is to show how irrespective how the
% grains were reconstructed, we can then export the geometry description
% using NeXus classes
ms_tic = tic;
if ~perform_io
    return;
end
h5w = HdfFiveSeqHdl(fpath);

scan_unit = 'n/a';
if strcmp(ebsd_orig.scanUnit, 'um')
    scan_unit = 'µm';
else
    scan_unit = lower(ebsd_orig.scanUnit);
end

disorientation_threshold = 15.0*degree;
discretization_threshold = 5;
% classical 15. high-angle to low-angle grain boundary
% use smaller values to segment sub-grain boundary network
% do not call like this [grains, ebsd_orig.grainId] as this
% is extremely slow

disp(['Grain reconstruction ...']);
% [grains,ebsd_orig.grainId,ebsd_orig.mis2mean] 
% [grains, ebsd_orig.grainId] 
grains = calcGrains( ...
    ebsd_orig('indexed'), ...
    'boundary', 'tight', ...
    'angle', disorientation_threshold, ...
    'minPixel', discretization_threshold);
disp(['Grain reconstruction: OK']);
% plot(grains)
% use [val , idx] = max(grains.area('2d')); to find the largest grain
% alternative grain reconstruction methods exist e.g.
% for subtle orientation gradients, fast multi-scale clustering, 
% https://doi.org/10.1016/j.ultramic.2013.04.009
% for the Forsterite example this is not useful due to interfaces strongly ragged
% grains_fmc = calcGrains(ebsd('indexed'), 'boundary', 'tight', 'FMC', 3.5);
% for subtle orientation gradients, Markov graph clustering
% https://micans.org/mcl/, http://dx.doi.org/10.1007/s11661-018-4904-9
% for the Forsterite example this tried to allocate a 294GB matrix 
% grains_mcl = calcGrains(ebsd('indexed'), 'boundary', ...
%     'tight', 'mcl', [1.24 50], 'soft', [0.2 0.3]*degree);
% so for the run-through we use the default voronoi tessellation based
% approach https://doi.org/10.1016/j.ultramic.2011.08.002

%% store discretization of crystal interface network
% MTex generates vertices and interfaces discretized into linear segments
% each segment is stored as a grainBoundary class object, therefore
% we need to reconstruct which segments are part of individual interface
% segments between grains i, j
% some of the vertices represent triplePoints, these store their adjacent
% grains and interface segments
% with reconstruction parameter 'boundary' set the edge of the ROI adds
% segments which by definition belong to the virtual grain 0 i.e. the edge
% each interface is conceptually a half-edge as it connects two crystals
% the ROI is tessellated by polygons of two types crystals and notIndexed
% crystals are bounded by interfaces, interfaces meet at triple junctions
% the edge of the ROI cuts crystals which have contact at the edge of the
% dataset

% eventually wrap this into an ROI
grpnm = [parent '/microstructure1'];
attr = io_attributes();
attr.add('NX_class', 'NXmicrostructure');
ret = h5w.nexus_write_group(grpnm, attr);

grpnm = [parent '/microstructure1/configuration'];
attr = io_attributes();
attr.add('NX_class', 'NXparameters');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [grpnm '/algorithm'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, 'disorientation_clustering', attr);
dsnm = [grpnm '/comments'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, 'indexed, boundary, tight', attr);
dsnm = [grpnm '/disorientation_threshold'];
attr = io_attributes();
attr.add('units', '°');
ret = h5w.nexus_write(dsnm, disorientation_threshold / degree, attr);
dsnm = [grpnm '/discretization_threshold'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, discretization_threshold, attr);

% this implementation currently supports 32-bit wide identifier
% for integer valued quantities, the support can be extended by
% changing the reporting type from (u)int32 to (u)int64
% typically though a width of 32 bits allows to store 2^32 identifier
% if counting from zero which especially for 2D are extremely large
% EBSD maps that one would not even exhaust if each hexagon-shaped pixel
% of a 500 million !!! scan point EBSD map is naively stored with each
% of its six vertices repeated
% using 32 bit instead of blindly 64 bit makes each processing
% take half the cache and feeding half the payload to the compression
% that is happening within the nexus_write calls
% another benefit of 32-bit ids is that adjacencies of two grains
% at interfaces can be encoded as an uint64 that is beneficial for
% dictionary lookup as used in several occasions in the code below
if size(grains.boundary.F, 1) >= 2^32 - 1 || length(grains) >= 2^32 - 1
    error(['The interface network of grains has more individuals ' ...
           'than the here used 32bit ID handling can deal with!']);
end

%% summary statistics
% grains.boundary reports a summary table how many segments
% and how much boundary length between different phases
% in what follows we store the raw data from which these
% summary statistics can be computed

%% instantiate storage of representation of the primitives
disp(['Primitives ...']);
grpnm = [parent '/microstructure1'];
dsnm = [grpnm '/dimensionality'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(2), attr);

%% vertices
grpnm = [parent '/microstructure1/cg_point'];
attr = io_attributes();
attr.add('NX_class', 'NXcg_point');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [grpnm '/dimensionality'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(2), attr);
dsnm = [grpnm '/cardinality'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(size(grains.allV.xy, 1)), attr);
dsnm = [grpnm '/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
dsnm = [grpnm '/position'];
attr = io_attributes();
attr.add('units', scan_unit);
ret = h5w.nexus_write(dsnm, double(grains.allV.xy'), attr);

%% polylines, representing individual interface facets
% problem the term facet is used for both a discretization of an interface
% patch as well as for describing a specific (low-energy or low Miller
% indices) face of a crystal
grpnm = [parent '/microstructure1/cg_polyline'];
attr = io_attributes();
attr.add('NX_class', 'NXcg_polyline');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [grpnm '/dimensionality'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(2), attr);
dsnm = [grpnm '/cardinality'];
polylines = grains.boundary.F;
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(size(polylines, 1)), attr);
dsnm = [grpnm '/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
dsnm = [grpnm '/number_of_vertices'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(2*ones([1, size(polylines, 1)]))', attr);
dsnm = [grpnm '/polylines'];
attr = io_attributes();
attr.add('use_these', [parent '/microstructure1/cg_point']);
polylines = grains.boundary.F';
ret = h5w.nexus_write(dsnm, uint32(reshape(polylines, ...
    [1, 2*length(polylines)])), attr);
dsnm = [grpnm '/length'];
p_u = grains.allV(polylines(1, :), :);
p_v = grains.allV(polylines(2, :), :);
facet_length = hypot((p_u.x - p_v.x), (p_u.y - p_v.y));
if any(isnan(facet_length))
    error('At least one entry in facet_length is NaN !');
end
attr = io_attributes();
attr.add('units', scan_unit);
ret = h5w.nexus_write(dsnm, facet_length, attr);
clearvars p_u p_v facet_length;
disp(['Primitives: OK']);

%% store crystals/grains
disp(['Crystals ...']);
grpnm = [parent '/microstructure1/crystals'];
attr = io_attributes();
attr.add('NX_class', 'NXobject');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [grpnm '/number_of_crystals'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(length(grains)), attr);
dsnm = [grpnm '/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
dsnm = [grpnm '/area_by_pixel'];  % which type of area all pixels, polygon area?
% area_per_ebsd_pixel = polyshape(ebsd_orig.unitCell.xy).area;  % clock-wise winding order?
attr = io_attributes();
ret = h5w.nexus_write(dsnm, double(grains.numPixel), attr);  %  * area_per_ebsd_pixel
clearvars area_per_ebsd_pixel;
dsnm = [grpnm '/area_by_mtex'];
attr = io_attributes();
attr.add('units', [scan_unit, '^2']);
ret = h5w.nexus_write(dsnm, double(grains.area('2d')), attr);
dsnm = [grpnm '/indices_phase'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(grains.phaseId), attr); 
% 0 is boundary
% convenience, can be logically/topologically inferred from entry1/interfaces
dsnm = [grpnm '/boundary_contact'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint8(grains.isBoundary), attr);
% TODO write out as bitfield, currently happening via pynxtools-em
dsnm = [grpnm '/orientation_spread'];
attr = io_attributes();
attr.add( 'units', '°');
ret = h5w.nexus_write(dsnm, double(grains.GOS / degree), attr);
grpnm = [parent '/microstructure1/crystals/orientation'];
attr = io_attributes();
attr.add('NX_class', 'NXrotations');
ret = h5w.nexus_write_group(grpnm, attr);
% dsnm = [grpnm '/parameterization'];
% attr = io_attributes();
% ret = h5w.nexus_write(dsnm, 'quaternion', attr);
dsnm = [grpnm '/rotation_quaternion'];
attr = io_attributes();
quat = nan([4, length(grains)]);
quat(1,:) = grains.meanRotation.a';
quat(2,:) = grains.meanRotation.b';
quat(3,:) = grains.meanRotation.c';
quat(4,:) = grains.meanRotation.d';
ret = h5w.nexus_write(dsnm, double(quat), attr);
% per grains.meanOrientation cannot be called directly for EBSD data with
% multiple phases (see Forsterite example...)
% Your variable contains the phases: Forsterite, Enstatite
% However, you are executing a command that is only permitted for a single phase!
% contains the phases: Forsterite, Enstatite -phasefor nothing but Euler angles
% as a solution meanOrientation is collected in the loop that collects
% per boundary misorientation
clearvars quat;
disp(['Crystals: OK']);
% https://mtex-toolbox.github.io/GrainOrientationParameters.html
% gam = ebsd_orig.grainMean(ebsd_orig.KAM, grains);

%% interface facets which discretize the segments of the polygons
% which describe the crystallite and ROI boundar(ies) as polylines
% are not mandatory they can be interferred from topological analysis
% ideally for this the grains should be stored as a half-edge data
% structure instead of face, vertex lists

%% store crystal boundaries which can be homo (aka grain) or hetero (phase) boundaries/interfaces
% (not their facets as a boundary can be discretized with differing number of support points)
% interfaces are pairs of half-edges because an interface separates two crystals
% each interface is discretized using at least one so-called facet, i.e.
% typically much more facets (polyline segments or triangles exist than
% conceptual interfaces
% [val, idx] = max(grains.area('2d'));

%% polyline segment to interface patches
disp(['Interfaces ...']);
grpnm = [parent '/microstructure1/interfaces'];
attr = io_attributes();
attr.add('NX_class', 'NXobject');
ret = h5w.nexus_write_group(grpnm, attr);
% eventually of multiple such segments because the vertices from MTex
% represent on the one hand vertices at triple points and virtual
% vertices discretizing the facets of the Voronoi cells from which
% the individual regions are composed,
% group interface facets to grains via hashing min/max crystal id pair
dsnm = [grpnm '/number_of_interfaces'];
attr = io_attributes();
pairs = grains.boundary.grainId';
% look-up table, interface segments vs patches
% a patch is build from at least one but typically multiple segment(s)
segment_to_patch = uint64(min(pairs)) + uint64(2^32) * uint64(max(pairs));
clearvars pairs;
unique_interfaces = unique(segment_to_patch);
% reindex the interface patches
interface_lu_to_interface_idx = dictionary(unique_interfaces, 1:1:length(unique_interfaces));

indices_patch = int64(zeros([1, length(grains.boundary)])) - 1;
for i = 1:1:length(grains.boundary)
    lu_key = segment_to_patch(i);
    if isKey(interface_lu_to_interface_idx, lu_key)
        indices_patch(i) = interface_lu_to_interface_idx(lu_key);
    else
        disp([num2str(i) ', ' lu_key]);
        error(['Unable to find lu_key in interface_lu_to_interface_idx !']);
    end
end
if any(indices_patch < 0)
    error(['Indices patch are inconsistent !']);
end
% includes interfaces of crystals to the edge of the ROI / boundary
crystal_id_pair = uint32(zeros([2, length(unique_interfaces)]));
mx = unique_interfaces ./ uint64(2^32);
mi = unique_interfaces - (uint64(2^32) .* uint64(mx));
crystal_id_pair(1, :) = mi;
crystal_id_pair(2, :) = mx;
clearvars mi mx;
ret = h5w.nexus_write(dsnm, uint32(length(unique_interfaces)), attr);

grpnm = [parent '/microstructure1/cg_polyline'];
dsnm = [grpnm '/indices_interfaces'];
attr = io_attributes();
attr.add('use_these', [parent '/microstructure1/interfaces']);
ret = h5w.nexus_write(dsnm, uint32(indices_patch), attr);

grpnm = [parent '/microstructure1/interfaces'];
dsnm = [grpnm '/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
% 0 marks the virtual zero grain which specifies the boundary of the ROI !
dsnm = [grpnm '/indices_crystal'];
attr = io_attributes();
attr.add('use_these', [parent '/microstructure1/crystals']);
ret = h5w.nexus_write(dsnm, uint32(crystal_id_pair), attr);
% do not wonder why crystal_id_pair may include 0, it marks the
% discretization of the boundary of the ROI !
clearvars unique_interfaces;

disp(['Interfaces misorientation ...']);
% compute misorientation for interface patches (not individual segments)
% as all segments of the patch for 2d have the same misorientation
% boundary plane of course is a per segment quantity but this is stored
% already as we have vertex positions and first, last so also directions
% two-staged computation of per-interface misorientation
% a convenient call like bnd = grains.boundary.misorientation does not
% work because different phases and ROI boundaries need to be dealt with

% stage 1 get adjacent grains' meanOrientation for all unique surface patches
for i = 1:1:length(grains)
    % cannot just filter by grains with ROI edge contact as also these may have still boundaries with grains inside the ROI
    mean_orientation(i) = grains(i).meanOrientation;
end
mean_ori_quat = nan([4, length(mean_orientation)]);
mean_ori_quat(1, :) = mean_orientation.a;
mean_ori_quat(2, :) = mean_orientation.b;
mean_ori_quat(3, :) = mean_orientation.c;
mean_ori_quat(4, :) = mean_orientation.d;
grpnm = [parent '/microstructure1/crystals/orientation'];
dsnm = [grpnm '/orientation_quaternion'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, double(mean_ori_quat), attr);
clearvars i mean_ori_quat;

% stage 2 compute misorientation explicitly
% but do not for performance reasons here reassign these values
% back to each interface segment cuz there is typically at least one
% order of magnitude more segments than patches
% not reassigning them back is done only for performance optimization!
pairs = uint32(unique(grains.boundary.grainId, 'rows'));
j = 1;
% misori_euler_slow = nan([3, length(pairs)]);
% misori_angle_slow = nan([1, length(pairs)]);
for i = 1:1:length(pairs)
    % cannot just filter by grains with ROI edge contact as also these may have still boundaries with grains inside the ROI
    if all(pairs(i, :) > 0)  % no misorientation for boundary segments in contact with the edge
        mi = min(pairs(i, :));
        mx = max(pairs(i, :));
        % trg(j) = i;
        p(j) = mean_orientation(mi);
        q(j) = mean_orientation(mx);
        % misori_slow = inv(mean_orientation(mi)) * mean_orientation(mx);
        % misori_euler_slow(1, i) = misori_slow.phi1 / degree;
        % misori_euler_slow(2, i) = misori_slow.Phi / degree;
        % misori_euler_slow(3, i) = misori_slow.phi2 / degree;
        % misori_angle_slow(1, i) = misori_slow.angle / degree;
        lu_keys(j) = uint64(mi) + uint64(2^32) * uint64(mx);
        j = j + 1;
        % clearvars misori;
    end
end
misori_fast = inv(p) .* q;
clearvars pairs j i mi mx p q;
% misori = dictionary(lu_keys, inv(p) .* q);
% be careful only collection of misorientations for disjoint crystals!
% not stored in the order of the interfaces!
% using MTex here only to compare these misorientations!
misori_euler_fast = nan([3, length(lu_keys)]);
misori_angle_fast = nan([1, length(lu_keys)]);
misori_euler_fast(1, :) = misori_fast(1, :).phi1 ./ degree;
misori_euler_fast(2, :) = misori_fast(1, :).Phi ./ degree;
misori_euler_fast(3, :) = misori_fast(1, :).phi2 ./ degree;
misori_angle_fast(1, :) = misori_fast(1, :).angle ./ degree;
clearvars misori_fast;

grpnm = [parent '/microstructure1/interfaces/misorientation'];
attr = io_attributes();
attr.add('NX_class', 'NXcollection');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [grpnm '/misorientation_euler'];
attr = io_attributes();
attr.add('units', '°');
ret = h5w.nexus_write(dsnm, double(misori_euler_fast), attr);
dsnm = [grpnm '/misorientation_angle'];
attr = io_attributes();
attr.add('units', '°');
ret = h5w.nexus_write(dsnm, double(misori_angle_fast), attr);
dsnm = [grpnm '/min_max_lookup_key'];
attr = io_attributes();
attr.add('comment', 'Misorientation between disjoint crystals, hashing function uint64(mi) + uint64(2^32) * uint64(mx)');
ret = h5w.nexus_write(dsnm, uint64(lu_keys), attr);
clearvars misori_euler_fast misori_angle_fast;
disp(['Interface misorientation: OK']);

grpnm = [parent '/microstructure1/interfaces'];
dsnm = [grpnm '/indices_phase'];
attr = io_attributes();
% check that for each facet with the same interface_hash
% the phase_id pair is exactly the same!
phase_id_pair = int64(zeros(size(crystal_id_pair))) - 1;
% subtract 1 to mark all values as unknowns first so that one can
% check if all have been visited
mi = uint32(min(grains.boundary.phaseId'));
mx = uint32(max(grains.boundary.phaseId'));
for idx = 1:1:size(grains.boundary.phaseId, 1)
    % never zero unless 0 + (2^32 * 0) not possible by virtue of construction?
    lu_key = segment_to_patch(idx);
    interface_idx = interface_lu_to_interface_idx(lu_key);
    % mi = min(uint32(grains.boundary.phaseId(idx, :)));
    % mx = max(uint32(grains.boundary.phaseId(idx, :)));
    % in the case of mi == mx we have a homophase interface
    % in the case of any([mi, mx]) == 0 we have boundary contact
    % but the flag isBoundary is a cleaner way to query these cases
    % in all other cases we have heterophase interface
    if phase_id_pair(1, interface_idx) == -1 ...
            & phase_id_pair(2, interface_idx) == -1
        % set those that we have not visited
        phase_id_pair(1, interface_idx) = mi(idx);
        phase_id_pair(2, interface_idx) = mx(idx);
    else
        % those we have visited assure that we are still consistent
        if phase_id_pair(1, interface_idx) == mi(idx) ...
                & phase_id_pair(2, interface_idx) == mx(idx)
            continue;
        else
            error(['Resetting values in a phase_id_pair ' ...
                num2str(idx) ' is not allowed !']);
        end
    end
end
if min(min(phase_id_pair)) >= 0 & max(max(phase_id_pair)) < int64(2^32)
    phase_id_pair = uint32(phase_id_pair);
else
    error('At least one phase_id_pair value remained incorrectly -1 !');
end
% so the information e.g. phase_id_pair  (0, 2) means this interface
% is an interface between some crystallite_projections of phase 0 and phase 2
% phase 0 is notIndexed and used for representing the interface
ret = h5w.nexus_write(dsnm, phase_id_pair, attr);

% TODO::export indices_polylines segments
dsnm = [grpnm '/indices_polylines'];
attr = io_attributes();
attr.add('use_these', [parent '/microstructure1/cg_polyline']);
ret = h5w.nexus_write(dsnm, uint32(1:1:size(polylines, 2))', attr);
clearvars i idx interface_id interface_idx mi mx phase_id_pair crystal_id_pair;
disp(['Interfaces: OK']);

%% triple junctions
disp(['Triple junctions ...']);
grpnm = [parent '/microstructure1/triple_junctions'];
attr = io_attributes();
attr.add('NX_class', 'NXobject');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [grpnm '/number_of_junctions'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(size(grains.triplePoints.id, 1)), attr);
dsnm = [grpnm '/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
dsnm = [grpnm '/indices_crystal'];
attr = io_attributes();
attr.add('use_these', [parent '/microstructure1/crystals']);
ret = h5w.nexus_write(dsnm, uint32(grains.triplePoints.grainId)', attr);
dsnm = [grpnm '/indices_polyline'];
attr = io_attributes();
attr.add('use_these', [parent '/microstructure1/cg_polyline']);
ret = h5w.nexus_write(dsnm, uint32(grains.triplePoints.boundaryId)', attr);
dsnm = [grpnm '/indices_interface'];
% the adjoining interface, (also see above comment) not necessary
attr = io_attributes();
attr.add('use_these', [parent '/microstructure1/interfaces']);
% again subtract 1 to assure and allow a check that we have all visited and
% have all consistent
interface_ids = int64(zeros([3, size(grains.triplePoints.boundaryId, 1)]) - 1);
bnd_idxs = grains.triplePoints.boundaryId';
for idx = 1:1:size(bnd_idxs, 2)
    a_bnd_lu_key = segment_to_patch(bnd_idxs(1, idx));
    b_bnd_lu_key = segment_to_patch(bnd_idxs(2, idx));
    c_bnd_lu_key = segment_to_patch(bnd_idxs(3, idx));
    a_bnd = interface_lu_to_interface_idx(a_bnd_lu_key);
    b_bnd = interface_lu_to_interface_idx(b_bnd_lu_key);
    c_bnd = interface_lu_to_interface_idx(c_bnd_lu_key);
    if all(interface_ids(1:3, idx) == -1)
        interface_ids(1, idx) = a_bnd;
        interface_ids(2, idx) = b_bnd;
        interface_ids(3, idx) = c_bnd;
    else
        if interface_ids(1, idx) == a_bnd ...
                & interface_ids(2, idx) == b_bnd ...
                & interface_ids(3, idx) == c_bnd
            continue;
        else
            error(['At least one triple junction is incorrectly handled !']);
        end
    end
end
% check that no index remains -1
if min(min(interface_ids)) >= 0 & max(max(interface_ids)) < int64(2^32)
    % cast from int64 to uint32 is safe on both sides
    % only when both constraints are met !
    interface_ids = uint32(interface_ids);
else
    error(['At least on interface_id is incorrectly >= 2^32 !']);
end
clearvars idx a_bnd_lu_key b_bnd_lu_key c_bnd_lu_key a_bnd b_bnd c_bnd;
ret = h5w.nexus_write(dsnm, interface_ids, attr);
clearvars interface_ids hash_to_interface_id segment_to_patch ret;
disp(['Triple junctions: OK']);

dsnm = ['/entry1/profiling/microstructure_elapsed_time'];
ms_wall_clock = toc(ms_tic);
attr = io_attributes();
attr.add('units', 's');
h5w.nexus_write(dsnm, double(ms_wall_clock), attr);

disp('NeXus/HDF5 exporting of microstructure: OK');
status = logical(1);

end