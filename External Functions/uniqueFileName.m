function [uniqueName,pathstr]= uniqueFileName(target,pathstr)
% Generates a unique filename, pathstr is optional
% Returns the fullfile version of the uniqueName which will or won't
% include the path depending on whether the target does
%
% JG 4/18/12
if nargin == 1
    [pathstr,name,ext] = fileparts(target);
    target = sprintf('%s%s',name,ext);
end
if ~isempty(pathstr) && exist(pathstr,'dir') ~= 7
    if ~mkdir(pathstr)
        warndlg(sprintf('Directory %s does not exist',pathstr));
        uniqueName = '';
        return;
    end
end 
count = 1;
uniqueName = fullfile(pathstr,target);
if ~isempty(pathstr)
    s = regexp(uniqueName,pathstr);
    if length(s) > 1
        uniqueName = uniqueName(s(end):end);
    end
end
while exist(uniqueName,'file') == 2
    [pathstr, name, ext] = fileparts(uniqueName);
    s = regexp(name,sprintf('_%03i',count));
    if ~isempty(s)
        name = name(1:s(end)-1);
        count = count + 1;
    end
    uniqueName = fullfile(pathstr,sprintf('%s_%03i%s',name,count,ext));
end
if nargout > 1
    [pathstr,name,ext] = fileparts(uniqueName);
    uniqueName = sprintf('%s%s',name,ext);
end