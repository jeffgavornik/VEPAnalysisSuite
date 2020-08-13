function set_all_properties(objectHandle,object_type,property_name,value,outputFlag)
% set_all_properties(fh,object_type,property,value)
%
% Function to set a single property value to all objects in a figure of a
% particular type
%
% Example: set_all_properties(fh,'line','linewidth',2); will set the width
% off all line objects in the figure to size 2
% 
% If object_type = 'ALL', will set property_name on all objects that have
% the named property
%
% To set just titles and axes labels, use:
%   set_all_properties(fh,'text','fontsize',fontsize)
% To set just axes tick labels, use:
%   set_all_properties(fh,'axes','fontsize',fontsize)
%
% Note: this function is recursive and will look for all graphics objects
% below the passed handle
%
% note: axes tick labels set by ah.fontsize, title set by
%         % ah.title.fontsize, axes labels by ah.xlabel.fontsize
%
% note: property_name matching is case sensitive

if nargin < 5
    outputFlag = false;
end

if ishandle(objectHandle)
    setProperty(objectHandle,property_name,value,object_type,outputFlag);
end

% Recursive function to set a property to a particular value for all
% graphics objects h or below
function setProperty(h,property,value,object_type,outputFlag)
props = get(h);
theType = get(h,'Type');
if outputFlag
    fprintf('%f: Type = %s',h,theType);
end
% Look to see if the property exist for the passed object handle
if isfield(props,property)
    if outputFlag
        fprintf(', %s is property',property);
    end
    if strcmpi(object_type,theType) || strcmpi('ALL',object_type)
        if outputFlag
            fprintf(', type match');
        end
        set(h,property,value);
    end
end
if outputFlag
    fprintf('\n');
end

% Call function on all children and subordinate objects
if isfield(props,'Children')
    kids = get(h,'Children');
    % Some subordinate objects are not contained in children, handle them
    % here
    if isfield(props,'Title')
        theTitle = get(h,'Title');
        if ishandle(theTitle) % titles are not always objects
            kids = [kids;theTitle];
        end
    end
    if isfield(props,'XLabel')
        kids = [kids;get(h,'XLabel')];
    end
    if isfield(props,'YLabel')
        kids = [kids;get(h,'YLabel')];
    end
    if isfield(props,'ZLabel')
        kids = [kids;get(h,'ZLabel')];
    end
    % Recurse
    for ii = 1:numel(kids)
        setProperty(kids(ii),property,value,object_type,outputFlag);
    end
end

