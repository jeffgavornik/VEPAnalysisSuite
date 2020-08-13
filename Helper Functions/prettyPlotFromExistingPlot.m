function fig = prettyPlotFromExistingPlot(obj,replace,...
    scaleDims,scaleUnits,figureCreateArgs,axesSetArgs,bgColor)

% obj is either a figure or axes handle
% replace (optional) bool indicating whether the old figure should be closed
% scaleDims (optional) - specify the size of scale bars to render on the
%   figure.  Format [xScale yScale]
% scaleUnits (optional) - specify units for the scale bar labels.  
%   Format {xUnits yUnits} where units are strings
% 
%
% Example
%   fig = prettyPlotFromExistingPlot(2,false,[100 100],{'ms' '\muV'},...
%       {8.5,11},{'XLim',[0 1]});
%   This will duplicate figure 2 without replacement, will create a scale
%   bar with dims of 100x100 (ms x uV) on a figure with dimensions 8.5x11"
%   and an xLim of 0 to 1

fontsize = 14;
resizeForLegend = true;

if nargin == 0 || isempty(obj)
    obj = gcf;
end

if nargin < 2 || isempty(replace)
    replace = false;
end

if exist('bgColor','var') == 0 || isempty(bgColor)
    bgColor = [1 1 1]; % white background by default
end

% Identify the axis to take the plots from
switch get(obj,'type')
    case 'figure'
        fh = obj;
        ah = get(obj,'CurrentAxes');
    case 'axes'
        ah = obj;
        fh = get(ah,'Parent');
    otherwise
        error('prettyPlotFromExistingPlot: bad object type ''%s''',class(obj));
end

% Get the legend, if it exists
legh = findobj(fh,'Tag','legend');
if ~isempty(legh)
    createLegend = true;
else
    createLegend = false;
end

% Create a new figure and make it white
if exist('figureCreateArgs','var') && ~isempty(figureCreateArgs)
    fig = CreateSizedFigure(figureCreateArgs{:});
else
    fig = figure('Visible',fh.Visible);
end
fig.Position([3 4]) = fh.Position([3 4]); % maintain size
set(fig,'Color',bgColor,'InvertHardCopy','off');

% Create the new axes and copy all of the graphics objects

if createLegend
    hs = copyobj([ah,legh],fig);
    lh = hs(2);
    lh.AutoUpdate = 'off';
    ax = hs(1);
else
    ax = subplot(1,1,1);
    copyobj(get(ah,'Children'),ax);
end
axisSize = [get(ah,'XLim') get(ah,'YLim')];
set(ax,'Visible','off','XLim',axisSize([1 2]),'YLim',axisSize([3 4]));
if exist('axesSetArgs','var') && ~isempty(axesSetArgs)
    try
        set(ax,axesSetArgs{:});
    catch ME
        warning('prettyPlotFromExistingPlot set axis fail\n%s',...
            ME.getReport()); %#ok<WNTAG>
    end
end
userData.plotAxes = ax;

% Copy the legend and position in the upper-right corner
% Resize the axes so no overlap
if createLegend
    legPos = get(lh,'position');
    newPos = legPos;
    newPos(1) = 1 - newPos(3) - 0.05;
    newPos(2) = 1 - newPos(4) - 0.05;
    set(lh,'position',newPos,'edgecolor',bgColor,'color',bgColor);
    if resizeForLegend
        axPos = get(ax,'Position');
        axPos(3) = axPos(3) - newPos(3);
        set(ax,'Position',axPos);
    end
    userData.legendHandle = lh;
else
    userData.legendHandle = [];
end

% Render Scale below the plot in a new axes set
if exist('scaleDims','var') == 1 && ~isempty(scaleDims)
    % Render
    axesPos = get(ax,'Position');
    shiftedPos = axesPos - [0.025 0.03 0 0];
    ax = axes('Position',shiftedPos);
    scalePtsX = [0 0 scaleDims(1)] - -axisSize(1);
    scalePtsY = [scaleDims(2) 0 0] - abs(axisSize(3));
    plot(ax,scalePtsX,scalePtsY,'linewidth',2,'color','k');
    axis(ax,axisSize);
    set(ax,'Visible','off');
    % Label
    xRange = range(axisSize([1 2]));
    yRange = range(axisSize([3 4]));
    if exist('scaleUnits','var') == 0 || isempty(scaleUnits)
        scaleUnits = {'' ''};
    end
    if scaleDims(1) ~= 0
        xScaleLabel = sprintf('%s %s',num2str(scaleDims(1)),scaleUnits{1});
        text(scalePtsX(2) + 0.5*(scalePtsX(3)-scalePtsX(2)),axisSize(3)-yRange*0.025,...
            xScaleLabel,'HorizontalAlignment','center');
    end
    if scaleDims(2) ~= 0
        yScaleLabel = sprintf('%s %s',num2str(scaleDims(2)),scaleUnits{2});
        text(axisSize(1)-xRange*0.025,axisSize(3)+scaleDims(2)*0.5,...
            yScaleLabel,'rotation',90,'HorizontalAlignment','center');
    end
    userData.scaleHandle = ax;
else
    userData.scaleHandle = [];
end

% Render a title above the top-most plot in a new axes set
titleh = get(ah,'Title');
if ~isempty(titleh)
    axesTitle = get(titleh,'String');
    axesPos = get(ax,'Position');
    newPos = [axesPos(1) axesPos(2)+axesPos(4)+0.01 axesPos(3) 0.05];
    tax = axes('Position',newPos);
    text(0,0.5,axesTitle,...
        'HorizontalAlignment','left','fontsize',fontsize);
    set(tax,'Visible','off');
end
userData.titleHandle = titleh;

set(fig,'userdata',userData);
set(fig,'defaultLegendAutoUpdate','off');

if replace
    close(fh);
end

end