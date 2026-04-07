mtexdir = ['CHANGEME'];
addpath(mtexdir);
examples = ['var_nlt_utf',
        'var_nlp_utf',
        'var_spc_utf',
        'var_nlt_asc',
        'var_nlp_asc',
        'var_spc_asc',
        'fix_nlt_utf',
        'fix_nlp_utf',
        'fix_spc_utf',
        'fix_nlt_asc',
        'fix_nlp_asc',
        'fix_spc_asc'];
for i = 1:length(examples)
    string_formatting = examples(i,:);
    disp(string_formatting);

    fpath = [string_formatting '.nxs'];
    status = nexus_write_init(fpath);
    
    h5w = HdfFiveSeqHdl(fpath);
    dsnm = ['/' string_formatting];
    attr = io_attributes();
    attr.add('version', 'Matlab R2023b Update 7');
    ret = h5w.nexus_write(dsnm, 'Matlab', attr);  % string_formatting);
    % disp(uint16(char('Matlab')));
end
