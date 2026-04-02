function create_unload_script(outputDir, paths, opts)
%CREATE_UNLOAD_SCRIPT   Generate unload_package.m in the given directory.
%
% Args:
%   outputDir - Directory to write unload_package.m into
%   paths     - Cell array of paths to remove (relative to outputDir)
%   opts      - (Optional) Struct with fields:
%     .absolute - If true, paths are absolute (for editable installs)

if nargin < 3
    opts = struct();
end
useAbsolute = isfield(opts, 'absolute') && opts.absolute;

unloadFile = fullfile(outputDir, 'unload_package.m');
fid = fopen(unloadFile, 'w');
if fid == -1
    error('mip:fileError', 'Could not create unload_package.m');
end

fprintf(fid, 'function unload_package()\n');
fprintf(fid, '    %% Remove package directories from MATLAB path\n');

if useAbsolute
    for i = 1:length(paths)
        fprintf(fid, '    rmpath(''%s'');\n', paths{i});
    end
else
    fprintf(fid, '    pkg_dir = fileparts(mfilename(''fullpath''));\n');
    for i = 1:length(paths)
        if strcmp(paths{i}, '.')
            fprintf(fid, '    rmpath(pkg_dir);\n');
        else
            fprintf(fid, '    rmpath(fullfile(pkg_dir, ''%s''));\n', paths{i});
        end
    end
end

fprintf(fid, 'end\n');
fclose(fid);

end
