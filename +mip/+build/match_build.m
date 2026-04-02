function [buildEntry, effectiveArch] = match_build(mipConfig, architecture)
%MATCH_BUILD   Find the first matching build entry for an architecture.
%
% Args:
%   mipConfig    - Struct from read_mip_yaml (must have .builds field)
%   architecture - (Optional) Architecture string. Default: mip.arch()
%
% Returns:
%   buildEntry    - The matched build struct from the builds array
%   effectiveArch - The effective architecture string ('any' or specific)

if nargin < 2 || isempty(architecture)
    architecture = mip.arch();
end

builds = mipConfig.builds;
if isempty(builds)
    error('mip:noBuild', 'No builds defined in mip.yaml');
end

% Normalize to cell array
if ~iscell(builds)
    builds = num2cell(builds);
end

for i = 1:length(builds)
    b = builds{i};
    archs = b.architectures;
    if ~iscell(archs)
        archs = {archs};
    end

    if ismember(architecture, archs)
        buildEntry = b;
        effectiveArch = architecture;
        return;
    end

    if ismember('any', archs)
        buildEntry = b;
        effectiveArch = 'any';
        return;
    end
end

error('mip:noMatchingBuild', ...
      'No build in mip.yaml matches architecture "%s"', architecture);

end
