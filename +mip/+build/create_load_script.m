function create_load_script(outputDir, paths, opts)
%CREATE_LOAD_SCRIPT   Generate load_package.m in the given directory.
%
% Args:
%   outputDir - Directory to write load_package.m into
%   paths     - Cell array of paths to add (relative to outputDir)
%   opts      - (Optional) Struct with fields:
%     .absolute - If true, paths are absolute (for editable installs)

if nargin < 3
    opts = struct();
end
useAbsolute = isfield(opts, 'absolute') && opts.absolute;

loadFile = fullfile(outputDir, 'load_package.m');
fid = fopen(loadFile, 'w');
if fid == -1
    error('mip:fileError', 'Could not create load_package.m');
end

fprintf(fid, 'function load_package()\n');
fprintf(fid, '    %% Add package directories to MATLAB path\n');

if useAbsolute
    for i = 1:length(paths)
        fprintf(fid, '    addpath(''%s'');\n', paths{i});
    end
else
    fprintf(fid, '    pkg_dir = fileparts(mfilename(''fullpath''));\n');
    for i = 1:length(paths)
        if strcmp(paths{i}, '.')
            fprintf(fid, '    addpath(pkg_dir);\n');
        else
            fprintf(fid, '    addpath(fullfile(pkg_dir, ''%s''));\n', paths{i});
        end
    end
end

fprintf(fid, 'end\n');
fclose(fid);

end
