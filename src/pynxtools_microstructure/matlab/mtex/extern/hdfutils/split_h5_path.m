function r = split_h5_path( char_arr )
    cell_arr = strsplit(char_arr, '/');
    cell_arr = cell_arr(2:end);
    % disp('Split path reads');
    % for i = 1:size(cell_arr, 2)
    %     disp(['__', cell_arr{i}, '__']);
    % end    
    r = cell_arr;
end