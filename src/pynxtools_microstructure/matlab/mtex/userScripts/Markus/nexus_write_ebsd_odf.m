function status = nexus_write_ebsd_odf(ebsd_orig, fpath, parent, perform_io)
% Generate default ODF plots for H5Web and write data to NeXus/HDF5 file

% ebsd_orig = ebsd_raw;
% fpath = ofpath;
% parent = '/entry1/roi1/ebsd/indexing';
% fpath: path and filename of NeXus/HDF5 results file
% parent: parent HDF5 group below which to write
if ~perform_io
    return;
end
odf_tic = tic;

h5w = HdfFiveSeqHdl(fpath);

kth_extrema_io = 1;
non_circular_io = 1;

phase_id = 0;
for phase_idx = 1:1:length(ebsd_orig.mineralList)
    if min(ebsd_orig.phaseMap) == -1
        n_count = sum(sum(ebsd_orig.phase == (phase_id - 1)));
    elseif min(ebsd_orig.phaseMap) == 0
        n_count = sum(sum(ebsd_orig.phase == phase_id));
    else
        error('ERROR: The phaseMap for this EBSD map uses an unexpected indexing!');
    end

    disp(['nexus_write_ebsd_odf ' num2str(phase_idx) '/' num2str(length(ebsd_orig.mineralList)) ' ' ebsd_orig.mineralList{phase_idx} ' phase_id ' num2str(phase_id) ' n_count ' num2str(n_count)]);

    if ~strcmp(ebsd_orig.mineralList{phase_idx}, 'notIndexed') & n_count > 0
        phase_name = ebsd_orig.mineralList{phase_idx};
        
        grpnm = [parent '/phase' num2str(phase_id) '/odf1'];
        attr = io_attributes();
        attr.add('NX_class', 'NXmicrostructure_odf');
        ret = h5w.nexus_write_group(grpnm, attr);
        
        grpnm = [parent '/phase' num2str(phase_id) '/odf1/configuration'];
        attr = io_attributes();
        attr.add('NX_class', 'NXparameters');
        ret = h5w.nexus_write_group(grpnm, attr);

        phase_name = ebsd_orig.mineralList{phase_idx};
        cs = ebsd_orig.CSList{phase_idx};
        specimen_symmetry_point_group = 'triclinic';
        ss = specimenSymmetry(specimen_symmetry_point_group);
        kernel_hw = 5. * degree;
        kernel_type = SO3DeLaValleePoussinKernel('halfwidth', kernel_hw);
        odf_reso = 2.5 * degree;

        dsnm = [grpnm '/crystal_symmetry_point_group'];
        attr = io_attributes();
        ret = h5w.nexus_write(dsnm, cs.pointGroup, attr);
        dsnm = [grpnm '/specimen_symmetry_point_group'];
        attr = io_attributes();
        ret = h5w.nexus_write(dsnm, specimen_symmetry_point_group, attr);
        dsnm = [grpnm '/kernel_name'];
        attr = io_attributes();
        ret = h5w.nexus_write(dsnm, 'de_la_vallee_poussin', attr);
        dsnm = [grpnm '/kernel_halfwidth'];
        attr = io_attributes();
        attr.add('units', 'degree');
        ret = h5w.nexus_write(dsnm, double(kernel_hw / pi * 180.), attr);
        dsnm = [grpnm '/resolution'];
        attr = io_attributes();
        attr.add('units', 'degree');
        ret = h5w.nexus_write(dsnm, double(odf_reso / pi * 180.), attr);

        % exemplar code for different types of ODFs
        odf = calcDensity(ebsd_orig(phase_name).orientations, ...
            'kernel', kernel_type, 'resolution', odf_reso);
        clearvars kernel_hw kernel_type odf_reso;
        % odf_naive = calcDensity(ori);
        % odf_psi = calcDensity(ori, 'kernel', SO3AbelPoissonKernel('halfwidth',10.*degree));
        % odf_fou = calcDensity(ori, 'order', 16);
        % for code parsing out used kernel check earlier commits

        % get SO3Grid
        if isa(odf, 'SO3Grid')
            S3G = getClass(varargin,'SO3Grid');
            S3G = orientation(S3G);
            d = Euler(S3G, odf);
        else
          [S3G,~,~,d] = regularSO3Grid(cs, ss, odf);
        end
        clearvars specimen_symmetry_point_group;

        % S3G is a grid on the sphere which we wish to evaluate for a phi2 
        % section plot using a custom grid
        % specifically e.g. regularly spaced phi_1/Phi/phi_2 positions
        % to get classical phi2 sections

        % evaluate
        ijk = 1;
        n_resolution = 1.0;  % discretization of H5Web ODF Euler space plot
        % compromise between achieving fast visualization and use small storage space
        % in several scientific applications one would sample finer
        n_e1 = ceil(360. / n_resolution);  % size(S3G, 1);  % phi_one, $\varphi_1$
        n_e2 = ceil(90. / n_resolution);  % size(S3G, 2);  % Phi, $\Phi$
        n_e3 = ceil(180. / n_resolution);  % size(S3G, 3);  % phi_two $\varphi_2$

        interp_pts = double(nan(3, n_e1*n_e2*n_e3));
        for k = 1:1:n_e3
            e3 = (0.5 + (k - 1)) * n_resolution;
            for j = 1:1:n_e2
                e2 = (0.5 + (j - 1)) * n_resolution;
                for i = 1:1:n_e1
                    e1 = (0.5 + (i - 1)) * n_resolution;
                    interp_pts(1, ijk) = e1;
                    interp_pts(2, ijk) = e2;
                    interp_pts(3, ijk) = e3;
                    ijk = ijk + 1;
                end
            end
        end
        here = orientation.byEuler(...
            interp_pts(1, :)*degree, ...
            interp_pts(2, :)*degree, ...
            interp_pts(3, :)*degree, cs, ss);
        naive_grid = eval(odf, here);
        clearvars i j k ijk e1 e2 e3;
        interp_values = double(reshape(naive_grid, [n_e1, n_e2, n_e3]));
        clearvars naive_grid S3G d;

        grpnm = [parent '/phase' num2str(phase_id) '/odf1/phi_two_plot'];
        attr = io_attributes();
        attr.add('NX_class', 'NXdata');
        attr.add('signal', 'intensity');
        attr.add('axes', {'varphi_two', 'capital_phi', 'varphi_one'});
        attr.add('varphi_one_indices', uint32(0));
        attr.add('capital_phi_indices', uint32(1));
        attr.add('varphi_two_indices', uint32(2));
        ret = h5w.nexus_write_group(grpnm, attr);
        dsnm = [grpnm '/title'];
        attr = io_attributes();
        ret = h5w.nexus_write(dsnm, ['ODF ' phase_name], attr);
        dsnm = [grpnm '/intensity'];
        attr = io_attributes();
        attr.add('comment', 'odf intensity normalized to random odf');
        % attr.add('long_name', 'ODF contour');
        % attr.add('CLASS', 'IMAGE');
        % attr.add('IMAGE_VERSION', '1.2');
        % attr.add('SUBCLASS_VERSION', int64(15));
        % TODO with single precision only half as much space
        % TODO should be sufficient for EBSD database demonstrator
        ret = h5w.nexus_write(dsnm, single(interp_values), attr);

        dsnm = [grpnm '/varphi_one'];
        attr = io_attributes();
        attr.add('units', 'degree');
        attr.add('long_name', ['phi_1 (degree)']);
        e1 = double((0.5 + ((1:1:n_e1) - 1)) * n_resolution);
        ret = h5w.nexus_write(dsnm, e1, attr);
        dsnm = [grpnm '/capital_phi'];
        attr = io_attributes();
        attr.add('units', 'degree');
        attr.add('long_name', ['Phi (degree)']);
        e2 = double((0.5 + ((1:1:n_e2) - 1)) * n_resolution);
        ret = h5w.nexus_write(dsnm, e2, attr);
        dsnm = [grpnm '/varphi_two'];
        attr = io_attributes();
        attr.add('units', 'degree');
        attr.add('long_name', ['phi_2 (degree)']);
        e3 = double((0.5 + ((1:1:n_e3) - 1)) * n_resolution);
        ret = h5w.nexus_write(dsnm, e3, attr);
        clearvars n_e1 n_e2 n_e3 interp_pts interp_values n_resolution;

        % ODF characteristics
        grpnm = [parent '/phase' num2str(phase_id) '/odf1/characteristics'];
        attr = io_attributes();
        attr.add('NX_class', 'NXprocess');
        ret = h5w.nexus_write_group(grpnm, attr);
        dsnm = [grpnm '/texture_index'];
        tindex = norm(odf)^2;
        attr = io_attributes();
        ret = h5w.nexus_write(dsnm, double(tindex), attr);
        clearvars tindex;

        if kth_extrema_io
            % entropy in the example
            % https://mtex-toolbox.github.io/ODFCharacteristics.html
            % reported was not a complex-value quantity but here it is
            % we do not report this here but would be possible via
            % storing a pair of double real, imaginary part in the HDF5 file
            % dsnm = [grpnm '/entropy'];
            % entrpy = entropy(odf);
            % attr = io_attributes();        
            % ret = h5w.nexus_write(dsnm, entrpy, attr);
            % clearvars entrpy;
    
            % classical component analysis as used for often alloys can use
            % e.g. fcc cube, goss, brass, copper
            % components = orientation.byEuler(...
            %     [ 0.,  0., 35.,  0.]*degree, ...
            %     [ 0., 45., 45., 35.]*degree, ...
            %     [ 0.,  0.,  0., 45.]*degree, cs, ss);
            % the same machinery as for here shown k-th extrema
            % locations of the three highest intensities of the ODF
            kth = 3;
            delta = 10.*degree;
            grpnm = [parent '/phase' num2str(phase_id) '/odf1/kth_extrema'];
            attr = io_attributes();
            attr.add('NX_class', 'NXprocess');
            ret = h5w.nexus_write_group(grpnm, attr);
            dsnm = [grpnm '/theta'];
            attr = io_attributes();
            attr.add('units', 'degree');
            ret = h5w.nexus_write(dsnm, double(delta / pi * 180.), attr);
            dsnm = [grpnm '/kth'];
            attr = io_attributes();
            ret = h5w.nexus_write(dsnm, uint32(kth), attr);
            dsnm = [grpnm '/location'];
            [intensity, maxima] = max(odf, 'numLocal', kth);
            disp(maxima);
            e1_e2_e3 = zeros(3, length(maxima));
            e1_e2_e3(1, :) = maxima(:).phi1 / degree;
            e1_e2_e3(2, :) = maxima(:).Phi / degree;
            e1_e2_e3(3, :) = maxima(:).phi2 / degree;
            attr = io_attributes();
            attr.add('units', 'degree');
            ret = h5w.nexus_write(dsnm, e1_e2_e3, attr);
            clearvars e1_e2_e3;
            dsnm = [grpnm '/intensity'];
            attr = io_attributes();
            attr.add('comment', 'odf intensity normalized to random odf');
            ret = h5w.nexus_write(dsnm, intensity, attr);
            clearvars intensity;
            % classical volume fraction with classical disorientation threshold
            dsnm = [grpnm '/volume_fraction'];
            V = zeros([1, length(maxima)]);
            for i = 1:1:length(maxima)
                V(i) = volume(odf, maxima(i), delta);  % fraction * 100.; % in percent
            end
            % modernized normalization of the volume fraction
            % V = volume(odf, components, delta) ./ ...
            %    volume(uniformODF(odf.CS), double(components), delta);
            attr = io_attributes();
            attr.add('comment1', 'NX_DIMENSIONLESS');
            attr.add('comment2', 'Components may overlap with the search region defined by theta !');
            attr.add('comment3', 'Therefore, volume fractions may not add up to 1. !');
            ret = h5w.nexus_write(dsnm, double(V), attr);
            clearvars kth delta maxima V;
        end

        if non_circular_io
            % modern analysis of non circular components that are close
            grpnm = [parent '/phase' num2str(phase_id) '/odf1/noncircular'];
            attr = io_attributes();
            attr.add('NX_class', 'NXprocess');
            ret = h5w.nexus_write_group(grpnm, attr);
            dsnm = [grpnm '/location'];
            [ori_nc, vol_nc] = calcComponents(odf);
            e1_e2_e3 = zeros(3, length(ori_nc));
            e1_e2_e3(1, :) = ori_nc(:).phi1 / degree;
            e1_e2_e3(2, :) = ori_nc(:).Phi / degree;
            e1_e2_e3(3, :) = ori_nc(:).phi2 / degree;
            attr = io_attributes();
            attr.add('units', 'degree');
            ret = h5w.nexus_write(dsnm, e1_e2_e3, attr);
            dsnm = [grpnm '/volume_fraction'];
            attr = io_attributes();
            attr.add('comment1', 'NX_DIMENSIONLESS');
            attr.add('comment2', 'Components may overlap with the search region defined by theta !');
            attr.add('comment3', 'Therefore, volume fractions may not add up to 1. !');
            ret = h5w.nexus_write(dsnm, vol_nc, attr);  
            clearvars ori_nc vol_nc e1_e2_e3;
        end
    end

    phase_id = phase_id + 1;
end
dsnm = ['/entry1/profiling/odf_elapsed_time'];
odf_wall_clock = toc(odf_tic);
attr = io_attributes();
attr.add('units', 's');
h5w.nexus_write(dsnm, double(odf_wall_clock), attr);

disp('NeXus/HDF5 exporting of ODF: OK');
status = logical(1);

end