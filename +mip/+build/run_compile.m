function run_compile(sourceDir, compileScript)
%RUN_COMPILE   Run a compile script inside a package source directory.
%
% Args:
%   sourceDir     - Package source directory (cd target)
%   compileScript - Compile script path relative to sourceDir

scriptPath = fullfile(sourceDir, compileScript);
if ~exist(scriptPath, 'file')
    error('mip:compileScriptNotFound', ...
          'Compile script not found: %s', scriptPath);
end

originalDir = pwd;
try
    cd(sourceDir);
    fprintf('Running compile script: %s\n', compileScript);
    run(compileScript);
    fprintf('Compilation completed successfully.\n');
catch ME
    cd(originalDir);
    error('mip:compileFailed', ...
          'Compilation failed: %s', ME.message);
end
cd(originalDir);

end
