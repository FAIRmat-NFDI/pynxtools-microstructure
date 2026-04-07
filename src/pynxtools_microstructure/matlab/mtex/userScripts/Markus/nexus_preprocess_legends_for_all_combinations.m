clear; clc;
% proj_vector = [vector3d.X, vector3d.Y, vector3d.Z];
% proj_name = ['x', 'y', 'z'];
point_groups = { ...
    '1', '-1', ...
    '2', 'm', '2/m', '222', 'mm2', 'mmm', ...
    '4', '-4', '4/m', '422', '4mm', '-42m', '4/mmm', ...
    '3', '-3', '32', '3m', '-3m', ...
    '6', '-6', '6/m', '622', '6mm', '-6m2', '6/mmm', ...
    '23', 'm-3', '432', '-43m', 'm-3m' };
ipf_lgd_mtx_dct = containers.Map();
ipf_lgd_tsl_dct = containers.Map();
for cs = 1:1:length(point_groups)
    pg = point_groups{cs};
    disp(pg);
    for prj = 1:1:1 % 3      
        ipf_key_mtx = ipfColorKey(crystalSymmetry(pg));
       
        figure('visible','off');
        plot(ipf_key_mtx);
        if cs < 10
            prefix = '0';
        else
            prefix = '';
        end
        png_fnm = ['temporary_mtx_' prefix num2str(cs) '.png'];  % '_' num2str(proj_idx) '.png'];
        exportgraphics(gcf, png_fnm, 'Resolution', 300);
        close all hidden;
        % ... framegrab this image to get the pixel color values (no alpha)
        im = imread(png_fnm);
        % delete(png_fnm);
        % remove the intermediately created figure
        sz = size(im);
        low_level = uint8(zeros(fliplr(sz)));
        % TODO::this must not be y-flipped !
        for x = 1:sz(2)
            for y = 1:sz(1)
                idx = y + (x - 1) * sz(1);
                low_level(:, x, y) = im(y, x, :);
            end
        end
        ipf_lgd_mtx_dct(pg) = low_level;
        clearvars -except point_groups ipf_lgd_mtx_dct ipf_lgd_tsl_dct cs pg prj;

        ipf_key_tsl = ipfTSLKey(crystalSymmetry(pg));       
        figure('visible','off');
        plot(ipf_key_tsl);
        if cs < 10
            prefix = '0';
        else
            prefix = '';
        end
        png_fnm = ['temporary_tsl_' prefix num2str(cs) '.png'];  % '_' num2str(proj_idx) '.png'];
        exportgraphics(gcf, png_fnm, 'Resolution', 300);
        close all hidden;
        im = imread(png_fnm);
        % delete(png_fnm);
        sz = size(im);
        low_level = uint8(zeros(fliplr(sz)));
        % TODO::this must not be y-flipped !
        for x = 1:sz(2)
            for y = 1:sz(1)
                idx = y + (x - 1) * sz(1);
                low_level(:, x, y) = im(y, x, :);
            end
        end
        ipf_lgd_tsl_dct(pg) = low_level;
        clearvars -except point_groups ipf_lgd_mtx_dct ipf_lgd_tsl_dct cs pg prj;
    end
end
clearvars pg cs prj;
save('ipf_lgds.mat');
