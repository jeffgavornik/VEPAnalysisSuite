function [ah,phs] = plotFamilyOfLines(vals1,vals2,xLabels,target,color,xVals)

if nargin < 2
    error('plotFamilyOfLines: requires 2 inputs');
end

if numel(vals1) ~= numel(vals2)
    error('plotFamilyOfLines: vals1 and vals2 must have the same number of elements');
end

if ~exist('target','var') || isempty(target)
    target = figure;
end
theType = get(target,'type');
switch theType
    case 'figure'
        ah = get(target,'CurrentAxes');
        if isempty(ah)
            ah = axes;
            set(ah,'XTick',[],'XTickLabel','');
        end
    case 'axes'
        ah = target;
    otherwise
        fprintf(2,'plotFamilyOfLines: Invalid target type %s\n',theType);
        return
end
if ~exist('color','var') || isempty(color)
    color = [0 0 1]; % blue by default
end

set(ah,'NextPlot','add','FontSize',14);

% Draw the family of lines
nVals = numel(vals1);

if ~exist('xVals','var') || isempty(xVals)
    xlims = get(ah,'XLim');
    xVals = [1 2] * (xlims(2)-xlims(1))/3;
end
% set(ah,'XLimMode','manual')

phs = zeros(1,nVals+1);
for iV = 1:nVals
    yVals = [vals1(iV) vals2(iV)];
    ph = plot(ah,xVals,yVals,'-o');
    set(ph,'color',color);
    phs(iV) = ph;
end
phs(end) = plot(ah,xVals,[mean(vals1) mean(vals2)],'k-o','linewidth',2);

% Set the x limits based on existing data
objs = findobj(ah,'type','line');
xData = cell2mat(get(objs,'xdata'));
xMin = min(xData(:));
xMax = max(xData(:));

xlims = get(ah,'xlim');
xlim([-1 1]*range(xlims)/2 + [xMin xMax]);

% Apply x labels
if exist('xLabels','var') && ~isempty(xLabels)
    %oldTicks = get(ah,'xTick');
    %oldLabels = get(ah,'XTickLabel');
    %newTicks = [oldTicks xVals];
    %newLabels = [oldLabels xLabels'];
    %set(ah,'xtick',newTicks,'xticklabel',newLabels);
    set(ah,'xtick',xVals,'xticklabel',xLabels);
    xlim(ah,xVals .* [0.75 1.25])
end
