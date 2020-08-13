function varargout = VDOTraceViewer(varargin)

% Inhibit mlint messages
%#ok<*INUSL,*INUSD,*DEFNU,*NASGU>

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @VEPDataObjectViewer_OpeningFcn, ...
    'gui_OutputFcn',  @VEPDataObjectViewer_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end


% --- Executes just before VEPDataObjectViewer is made visible.
function VEPDataObjectViewer_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for VEPDataObjectViewer
handles.output = hObject;

% Redirect  close request function
set(handles.figure1,'CloseRequestFcn',...   
    @(hObject,eventdata)closereq_Callback(hObject));

% Setup to control stimulus selection using a slider
if verLessThan('matlab', '7.11') % R2010b
    handles.slideListener = handle.listener(handles.stimSlide,...
        'ActionEvent',@stimSlide_listener_callBack);
else
    handles.slideListener = addlistener(handles.stimSlide,...
        'ContinuousValueChange',@stimSlide_listener_callBack);
end

% Set data export selection callback
set(handles.exportCtrlPanel,'SelectionChangeFcn',...
    @(src,event)exportCtrlPanel_Callback(src,event,guidata(src)));

% Create a dictionary to hold application data
appDataDict = containers.Map;
setappdata(hObject,'appDataDict',appDataDict);

% Create a management object to keep track of plots
managerObj = VEPPlotManagerClass;
setappdata(hObject,'managerObj',managerObj);

% Create variables that will be used for data selection
appDataDict('animal') = [];
appDataDict('condition') = [];
appDataDict('stim') = [];

% Setup for Animal-Session-Stim data selection
appDataDict('srcChangeHandles') = [handles.animalTxt handles.sessionTxt ...
    handles.animalMenu handles.conditionMenu handles.CH2axes];

% Create dataSpecifierObjects to retrieve keys and VEP traces
handles.kidKeyTemplate = getDataSpecifierTemplate('kidKeys');
handles.VEPTraceTemplate = getDataSpecifierTemplate('VEPTrace');
handles.VEPScoreTemplate = getDataSpecifierTemplate('VEPscore');
handles.channelsTemplate = getDataSpecifierTemplate('channelKeys');
handles.validTracesTemplate = getDataSpecifierTemplate('ValidTraces');

% Create the working plot handles - these will show current selection data
handles.CH1_workingPlot = plot(handles.CH1axes,[0 1],[0 1],...
    'color','k','Visible','off','linewidth',2);
handles.CH2_workingPlot = plot(handles.CH2axes,[0 1],[0 1],...
    'color','k','Visible','off','linewidth',2);

% Set default axes  and line properties
appDataDict('ylim') = [-500 500];
%appDataDict('xlim') = [0 0.4];
%xlabel(handles.CH1axes,'t (ms)','fontsize',12,'fontweight','bold');
ylabel(handles.CH1axes,'V (\muV)','fontsize',12,'fontweight','bold');
set(handles.CH1axes,'YLim',appDataDict('ylim'));
% set(handles.CH1axes,'XLim',appDataDict('xlim'));
% xlabel(handles.CH2axes,'t (ms)','fontsize',12,'fontweight','bold');
% ylabel(handles.CH2axes,'V (\muV)','fontsize',12,'fontweight','bold');
set(handles.CH2axes,'YLim',appDataDict('ylim'));
% set(handles.CH2axes,'XLim',appDataDict('xlim'));

% Setup plots to show scoring data on the working plots
handles.CH1ScoreInd = VEPScoringIndicatorClass(handles.CH1_workingPlot);
handles.CH1ScoreInd.setVisible('on');
handles.CH2ScoreInd = VEPScoringIndicatorClass(handles.CH2_workingPlot);
handles.CH2ScoreInd.setVisible('on');

% By default, show the scores
appDataDict('scoringTickVisibility') = 'on';

% Setup to show all valid traces
setappdata(handles.CH1_workingPlot,'Ch1ConstituentTraces',[]);
setappdata(handles.CH2_workingPlot,'Ch2ConstituentTraces',[]);

% Setup for data export
handles.exportButtons = [handles.ch1ExportButton handles.ch2ExportButton];
handles.dataExportHandles = [handles.exportPendingCheckbox ...
    handles.exportDataButton handles.cancelExportButton];
evntData.NewValue = handles.figureButton;
exportCtrlPanel_Callback([],evntData,handles);
%setupForFigureExport(handles);

handles.CH1Text = text(0.75,0.85,'tmp',...
    'Units','Normalized',...
    'Parent',handles.CH1axes,...
    'Visible','off',...
    'Interpreter','LaTeX',...
    'FontName','Helvetica',...
    'Fontsize',14);

handles.CH2Text = text(0.75,0.85,'tmp',...
    'Units','Normalized',...
    'Parent',handles.CH2axes,...
    'Visible','off',...
    'Interpreter','LaTeX',...
    'FontName','Helvetica',...
    'Fontsize',14);

handles.dataSpecificPlotUpdate = @plotVEPScoring;

% Update handles structure
guidata(hObject, handles);

% Include manual scoring functionality
setupForManualScoring(hObject);
enableScoring(handles,false);

% If a VEPDataObject was passed, add it to the app data
if numel(varargin) > 0
    if isa(varargin{1},'VEPDataClass')
        try
            associateVEPDataObject(hObject,varargin{1});
        catch ME
            
        end
    else
        error('VEPDataObjectViewer only works with VEPDataClass objects');
    end
end

end

function associateVEPDataObject(hObject,vdo)
handles = guidata(hObject);
handles.vdo = vdo;
% add a listener for update and close events
handles.updateListener = addlistener(vdo,'UpdateViewers',...
    @(src,event)vdoUpdate_Callback(hObject));
handles.closeListener = addlistener(vdo,'CloseViewers',...
    @(src,eventdata)closereq_Callback(hObject));
guidata(hObject,handles);
vdoUpdate_Callback(hObject);
end

function closereq_Callback(hObject)
handles = guidata(hObject);
if isfield(handles,'updateListener')
    delete(handles.updateListener);
end
if isfield(handles,'closeListener')
    delete(handles.closeListener);
end
delete(getappdata(handles.figure1,'ScoreChangedListeners'));
delete(handles.figure1);
end

function varargout = VEPDataObjectViewer_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;
end

% GUI Element Create Functions --------------------------------------------
% -------------------------------------------------------------------------

function animalMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function conditionMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function stimMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function exportMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function channelMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function stimSlide_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
end

function legendBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% GUI Menu Callbacks ------------------------------------------------------
% -------------------------------------------------------------------------

function PrintMenuItem_Callback(hObject, eventdata, handles)
printdlg(handles.figure1)
end


% GUI Element Callbacks ---------------------------------------------------
% -------------------------------------------------------------------------

% Load in the animals and make default selection
function vdoUpdate_Callback(hObject)
handles = guidata(hObject);
% Get the current animal selection value
oldAnimalKeys = cellstr(get(handles.animalMenu,'String'));
oldAnimalKey = oldAnimalKeys{get(handles.animalMenu,'Value')};
% Get the animal keys from the VEPDataObject
animalKeys = handles.vdo.getAnimalKeys;
set(handles.animalMenu,'String',animalKeys);
% If the previously selected animal exists, use it.
% If not, use the first animal as the default selection
animalIndex = strcmp(animalKeys,oldAnimalKey);
if sum(animalIndex)
    set(handles.animalMenu,'Value',find(animalIndex == 1));
else
    set(handles.animalMenu,'Value',1);
end
animalMenu_Callback(handles.animalMenu,[],handles);
end

% Select the Animal
function animalMenu_Callback(hObject, eventdata, handles)

% Get the current stimulus selection value
oldConditionKeys = cellstr(get(handles.conditionMenu,'String'));
oldConditionKey = oldConditionKeys{get(handles.conditionMenu,'Value')};

% Populate condition menu with conditions for the selected animal
animalKeys = cellstr(get(hObject,'String'));
animalKey = animalKeys{get(hObject,'Value')};
handles.kidKeyTemplate.resetDataPath();
handles.kidKeyTemplate.setHierarchyLevel(1,animalKey);
handles.VEPTraceTemplate.resetDataPath();
handles.VEPTraceTemplate.setHierarchyLevel(1,animalKey);
handles.VEPScoreTemplate.resetDataPath();
handles.VEPScoreTemplate.setHierarchyLevel(1,animalKey);
handles.channelsTemplate.resetDataPath();
handles.channelsTemplate.setHierarchyLevel(1,animalKey);
handles.validTracesTemplate.resetDataPath();
handles.validTracesTemplate.setHierarchyLevel(1,animalKey);
conditionKeys = handles.vdo.getData(handles.kidKeyTemplate);
set(handles.conditionMenu,'String',conditionKeys);
appDataDict = getappdata(handles.figure1,'appDataDict');
appDataDict('animalKey') = animalKey;

% If the previously selected condition exists for the new animal, use it.
% If not, use the first condition as the default selection
condIndex = strcmp(conditionKeys,oldConditionKey);
if sum(condIndex)
    set(handles.conditionMenu,'Value',find(condIndex == 1));
else
    set(handles.conditionMenu,'Value',1);
end
conditionMenu_Callback(handles.conditionMenu,[],handles);
end

% Select the condition
function conditionMenu_Callback(hObject, eventdata, handles)
strContents = cellstr(get(hObject,'String'));

% Get the current stimulus selection value
oldStimKeys = cellstr(get(handles.stimMenu,'String'));
oldStimKey = oldStimKeys{get(handles.stimMenu,'Value')};

% Populate condition menu with conditions for the selected animal
conditionKey = strContents{get(hObject,'Value')};
handles.kidKeyTemplate.setHierarchyLevel(2,conditionKey);
handles.VEPTraceTemplate.setHierarchyLevel(2,conditionKey);
handles.VEPScoreTemplate.setHierarchyLevel(2,conditionKey);
handles.channelsTemplate.setHierarchyLevel(2,conditionKey);
handles.validTracesTemplate.setHierarchyLevel(2,conditionKey);
stimKeys = handles.vdo.getData(handles.kidKeyTemplate);
set(handles.stimMenu,'String',stimKeys)
appDataDict = getappdata(handles.figure1,'appDataDict');
appDataDict('sessionKey') = conditionKey;

% If the previously selected stim exists for the new animal, use it.
% If not, use the first stim as the default selection
stimIndex = strcmp(stimKeys,oldStimKey);
if sum(stimIndex)
    selValue = find(stimIndex == 1);
else
    selValue = 1;
end
set(handles.stimMenu,'Value',selValue);

% Setup the silder based on the current stimulus values
nStims = length(stimKeys);

if nStims == 1
    minVal = 0.9;
    sliderStepValues = [1 1];
else
    minVal = 1;
    sliderStepValues = [1/(nStims-1) 1/(nStims-1)];
end
if min(sliderStepValues) < 0
    return;
end
set(handles.stimSlide,'Min',minVal,'Max',nStims,...
    'Value',selValue,'SliderStep',sliderStepValues);
stimMenu_Callback(handles.stimMenu,[],handles); % make default selection
end

% Select the stimulus
function stimMenu_Callback(hObject, eventdata, handles)

% GUI Glue
if hObject ~= handles.stimMenu
    set(handles.stimMenu,'Value',eventdata);
else
    value = get(hObject,'Value');
    set(handles.stimSlide,'Value',value);
    handles.oldIndex = value;
    guidata(hObject,handles);
end

strContents = cellstr(get(handles.stimMenu,'String'));
stimKey = strContents{get(handles.stimMenu,'Value')};
handles.VEPTraceTemplate.setHierarchyLevel(3,stimKey);
handles.VEPScoreTemplate.setHierarchyLevel(3,stimKey);
handles.channelsTemplate.setHierarchyLevel(3,stimKey);
handles.validTracesTemplate.setHierarchyLevel(3,stimKey);
appDataDict = getappdata(handles.figure1,'appDataDict');
appDataDict('stimKey') = stimKey;

% Make default channel selections
chSelMenu_Callback([],[],handles); 

% Draw the plot in CH1 and CH2 axes.
updatePlots(handles.figure1,eventdata,handles)
end

% Select the channel to display on each plot
function chSelMenu_Callback(hObject, eventdata, handles)
appDataDict = getappdata(handles.figure1,'appDataDict');
if isempty(hObject)
    % Programatic call following stim selection
    % Get the channel keys from the current stim selection
    channelKeys = handles.vdo.getData(handles.channelsTemplate);
    appDataDict('channelKeys') = channelKeys;
    % Get the current channel keys from the GUI and, if they are not in the
    % list of channel keys, add and select them
    % Channel 1
    strContents = cellstr(get(handles.ch1SelMenu,'String'));
    chKey = strContents{get(handles.ch1SelMenu,'Value')};
    % iCh = strmatch(chKey,channelKeys);
    iCh = find(strcmp(chKey,channelKeys));
    if isempty(iCh)
        newKeys = channelKeys;
        iCh = 1;
    else
        newKeys = channelKeys;
    end
    set(handles.ch1SelMenu,'String',newKeys,'Value',iCh);
    % Channel 2
    strContents = cellstr(get(handles.ch2SelMenu,'String'));
    chKey = strContents{get(handles.ch2SelMenu,'Value')};
    % iCh = strmatch(chKey,channelKeys);
    iCh = find(strcmp(chKey,channelKeys));
    if isempty(iCh)
        newKeys = channelKeys;
        iCh = length(channelKeys);
    else
        newKeys = channelKeys;
    end
    set(handles.ch2SelMenu,'String',newKeys,'Value',iCh);
else
    % This code will get rid of invalid string values if any exist
    strContents = cellstr(get(hObject,'String'));
    chKey = strContents{get(hObject,'Value')};
    channelKeys = appDataDict('channelKeys');
    % iCh = strmatch(chKey,channelKeys);
    iCh = find(strcmp(chKey,channelKeys));
    if isempty(iCh)
        iCh = 1;
    end
    set(hObject,'String',channelKeys,'Value',iCh);
    updatePlots(handles.figure1,eventdata,handles)
end

end

% Called by slider movement evoked 'ActionEvent' listener notification
function stimSlide_listener_callBack(hObject, eventData)
index = round(get(hObject,'Value'));
handles = guidata(hObject);
if index ~= handles.oldIndex
    handles.oldIndex = index;
    guidata(hObject,handles);
    set(handles.stimMenu,'value',index);
    stimMenu_Callback(hObject,index,handles);
end
end

% Tell the manager to copy the working plot
function addplotbutton_Callback(hObject, eventdata, handles)
manager = getappdata(handles.figure1,'managerObj');
manager.addPlot(handles);
end

% Tell the manager to delete the selected plot
function deleteplotbutton_Callback(hObject, eventdata, handles)
appDataDict = getappdata(handles.figure1,'appDataDict');
legend = handles.legendBox;
% Create a string based on the current selection
selected = get(legend,'Value');
manager = getappdata(handles.figure1,'managerObj');
manager.deletePlot(handles, selected);
end

% Hide the working plot
function hideWPCheckbox_Callback(hObject, eventdata, handles)
if get(handles.hideWPCheckbox,'value')
    value = 'off';
    set(handles.CH1_workingPlot,'Visible',value);
    set(handles.CH1Text,'Visible',value);
    handles.CH1ScoreInd.setVisible(value);
    set(handles.CH2_workingPlot,'Visible',value);
    set(handles.CH2Text,'Visible',value);
    handles.CH2ScoreInd.setVisible(value);
else
    value = 'on';
    appDataDict = getappdata(handles.figure1,'appDataDict');
    set(handles.CH1_workingPlot,'Visible',value);
    set(handles.CH1Text,'Visible',appDataDict('scoringTickVisibility'));
    handles.CH1ScoreInd.setVisible(appDataDict('scoringTickVisibility'));
    set(handles.CH2_workingPlot,'Visible',value);
    set(handles.CH2Text,'Visible',appDataDict('scoringTickVisibility'));
    handles.CH2ScoreInd.setVisible(appDataDict('scoringTickVisibility'));
end
end

% Reset original position of any dragged plots
function resetBox_Callback(hObject, eventdata, handles)
manager = getappdata(handles.figure1,'managerObj');
manager.restorePlotsToOriginalPosition;
set(handles.resetBox,'Value',0);
end

% Turn VEP mag indictors on/off - don't turn on for invisible plots
function hideMagsBox_Callback(hObject, eventdata, handles)
manager = getappdata(handles.figure1,'managerObj');
appDataDict = getappdata(handles.figure1,'appDataDict');
set(handles.resetBox,'Value',0);
value = get(hObject,'value');
if ~value
    appDataDict('scoringTickVisibility') = 'on';
    manager.setTickVisibility('on');
    if strcmp(get(handles.CH1_workingPlot,'Visible'),'on')
        handles.CH1ScoreInd.setVisible('on');
        set(handles.CH1Text,'Visible','on');
    end
    if strcmp(get(handles.CH2_workingPlot,'Visible'),'on')
        handles.CH2ScoreInd.setVisible('on');
        set(handles.CH2Text,'Visible','on');
    end
else
    appDataDict('scoringTickVisibility') = 'off';
    manager.setTickVisibility('off');
    handles.CH1ScoreInd.setVisible('off');
    handles.CH2ScoreInd.setVisible('off');
    set(handles.CH1Text,'Visible','off');
    set(handles.CH2Text,'Visible','off');
end
% manager.toggleTickVisibility;
% handles.CH1ScoreInd.toggleVisibility;
% handles.CH2ScoreInd.toggleVisibility;
end

function dragOptions_Callback(hObject, eventdata, handles)
manager = getappdata(handles.figure1,'managerObj');
switch hObject
    case handles.verticalDraggingBox
        manager.toggleVerticalDragging;
    case handles.horizontalDraggingBox
        manager.toggleHorizontalDragging;
end
end


% Export control selection functions --------------------------------------
% -------------------------------------------------------------------------
function exportCtrlPanel_Callback(hObject,eventdata,handles)
% Select export function
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object
    case 'figureButton'
        setupForFigureExport(handles);
        set(handles.dataExportHandles,'Visible','off');
    case 'groupButton'
        setupForGroupExport(handles);
        set(handles.dataExportHandles,'Visible','off');
    case 'dataButton'
        setupForDataExport(handles);
        set(handles.dataExportHandles,'Visible','on');
    otherwise
        error('VEPDataObjectViewer.exportCtrlPanel_Callback');
end

end

% Prepare to export axes data as a figure
function setupForFigureExport(handles)
options = {'Postscript','JPEG','Figure Only'};
set(handles.exportMenu,'String',options,'Value',1,'Callback',[],...
    'ToolTipString','Set figure export type','Enable','on');
set(handles.exportButtons,'Callback',...
    @(hObject,eventdata)exportFigure_Callback(hObject,guidata(hObject)),...
    'ToolTipString','Create formatted figure','Enable','on');
end

% Export selected ch plot as a figure
function exportFigure_Callback(hObject,handles)

% Figure out which channel to export
switch hObject
    case handles.ch1ExportButton
        hSrc = handles.CH1axes;
        chStrs = cellstr(get(handles.ch1SelMenu,'String'));
        chStr = chStrs{get(handles.ch1SelMenu,'Value')};
        iCh = 1;
    case handles.ch2ExportButton
        hSrc = handles.CH2axes;
        chStrs = cellstr(get(handles.ch2SelMenu,'String'));
        chStr = chStrs{get(handles.ch2SelMenu,'Value')};
        iCh = 2;
end
appDataDict = getappdata(handles.figure1,'appDataDict');

% Copy the plot axes to a new figure
fh = figure('color',[1 1 1]);
ah = copyobj(hSrc,fh);
set(ah,'units','normalized','position',[0.13 0.11 0.775 0.815]);
oldTitle = get(ah,'Title');
oldTitle = get(oldTitle,'String');
title(ah,[]);

% Draw a scale bar on the new axes
xTicks = get(ah,'XTick');
yTicks = get(ah,'YTick');
xPts = [0 0 0.1 0.1];
yPts = [100 0 0 0] + (yTicks(1) - (yTicks(2)-yTicks(1))/2);
hold(ah,'on')
lh = plot(xPts,yPts,'k');
hold(ah,'off')
axis(ah,'off')
xTxtLoc = (xPts(3)-xPts(2))/2;
yTxtLoc = yPts(2) - (yTicks(2)-yTicks(1))/3;
th1 = text(xTxtLoc,yTxtLoc,'100 ms',...
    'Parent',ah,'HorizontalAlignment','center');
xTxtLoc = (xTicks(1)-xTicks(2))/3;
yTxtLoc = yPts(2) - (yPts(2)-yPts(1))/2;
th2 = text(xTxtLoc,yTxtLoc,'100 \muV',...
    'Parent',ah,'HorizontalAlignment','center','Rotation',90);

% Rescale axes to fit the scale and center the data
deltaX = 0.05;
deltaY = 50;
xlim(ah,[min(xTicks(1),xPts(1)) max(xTicks(end),xPts(3))]+[-1 1]*deltaX);
ylim(ah,[min(yTicks(2),yPts(1)) max(yTicks(end),yPts(1))]+[-1 1]*deltaY);

% Truncate underlying data at the axis limits
lineObjs = findobj(ah,'type','line');
for iL = 1:numel(lineObjs)
    if lineObjs(iL) ~= lh % don't chop the scale bars
        xData = get(lineObjs(iL),'xdata');
        yData = get(lineObjs(iL),'ydata');
        xind = (xData > xTicks(end)) | (xData < xTicks(1));
        if ~isempty(xind)
            xData = xData(~xind);
            yData = yData(~xind);
        end
        yind = (yData > yTicks(end)) | (yData < yTicks(1));
        if ~isempty(yind)
            xData = xData(~yind);
            yData = yData(~yind);
        end
        set(lineObjs(iL),'xdata',xData,'ydata',yData);
    end
end

% Create a legend using binding labels
manager = getappdata(handles.figure1,'managerObj');
bindings = manager.getBindings;
keys = bindings.keys;
if ~isempty(keys)
    legStr = {};
    for iK = 1:numel(keys)
        theBinding = bindings(keys{iK});
        plotHandles(iK) = theBinding{2}.lineObj; %#ok<AGROW>
        chKeys = theBinding{4};
        newLegStr = [theBinding{1} '_' chKeys{iCh}];
        legStr{end+1} = regexprep(newLegStr,'_','\\_'); %#ok<AGROW>
    end
    % Add working plot title if it is visible
    if get(handles.hideWPCheckbox,'Value') == 0
        legStr{end+1} = sprintf('%s\\_%s\\_%s\\_%s',...
            appDataDict('animalKey'),appDataDict('sessionKey'),...
            appDataDict('stimKey'),chStr);
        plotHandles(end+1) = handles.CH1_workingPlot;
    end
    legend(ah,plotHandles,legStr,'location','northeast')
else
    legend(ah,oldTitle,'location','northeast');
end

% Delete extraneous text objects
delete(findobj(fh,'String','tmp'));

% Turn off clipping everywhere
objs = findobj(fh,'-property','Clipping');
for iO = 1:numel(objs)
    set(objs(iO),'Clipping','off');
end

% Get rid off all button down functions
objs = findobj(fh,'-property','ButtonDownFcn');
for iO = 1:numel(objs)
    set(objs(iO),'ButtonDownFcn',[]);
end

% Prompt for filename and export
exportStrs = cellstr(get(handles.exportMenu,'String'));
exportType = exportStrs{get(handles.exportMenu,'Value')};
switch exportType
    case 'Postscript'
        [filename, pathname] = uiputfile('*.eps',...
            'Save figure as eps','tracePlot.eps');
        if isequal(filename,0) || isequal(pathname,0) % user select cancel
            return;
        end
        outputFile = fullfile(pathname,filename);
        print(fh,'-depsc',outputFile);
    case 'JPEG'
        [filename, pathname] = uiputfile('*.jpeg',...
            'Save figure as jpeg','tracePlot.jpeg');
        if isequal(filename,0) || isequal(pathname,0) % user select cancel
            return;
        end
        outputFile = fullfile(pathname,filename);
        print(fh,'-djpeg',outputFile);
end

end

function setupForGroupExport(handles)
groupKeys = handles.vdo.getGroupKeys;
options = ['-Select Export Group-' groupKeys 'Create New Group'];
set(handles.exportMenu,'String',options,'Value',1,...
    'Callback',...
    @(hObject,eventdata)groupSelection_Callback(hObject,guidata(hObject)),...
    'ToolTipString','Select a group to send data to','Enable','on');
set(handles.exportButtons,'Callback',...
    @(hObject,eventdata)exportGroup_Callback(hObject,guidata(hObject)),...
    'Enable','off','ToolTipString','Export data to selected group');
end

function groupSelection_Callback(hObject,handles)
menuContents = cellstr(get(handles.exportMenu,'String'));
grpKey = menuContents{get(handles.exportMenu,'Value')};

switch grpKey
    case '-Select Export Group-'
        set(handles.exportButtons,'Enable','off');
        return
    case 'Create New Group'
        grpKey = char(inputdlg('Enter new group name','Create new group'));
        if isempty(grpKey)
            set(handles.exportMenu,'Value',1);
            set(handles.exportButtons,'Enable','off');
            return
        end
        handles.vdo.createNewGroup(grpKey,'VEPMagGroupClass');
        groupKeys = handles.vdo.getGroupKeys;
        options = ['-Select Export Group-' groupKeys 'Create New Group'];
        %set(handles.exportMenu,'String',options,...
        %    'Value',strmatch(grpKey,options));
        set(handles.exportMenu,'String',options,...
            'Value',find(strcmp(grpKey,options)));
        % notify(handles.vdo,'GrpMgmtRefreshGUINeeded');
    otherwise
end
appDataDict = getappdata(handles.figure1,'appDataDict');
appDataDict('groupKey') = grpKey;
set(handles.exportButtons,'Enable','on');
end

% Export selected ch to a group
function exportGroup_Callback(hObject,handles)
switch hObject
    case handles.ch1ExportButton
        hMenu = handles.ch1SelMenu;
    case handles.ch2ExportButton
        hMenu = handles.ch2SelMenu;
    otherwise
        return
end
chStrs = get(hMenu,'String');
chKey = chStrs{get(hMenu,'Value')};
appDataDict = getappdata(handles.figure1,'appDataDict');
dso = getDataSpecifierTemplate('kidKeys');
dso.setHierarchyLevel(1,appDataDict('animalKey'));
dso.setHierarchyLevel(2,appDataDict('sessionKey'),true);
dso.setHierarchyLevel(3,appDataDict('stimKey'),true);
dso.setHierarchyLevel(4,chKey);
addDataSpecifier(handles.vdo.groupRecords(appDataDict('groupKey')),dso);
end

function setupForDataExport(handles)
options = {'Scores' 'Average Voltage Trace' 'Individual Traces'};
if strcmp(get(handles.exportDataButton,'Visible'),'on')
    selValue = get(handles.exportMenu,'Value');
else
    selValue = 1;
end
set(handles.exportMenu,'String',options,'Value',selValue,...
    'Callback',@(hObject,eventdata)dataExportMenu_Callback(hObject,guidata(hObject)),...
    'ToolTipString','Select data export type','Enable','on');
set(handles.exportButtons,'Callback',...
    @(hObject,eventdata)exportData_Callback(hObject,guidata(hObject)),...
    'ToolTipString','Select data for export');
set(handles.exportPendingCheckbox,'Value',0);
setappdata(handles.exportPendingCheckbox,'exportDict',containers.Map);
set([handles.exportDataButton handles.cancelExportButton],'Enable','off');
end

function dataExportMenu_Callback(hObject,handles)
menuOptions = get(handles.exportMenu,'string');
menuSelection = menuOptions{get(handles.exportMenu,'Value')};
switch menuSelection
    case 'Individual Traces'
        set(handles.exportButtons,'ToolTipString','Export traces');
    otherwise
        set(handles.exportButtons,'ToolTipString','Select data for export');
end
end

function executeDataExport_Callback(hObject,evntData,handles)
% This function is evoked by the Save and Cancel buttons - sends data in
% the exportDictionary to a CSV file or the desktop or, if cancel, deletes
% the dictionary and restores selection buttons
switch hObject
    case handles.cancelExportButton
        % Prompt the user to save before quitting or cancel
        selection = questdlg(...
            'Pending data exists. Delete without Saving?',...
            'Cancel Data Export',...
            'Delete','Cancel',...
            'Delete');
        if strcmp(selection,'Cancel')
            return
        end
    case handles.exportDataButton
        exportDict = getappdata(handles.exportPendingCheckbox,'exportDict');
        % Save Data to the base workspace
        if ~isdeployed
            disp('Trace Export Dictionary saved to workspace');
            assignin('base','VDOTraceExportDict',exportDict);
        end
        % Package Data for Export to File
        exportType = getappdata(handles.exportPendingCheckbox,'ExportType');
        switch exportType
            case 'Scores'
                keys = exportDict.keys;
                nD = length(exportDict(keys{1}));
                outCell = cell(length(keys)+1,nD+1);
                outCell(1,:) = {'DataSrc' 'Mag' 'Vneg' 'Vpos' ...
                    'negLatency' 'posLatency'};
                for iK = 1:length(keys)
                    theKey = keys{iK};
                    savedData = exportDict(theKey);
                    outCell{iK+1,1} = theKey;
                    for iD = 1:nD
                        outCell{iK+1,iD+1} = savedData(iD);
                    end
                end
                defaultName = 'scoreData.csv';
            case 'Average Voltage Trace'
                t = exportDict('t');
                nS = length(t);
                exportDict.remove('t');
                keys = exportDict.keys;
                nK = length(keys);
                outCell = cell(nS+1,nK+1);
                outCell{1,1} = 't';
                for iT = 1:nS
                    outCell{iT+1,1} = t(iT);
                end
                for iK = 1:length(keys)
                    theKey = keys{iK};
                    theData = exportDict(theKey);
                    outCell{1,iK+1} = theKey;
                    for iT = 1:nS
                        outCell{iT+1,iK+1} = theData(iT);
                    end
                end
                defaultName = 'avgVoltTraces.csv';
            case 'Individual Traces'
        end
        % Prompt for output file
        prompt = sprintf('Export data to csv file');
        [filename, pathname] = uiputfile('*.csv',prompt,defaultName);
        if isequal(filename,0) || isequal(pathname,0) % user selected cancel
            return;
        end
        cell2csv(outCell,filename,pathname);
        
        % warndlg('This should export the data');
end
rmappdata(handles.exportPendingCheckbox,'exportDict');
set([handles.figureButton handles.groupButton],'Enable','on');
        setupForDataExport(handles);
end

function exportData_Callback(hObject,handles)
% Evoked by the ch1 and ch2 export buttons - stores data in a dictionary
% for later export to a file or the base workspace

exportOptions = cellstr(get(handles.exportMenu,'String'));
exportSelection = exportOptions{get(handles.exportMenu,'Value')};
setappdata(handles.exportPendingCheckbox,'ExportType',exportSelection);

switch hObject
    case handles.ch1ExportButton
        hMenu = handles.ch1SelMenu;
        scoreInd = handles.CH1ScoreInd;
        ph = handles.CH1_workingPlot;
    case handles.ch2ExportButton
        hMenu = handles.ch2SelMenu;
        scoreInd = handles.CH2ScoreInd;
        ph = handles.CH2_workingPlot;
end

chStrs = cellstr(get(hMenu,'String'));
chKey = chStrs{get(hMenu,'Value')};
appDataDict = getappdata(handles.figure1,'appDataDict');
dataKey = sprintf('%s_%s_%s_%s',appDataDict('animalKey'),...
    appDataDict('sessionKey'),appDataDict('stimKey'),chKey);

exportType = getappdata(handles.exportPendingCheckbox,'ExportType');

% Individual traces are dumped straight to a file, not buffered to a
% dictionary
if strcmp(exportType,'Individual Traces')
    % Get the individual traces and put into a cell array
    chContents = cellstr(get(hMenu,'String'));
    chKey = chContents{get(hMenu,'Value')};
    handles.validTracesTemplate.setHierarchyLevel(4,chKey);
    [traces tTrace] = handles.vdo.getData(handles.validTracesTemplate);
    nS = length(tTrace);
    nTr = size(traces,2);
    outCell = cell(nS+1,nTr+1);
    outCell{1,1} = 't';
    for iC = 2:nTr+1
        outCell{1,iC} = sprintf('tr%i',iC-1);
    end
    outCell(2:end,1) = num2cell(tTrace');
    outCell(2:end,2:end) = num2cell(traces);
    % Prompt for output file
    appDataDict = getappdata(handles.figure1,'appDataDict');
    animalKey = appDataDict('animalKey');
    sessionKey = appDataDict('sessionKey');
    stimKey = appDataDict('stimKey');
    defaultName = genvarname(sprintf('traces_%s_%s_%s_%s',...
        animalKey,sessionKey,stimKey,chKey));
    prompt = sprintf('Export traces to csv file');
    [filename, filepath] = uiputfile('*.csv',prompt,defaultName);
    if isequal(filename,0) || isequal(filepath,0) % user selected cancel
        return;
    end
    cell2csv(outCell,filename,filepath);
    return
end

exportDict = getappdata(handles.exportPendingCheckbox,'exportDict');
if isempty(exportDict)
    % Start saving data for export - lockdown options until the data is
    % either exported or canceled
    set(handles.exportPendingCheckbox,'Value',1);
    set(handles.dataExportHandles,'Enable','on')
    set(handles.exportMenu,'Enable','off');
    set([handles.figureButton handles.groupButton],'Enable','off');
    
end

switch exportType
    case 'Scores' 
        [~, vMag neg pos negLat posLat] = getScoreStr(scoreInd);
        exportDict(dataKey) = [vMag neg pos negLat posLat];
    case 'Average Voltage Trace'
        if ~exportDict.isKey('t')
            exportDict('t') = get(ph,'xdata');
        end
        exportDict(dataKey) = get(ph,'ydata');
        if length(exportDict('t')) ~= length(exportDict(dataKey))
            warnstr = sprintf(...
                'Data length for %s does not match store time array.',...
                dataKey);
            warndlg(warnstr);
        end
end

end

function checkboxOverride(hObject,evntData,handles)
% Prevent user from chancing the pending data export checkbox value
oldValue = get(hObject,'Value');
set(hObject,'Value',~oldValue);
end


% VEP Scoring Functions ---------------------------------------------------
% -------------------------------------------------------------------------

function setupForManualScoring(hObject)
handles = guidata(hObject);
setappdata(handles.figure1,'ScoreChangedListeners',[]);
guidata(hObject,handles);
end

% Activate Manual VEP Scoring function
function manScoreButton_Callback(hObject,eventdata,handles)

disp('manScoreButton_Callback');
switch hObject
    case handles.manScoreButton
        if strcmp(get(handles.manScoreButton,'String'),'Save')
            scoreDictName = 'Manual';
            % Make a DataSelectionObject to find the active channelDataObjects
            dso = handles.VEPTraceTemplate.copy();
            dso.setDataSpecifier('returnTheObject');
            appDataDict = getappdata(handles.figure1,'appDataDict');
            % Get scores and save back to the VEPDataObject
            if handles.CH1ScoreInd.scoreChanged
                ch1Contents = cellstr(get(handles.ch1SelMenu,'String'));
                ch1Key = ch1Contents{get(handles.ch1SelMenu,'Value')};
                dso.setDataPathElement('channel',ch1Key);
                theChannel = handles.vdo.getData(dso);
                theScore = handles.CH1ScoreInd.getScore;
                theChannel.addScoreFromSrc(scoreDictName,theScore);
            end
            if handles.CH2ScoreInd.scoreChanged
                ch2Contents = cellstr(get(handles.ch2SelMenu,'String'));
                ch2Key = ch2Contents{get(handles.ch2SelMenu,'Value')};
                dso.setDataPathElement('channel',ch2Key);
                theChannel = handles.vdo.getData(dso);
                theScore = handles.CH2ScoreInd.getScore;
                theChannel.addScoreFromSrc(scoreDictName,theScore);
            end
            enableScoring(handles,false);
        else
            enableScoring(handles,true);
        end
    case handles.cancelScoreButton
        handles.CH1ScoreInd.restoreOriginalPosition;
        handles.CH2ScoreInd.restoreOriginalPosition;
        scoresChanged_Callback([],handles);
        enableScoring(handles,false);
    case handles.resetScoreButton
        handles.CH1ScoreInd.restoreOriginalPosition;
        handles.CH2ScoreInd.restoreOriginalPosition;
        scoresChanged_Callback([],handles);
end

end

function enableScoring(handles,enable)
% Score handles are visible only during scoring
scoreHandles = [handles.ch1ScoreTxt handles.ch2ScoreTxt ...
    handles.cancelScoreButton handles.resetScoreButton];
% Other handles are disabled during scoring
otherHandles = [ handles.animalMenu handles.conditionMenu ...
    handles.stimMenu handles.stimSlide handles.exportMenu ...
    handles.figureButton handles.groupButton handles.dataButton ...
    handles.addplotbutton handles.deleteplotbutton ...
    handles.hideWPCheckbox handles.hideMagsBox handles.resetBox ...
    handles.horizontalDraggingBox handles.verticalDraggingBox ...
    handles.ch1ExportButton handles.ch2ExportButton ...
    handles.ch1SelMenu handles.ch2SelMenu];
% Enable/disable score indicator objects
handles.CH1ScoreInd.enableScoring(enable);
handles.CH2ScoreInd.enableScoring(enable);
% Set GUI and 
if enable
    set(scoreHandles,'Visible','on');
    set(otherHandles,'Enable','off');
    set(handles.manScoreButton,'String','Save',...
        'TooltipString','Manually score data');
    % Create a callback to update the displayed scores
    setappdata(handles.figure1,'ScoreChangedListeners',...
        [addlistener(handles.CH1ScoreInd,...
        'ScoreChanged',@(src,event)scoresChanged_Callback(src,handles))...
        addlistener(handles.CH2ScoreInd,...
        'ScoreChanged',@(src,event)scoresChanged_Callback(src,handles))]);
    % Update the displayed score data
    scoresChanged_Callback([],handles);
else
    set(scoreHandles,'Visible','off');
    set(otherHandles,'Enable','on');
    set(handles.manScoreButton,'String','Score',...
        'TooltipString','Save modified scores' );
    % Remove listener callbacks
    delete(getappdata(handles.figure1,'ScoreChangedListeners'));
    setappdata(handles.figure1,'ScoreChangedListeners',[]);
end
end

% Update the text field displaying the manual score values
function scoresChanged_Callback(src,handles)
if strcmp(get(handles.manScoreButton,'String'),'Save')
    set(handles.ch1ScoreTxt,'String',handles.CH1ScoreInd.getScoreStr);
    set(handles.ch2ScoreTxt,'String',handles.CH2ScoreInd.getScoreStr);
end
end



% Plot Routines -----------------------------------------------------------
% -------------------------------------------------------------------------

% Draw the plots based on the selected stimulus
function updatePlots(hObject,eventData,handles)

% Get the valid channel keys and the selected keys
ch1Contents = cellstr(get(handles.ch1SelMenu,'String'));
ch1Key = ch1Contents{get(handles.ch1SelMenu,'Value')};
ch2Contents = cellstr(get(handles.ch2SelMenu,'String'));
ch2Key = ch2Contents{get(handles.ch2SelMenu,'Value')};
appDataDict = getappdata(handles.figure1,'appDataDict');
channelKeys = appDataDict('channelKeys');

% Check to see if scoring ticks are visible
appDataDict = getappdata(handles.figure1,'appDataDict');
if ~get(handles.hideMagsBox,'value')
    scoringTickVisibility = 'on';
else
    scoringTickVisibility = 'off';
end

% Get rid of constituent traces if they exist
delete(getappdata(handles.CH1_workingPlot,'Ch1ConstituentTraces'));
setappdata(handles.CH1_workingPlot,'Ch1ConstituentTraces',[]);
delete(getappdata(handles.CH2_workingPlot,'Ch2ConstituentTraces'));
setappdata(handles.CH2_workingPlot,'Ch2ConstituentTraces',[]);

% Update working plot with current CH1 data
if sum(strcmp(ch1Key,channelKeys))
    set(handles.ch1SelMenu,'ForegroundColor',[0 0 0]);
    handles.VEPTraceTemplate.setHierarchyLevel(4,ch1Key);
    handles.VEPScoreTemplate.setHierarchyLevel(4,ch1Key);
    [voltageTrace tTr] = handles.vdo.getData(handles.VEPTraceTemplate);
    score = handles.vdo.getData(handles.VEPScoreTemplate);        
    % Plot constituent traces if menu item is selected
    if get(handles.showTracesCheckBox,'Value')
        handles.validTracesTemplate.setHierarchyLevel(4,ch1Key);
        [traces tTrace] = handles.vdo.getData(handles.validTracesTemplate);
        nTr = size(traces,2);
        phs = zeros(1,nTr);
        hold(handles.CH1axes,'on');
        colors = flipud(bone(nTr));
        for iP = 1:nTr
            phs(iP) = plot(handles.CH1axes,...
                tTrace,traces(:,iP),'color',colors(iP,:));
        end
        hold(handles.CH1axes,'off');
        setappdata(handles.CH1_workingPlot,'Ch1ConstituentTraces',phs);
        uistack(phs,'bottom');
    end
    if ~isempty(voltageTrace)
        set(handles.hideWPCheckbox,'Value',0);
        set(handles.CH1_workingPlot,'xdata',tTr,'ydata',voltageTrace,...
            'visible','on');
        handles.CH1ScoreInd.setScore(score);
        set(handles.CH1Text,'String',...
            sprintf('%1.0f$\\mu$V',score.vMag),...
            'Visible',scoringTickVisibility);
        handles.CH1ScoreInd.setVisible(appDataDict('scoringTickVisibility'));
    else
        set(handles.CH1_workingPlot,'Visible','off');
        set(handles.CH1Text,'visible','off');
        handles.CH1ScoreInd.setVisible('off');
    end
else
    set(handles.ch1SelMenu,'ForegroundColor',[1 0 0]);
    set(handles.CH1_workingPlot,'Visible','off');
    set(handles.CH1Text,'visible','off');
    handles.CH1ScoreInd.setVisible('off');
end

% Update working plot with current CH2 data
if sum(strcmp(ch2Key,channelKeys))
    set(handles.ch2SelMenu,'ForegroundColor',[0 0 0]);
    handles.VEPTraceTemplate.setHierarchyLevel(4,ch2Key);
    handles.VEPScoreTemplate.setHierarchyLevel(4,ch2Key);
    [voltageTrace tTr] = handles.vdo.getData(handles.VEPTraceTemplate);
    score = handles.vdo.getData(handles.VEPScoreTemplate);
    % Plot constituent traces if menu item is selected
    if get(handles.showTracesCheckBox,'Value')
        handles.validTracesTemplate.setHierarchyLevel(4,ch2Key);
        [traces tTrace] = handles.vdo.getData(handles.validTracesTemplate);
        nTr = size(traces,2);
        phs = zeros(1,nTr);
        hold(handles.CH2axes,'on');
        colors = flipud(bone(nTr));
        for iP = 1:nTr
            phs(iP) = plot(handles.CH2axes,...
                tTrace,traces(:,iP),'color',colors(iP,:));
        end
        hold(handles.CH2axes,'off');
        setappdata(handles.CH2_workingPlot,'Ch2ConstituentTraces',phs);
        uistack(phs,'bottom');
    end
    if ~isempty(voltageTrace)
        set(handles.hideWPCheckbox,'Value',0);
        set(handles.CH2_workingPlot,'xdata',tTr,'ydata',voltageTrace,...
            'visible','on');
        handles.CH2ScoreInd.setScore(score);
        set(handles.CH2Text,'String',...
            sprintf('%1.0f$\\mu$V',score.vMag),...
            'Visible',scoringTickVisibility);
        handles.CH2ScoreInd.setVisible(appDataDict('scoringTickVisibility'));
    else
        set(handles.CH2_workingPlot,'Visible','off');
        set(handles.CH2Text,'visible','off');
        handles.CH2ScoreInd.setVisible('off');
    end
else
    set(handles.ch2SelMenu,'ForegroundColor',[1 0 0]);
    set(handles.CH2_workingPlot,'Visible','off');
    set(handles.CH2Text,'visible','off');
    handles.CH2ScoreInd.setVisible('off');
end

% If enabled, update the scoring info
scoresChanged_Callback([],handles);

end

function setAxes_Callback(src,~,handles)
switch src
    case handles.xAxesAutoMenu
        set(handles.CH2axes,'XLimMode','auto');
        set(handles.CH1axes,'XLimMode','auto');
        set(handles.xAxesAutoMenu,'checked','on');
        set(handles.xAxesSelectMenu,'checked','off');
    case handles.xAxesSelectMenu
        xlim = userSelectAxes('X Axis','ms',{'0' '0.5'});
        if ~isempty(xlim)
            set(handles.CH2axes,'XLim',xlim,'XLimMode','manual');
            set(handles.CH1axes,'XLim',xlim,'XLimMode','manual');
            set(handles.xAxesAutoMenu,'checked','off');
            set(handles.xAxesSelectMenu,'checked','on');
        end
    case handles.yAxesAutoMenu
        set(handles.CH2axes,'YLimMode','auto');
        set(handles.CH1axes,'YLimMode','auto');
        set(handles.yAxesAutoMenu,'checked','on');
        set(handles.yAxesSelectMenu,'checked','off');
    case handles.yAxesSelectMenu
        ylim = userSelectAxes('Y Axis','uV',{'-500' '500'});
        if ~isempty(ylim)
            set(handles.CH2axes,'YLim',ylim,'YLimMode','manual');
            set(handles.CH1axes,'YLim',ylim,'YLimMode','manual');
            set(handles.yAxesAutoMenu,'checked','off');
            set(handles.yAxesSelectMenu,'checked','on');
        end
    case handles.lineWidthMenu
        userResponse = inputdlg('Select Line Width','',1,{'2'});
        if ~isempty(userResponse)
            manager = getappdata(handles.figure1,'managerObj');
            linewidth = str2double(userResponse{1});
            set(handles.CH1_workingPlot,'LineWidth',linewidth);
            set(handles.CH2_workingPlot,'LineWidth',linewidth);
            manager = getappdata(handles.figure1,'managerObj');
            manager.setLineWidth(linewidth);
        end
end
end

function lims = userSelectAxes(axisString,unitsStr,defaults)
prompt = {sprintf('%s minimum (%s)',axisString,unitsStr) ...
    sprintf('%s maxiumum (%s)',axisString,unitsStr)};
windowName = 'Axes Limit Selection';
userResponse = inputdlg(prompt,windowName,1,defaults);
if isempty(userResponse)
    lims = [];
else
    lims(1) = str2double(userResponse{1});
    lims(2) = str2double(userResponse{2});
end
end

function dumpTraces_Callback(~,~,handles)

end

