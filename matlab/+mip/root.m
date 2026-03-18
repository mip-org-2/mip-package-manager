function root = root()
%ROOT   Get the mip root directory path.
%   ROOT() returns the path to the mip root directory by determining where
%   this package is installed. Assumes the layout:
%     <root>/packages/mip/mip/+mip/root.m

% Navigate up from this file's location:
%   +mip/root -> +mip -> mip (source) -> mip (package) -> packages -> root
this_dir = fileparts(mfilename('fullpath'));   % .../+mip
source_dir = fileparts(this_dir);             % .../mip/mip
package_dir = fileparts(source_dir);          % .../packages/mip
packages_dir = fileparts(package_dir);        % .../packages
root = fileparts(packages_dir);               % .../root

end
