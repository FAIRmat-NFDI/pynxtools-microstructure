function status = nexus_write_ebsd_pf(ebsd_orig, fpath, parent, perform_io)
% Generate default PF plots recomputed for H5Web and write data to NeXus/HDF5 file

% ebsd_orig:
% fpath: path and filename of NeXus/HDF5 results file
% parent: parent HDF5 group below which to write
n_resolution = 0.01; % of PF plot

if ~perform_io
    return;
end
h5w = HdfFiveSeqHdl(fpath);

grpnm = [parent '/pf1'];
attr = io_attributes();
attr.add('NX_class', 'NXmicrostructure_pf');
h5w.nexus_write_group(grpnm, attr);

pf_id = 1;
phase_id = 0;
for phase_idx = 1:1:length(ebsd_orig.mineralList)
    % TODO: add a map for all those points not indexed
    if min(ebsd_orig.phaseMap) == -1
        n_count = sum(sum(ebsd_orig.phase == (phase_id - 1)));
    elseif min(ebsd_orig.phaseMap) == 0
        n_count = sum(sum(ebsd_orig.phase == phase_id));
    else
        error('ERROR: The phaseMap for this EBSD map uses an unexpected indexing!');
    end

    if ~strcmp(ebsd_orig.mineralList{phase_idx}, 'notIndexed') & n_count > 0

        cs = ebsd_orig.CSList{1 + phase_id};
        miller_set = Miller({0, 0, 1}, {1, -1, 0}, {1, 1, 1}, {2, 1, 0}, cs);
        % estimated specific polefigure from ebsd dataset
        % plotPDF(odf, miller_set);
        % colorbar

        for k = 1:1:length(miller_set)
            grpnm = [parent '/pf1/pf' num2str(pf_id)];
            attr = io_attributes();
            attr.add('NX_class', 'NXdata');
            attr.add('comment1', 'Pole figure recomputed from equally-named odf')
            attr.add('comment2', 'PF looks as for MTex xEast, zIntoPlane but X and Y each have different sign?');
            h5w.nexus_write_group(grpnm, attr);
            grpnm = [parent '/pf1/pf' num2str(pf_id) '/configuration'];
            attr = io_attributes();
            attr.add('NX_class', 'NXparameters');
            h5w.nexus_write_group(grpnm, attr);

            phase_name = ebsd_orig.mineralList{phase_idx};
            specimen_symmetry_point_group = 'triclinic';
            specimenSymmetry(specimen_symmetry_point_group);

            dsnm = [grpnm '/phase_name'];
            attr = io_attributes();
            h5w.nexus_write(dsnm, phase_name, attr);
            dsnm = [grpnm '/phase_id'];
            h5w.nexus_write(dsnm, uint32(phase_id), attr);
            dsnm = [grpnm '/crystal_symmetry_point_group'];
            h5w.nexus_write(dsnm, cs.pointGroup, attr);
            dsnm = [grpnm '/specimen_symmetry_point_group'];
            h5w.nexus_write(dsnm, specimen_symmetry_point_group, attr);
            kernel_hw = 10.*degree;
            kernel_reso = 2.5*degree;
            dsnm = [grpnm '/halfwidth'];
            attr = io_attributes();
            attr.add('units', 'degree');
            h5w.nexus_write(dsnm, double(kernel_hw / pi * 180.), attr);
            dsnm = [grpnm '/resolution'];
            attr = io_attributes();
            attr.add('units', 'degree');
            h5w.nexus_write(dsnm, double(kernel_reso / pi * 180.), attr);
            dsnm = [grpnm '/miller_indices'];
            attr = io_attributes();
            h5w.nexus_write(dsnm, ...
                ['{' num2str(miller_set(k).h) ...
                ', ' num2str(miller_set(k).k) ...
                ', ' num2str(miller_set(k).l) '}'], attr);

            % exemplar code for different type of default ODFs
            odf = calcDensity(ebsd_orig(phase_name).orientations, ...
                'halfwidth', kernel_hw, 'resolution', kernel_reso);

            pf_name = ['miller' num2str(k)];
            miller_indices = ['{' num2str(miller_set(k).h) ...
                ', ' num2str(miller_set(k).k) ...
                ', ' num2str(miller_set(k).l) '}'];

            pf = calcPDF(odf, miller_set(k));
            [intensity, maxima] = max(pf, 'numLocal', 10);
            % typical representation of polefigure is via S2Grid whose points are not
            % equally distributed though when projected into the equatorial plane
            % thus opposite approach for H5Web, sample a square and set
            % PF intensity for points outside unit circle to NaN
            % [-1.:n_resolution:+1.]^2
            X = +1.:-n_resolution:-1.;
            Y = +1.:-n_resolution:-1.;
            XYZ = zeros(3, length(X) * length(Y));
            for j = 1:1:length(Y)
                for i = 1:1:length(X)
                    idx = i + (j-1) * length(X);
                    XYZ(1, idx) = X(i);
                    XYZ(2, idx) = Y(j);
                end
            end

            % inverse stereographic projection
            % R^2 = X^2 + Y^2
            % (X,Y,0) -> (x,y,z) = (2X/(R^2 + 1), 2Y/(R^2 + 1), (R^2 - 1)/(R^2 + 1))
            % https://www.physicsforums.com/threads/inverse-of-the-stereographic-projection.108175/

            xyz = zeros(3, length(X) * length(Y));
            Rsqr = XYZ(1, :).^2 + XYZ(2, :).^2;
            xyz(1, :) = 2.*XYZ(1, :) ./ (Rsqr + 1);
            xyz(2, :) = 2.*XYZ(2, :) ./ (Rsqr + 1);
            xyz(3, :) = (Rsqr - 1) ./ (Rsqr + 1);
            vec = normalize(vector3d(xyz, 'antipodal'));
            intensity = eval(pf, vec); % vector3d(1, 0, 0, 'antipodal'));

            interp_values = nan([length(X), length(Y)]);
            for j = 1:1:length(Y)
                for i = 1:1:length(X)
                    idx = i + (j-1) * length(X);
                    if X(i)^2 + Y(j)^2 <= 1.
                        interp_values(i, j) = intensity(idx);
                    end
                end
            end

            grpnm = [parent '/pf1/pf' num2str(pf_id) '/pf_plot'];
            attr = io_attributes();
            attr.add('NX_class', 'NXdata');
            attr.add('signal', 'intensity');
            attr.add('axes', {'axis_y', 'axis_x'});
            attr.add('axis_x_indices', uint32(0));
            attr.add('axis_y_indices', uint32(1));
            h5w.nexus_write_group(grpnm, attr);

            dsnm = [grpnm '/title'];
            attr = io_attributes();
            h5w.nexus_write(dsnm, ...
                ['PF Miller ' miller_indices ' ' phase_name], attr);

            dsnm = [grpnm '/intensity'];
            attr = io_attributes();
            % ##MK::TODO single precision to reduce size for OASIS demo
            h5w.nexus_write(dsnm, single(interp_values), attr);

            dsnm = [grpnm '/axis_x'];
            attr = io_attributes();
            attr.add('long_name', 'x');
            h5w.nexus_write(dsnm, double(X), attr);

            dsnm = [grpnm '/axis_y'];
            attr = io_attributes();
            attr.add('long_name', 'y');
            h5w.nexus_write(dsnm, double(Y), attr);

            pf_id = pf_id + 1;
        end
    end
    phase_id = phase_id + 1;
end
disp('NeXus/HDF5 exporting of pole figures was successful');
status = true;
end