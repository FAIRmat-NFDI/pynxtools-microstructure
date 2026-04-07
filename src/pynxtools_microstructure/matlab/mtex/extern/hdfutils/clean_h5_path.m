function r = clean_h5_path( char_arr )
    if length(char_arr) > 1
        tmp1 = strrep(char_arr, ' ', '');
        tmp1 = strip(tmp1);
        while tmp1(end) == '/'
            tmp1 = strip(tmp1, 'right', '/');
        end
        tmp2 = '';
        for i = 1:length(tmp1)-1
            if tmp1(i:i+1) == '/'
                if tmp1(i+1) ~= '/'
                    tmp2 = [tmp2, tmp1(i)];
                end
            else
                tmp2 = [tmp2, tmp1(i)];
            end
        end
        tmp2 = [tmp2, tmp1(length(tmp1))];
        if tmp2(1) ~= '/'
            tmp2 = ['/', tmp2];
        end
        % disp(['Cleaned path reads __', tmp2, '__']);
        r = tmp2;
    else
        r = char_arr;
    end
end