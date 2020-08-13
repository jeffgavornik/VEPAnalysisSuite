function phs = addMarkerSymbols(target,xVals,yVals,color)
% Add triangles centered at xVals with top points at yVals
% If target is a figure handle, uses the current axes
% If target it an axes handle, uses that

if nargin < 2
    error('addMarkerSymbols: requires 2 inputs');
end

theType = get(target,'type');
switch theType
    case 'figure'
        ah = get(target,'CurrentAxes');
    case 'axes'
        ah = target;
    otherwise
        fprintf(2,'addMarkerSymbols: Invalid target type %s\n',theType);
        return
end

if ~exist('color','var') || isempty(color)
    color = [0 0 0]; % black by default
end

hold(ah,'on');

% Create the triangle primitive
xlims = get(ah,'XLim');
width = 0.025 * (xlims(2)-xlims(1));
ylims = get(ah,'YLim');
height = 0.025 * (ylims(2)-ylims(1));
symX = [0 width/2 width] - width/2;
symY = [0 height 0] - height;

% Draw the symbols
nSyms = length(xVals);

if ~exist('yVals','var') || isempty(yVals)
    yVals = (ylims(1) + 0.1 * (ylims(2)-ylims(1))) * ones(1,nSyms);
end
if length(yVals) ~= nSyms
    yVals = yVals(1) * ones(1,nSyms);
end
phs = zeros(1,length(xVals));
for iS = 1:nSyms
    ph = 	fill(xVals(iS)+symX,yVals(iS)+symY,color,'parent',ah);
    %     set(ph,'EdgeColor',color);
    set(ph,'LineStyle','none','clipping','off');
    phs(iS) = ph;
end

hold(ah,'off');