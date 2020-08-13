function handles = plotWithErrorBars(xData,yData,ah,varargin)

% If axes passed, use it.  Otherwise, create axes on a new figure
if ~exist('ah','var') || isempty(ah)
    fh = figure;
    ah = axes;
else
    if ~strcmp(get(ah,'type'),'axes')
        error('renderPSTH: ah not type "axes"');
    end
    fh = get(ah,'Parent');
end
holdOption = get(ah,'NextPlot');
set(ah,'NextPlot','add');

% See if data is packaged as a cell array
cellData = isa(yData,'cell');

% Check to make sure data dimensions match, try to fix if they don't
nPts = length(xData);
if cellData
    nY = numel(yData);
    if nY ~= nPts
        error('plotWithErrorBars: x and y data dimensions do not match');
    end
else
    [r,c] = size(yData);
    if c ~= nPts
        if r == nPts
            yData = yData';
            warning('plotWithErrorBars: transposing data')
        else
            error('plotWithErrorBars: x and y data dimensions do not match');
        end
    end
end

% Calculate mean and error values
% nPts = length(yData);
muVals = zeros(1,nPts);
errVals = zeros(1,nPts);
for iD = 1:nPts
    if cellData
        data = yData{iD};
    else
        data = yData(:,iD);
    end
    muVals(iD) = mean(data);
    errVals(iD) = std(data)/sqrt(length(data));
end

% Set default
if isempty(xData)
    xData = 1:nPts;
end

% Plot mean, match linewidth and color for the error bars
hMean = plot(ah,xData,muVals,varargin{:});
lineWidth = get(hMean,'linewidth');
color = get(hMean,'color');
hErr = zeros(1,nPts);
for iD = 1:nPts
    hErr(iD) = plot(xData(iD)*[1 1],muVals(iD)+errVals(iD)*[-1 1],...
        'linewidth',lineWidth,'color',color);
end

% Save handles for return
handles.fh = fh;
handles.ah = ah;
handles.hMean = hMean;
handles.hErr = hErr;
handles.mu = muVals;
handles.err = errVals;

% Restore Hold Option
set(ah,'NextPlot',holdOption);