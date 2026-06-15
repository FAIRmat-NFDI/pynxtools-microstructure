function host_info = nexus_nomad_get_host_info()
% model, CPU model/brand string
% ostype, operating system type
% architecture, CPU architecture (x86, amd64, etc.)
% max_threads, number of logical CPU threads

host_info = struct('model', '', 'ostype', '', 'architecture', '', 'max_threads', 0);

% Detect OS
if ispc
    osType = 'Windows';
elseif ismac
    osType = 'macOS';
elseif isunix
    osType = 'Linux';
else
    osType = 'unknown';
end
host_info.ostype = osType;

% --- CPU model / brand ---
switch osType
    case 'Windows'
        [status, cmdout] = system('wmic cpu get Name');
        if status == 0
            lines = strsplit(strtrim(cmdout), '\n');
            if numel(lines) > 1
                host_info.model = strtrim(lines{2});
            else
                host_info.model = 'unknown';
            end
        else
            host_info.model = 'unknown';
        end
    case 'Linux'
        [status, cmdout] = system('lscpu | grep "Model name"');
        if status == 0
            tokens = strsplit(cmdout, ':');
            if numel(tokens) > 1
                host_info.model = strtrim(tokens{2});
            else
                host_info.model = 'unknown';
            end
        else
            host_info.model = 'unknown';
        end
    case 'macOS'
        [status, cmdout] = system('sysctl -n machdep.cpu.brand_string');
        if status == 0
            host_info.model = strtrim(cmdout);
        else
            host_info.model = 'unknown';
        end
    otherwise
        host_info.model = 'unknown';
end

% --- CPU architecture ---
host_info.architecture = char(java.lang.System.getProperty('os.arch'));

% --- Number of threads ---
try
    host_info.max_threads = feature('numcores');  % physical/logical cores
catch
    host_info.max_threads = maxNumCompThreads;    % fallback
end
end
