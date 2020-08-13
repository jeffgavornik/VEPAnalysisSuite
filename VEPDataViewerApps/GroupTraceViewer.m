function varargout = GroupTraceViewer(varargin)

% Inhibit mlint messages
%#ok<*INUSL,*INUSD,*DEFNU,*NASGU>

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @GroupTraceViewer_OpeningFcn, ...
    'gui_OutputFcn',  @GroupTraceViewer_OutputFcn, ...
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

% --- Executes just before GroupTraceViewer is made visible.
function GroupTraceViewer_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for GroupTraceViewer
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

% Create a dictionary to hold application data
appDataDict = containers.Map;
setappdata(hObject,'appDataDict',appDataDict);

% % Create a management object to keep track of plots
managerObj = GroupTracePlotManagerClass;
setappdata(hObject,'managerObj',managerObj);

% Create variables that will be used for data selection
appDataDict('stim') = [];

% Create the working plot handles - these will be used to show the current
% selection
handles.CH1_workingPlot = plot(handles.CH1axes,[0 1],[0 1],...
    'color','k','Visible','off','linewidth',2);
setappdata(handles.CH1_workingPlot,'ConstituentTraces',[]);

% Set default axes  and line properties
%appDataDict('ylim') = [-500 500];
%appDataDict('xlim') = [0 0.4];
xlabel(handles.CH1axes,'t (ms)','fontsize',12,'fontweight','bold');
ylabel(handles.CH1axes,'V (\muV)','fontsize',12,'fontweight','bold');
%set(handles.CH1axes,'YLim',appDataDict('ylim'));
% set(handles.CH1axes,'XLim',appDataDict('xlim'));

handles.CH1Text = text(0.75,0.85,'tmp',...
    'Units','Normalized',...
    'Parent',handles.CH1axes,...
    'Visible','off',...
    'Interpreter','LaTeX',...
    'FontName','Helvetica',...
    'Fontsize',14);

% Set data export selection callback
set(handles.exportCtrlPanel,'SelectionChangeFcn',...
    @(src,event)exportCtrlPanel_Callback(src,event,guidata(src)));

% Setup for data export
handles.dataExportHandles = [handles.exportPendingCheckbox ...
    handles.cancelExportButton];
evntData.NewValue = handles.figureButton;
exportCtrlPanel_Callback([],evntData,handles);
%setupForFigureExport(handles);

% Update handles structure
guidata(hObject, handles);

% If a VEPDataObject was passed, add it to the app data
if numel(varargin) > 0
    if isa(varargin{1},'VEPDataClass')
        associateVEPDataObject(hObject,varargin{1})
    else
        error('GroupTraceViewer only works with VEPDataClass objects');
    end
end

end

function associateVEPDataObject(hObject,vdo)
handles = guidata(hObject);
handles.vdo = vdo;
% add a listener for update and close events
handles.updateListener = addlistener(vdo,'UpdateViewers',...
    @(src,event)vdoUpdate_Callback(hObject,src));
handles.closeListener = addlistener(vdo,'CloseViewers',...
    @(src,eventdata)closereq_Callback(hObject));
guidata(hObject,handles);
vdoUpdate_Callback(hObject,'');
end

function closereq_Callback(hObject)
handles = guidata(hObject);
if isfield(handles,'updateListener')
    delete(handles.updateListener);
end
if isfield(handles,'closeListener')
    delete(handles.closeListener);
end
delete(handles.figure1);
end

function varargout = GroupTraceViewer_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;
end

function handles = findHandles(hFigure)
% This function finds the figure window and returns the handle - used for
% programatic interface where the calling function does not have access to
% any of the internal state but does know the figure, i.e. hFigure =
% GroupTraceViewer(vdo)
handles = guidata(hFigure);
end

% GUI Element Create Functions --------------------------------------------
% -------------------------------------------------------------------------

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

function avgByAnimalMenu_Callback(hObject, eventdata, handles)
switch get(handles.avgByAnimalMenu,'Checked')
    case 'on'
        set(handles.avgByAnimalMenu,'Checked','off');
    case 'off'
        set(handles.avgByAnimalMenu,'Checked','on');
end
updatePlots(handles.figure1,eventdata,handles);
end

function showTracesMenu_Callback(hObject, eventdata, handles)
switch get(handles.showTracesMenu,'Checked')
    case 'on'
        set(handles.showTracesMenu,'Checked','off');
    case 'off'
        set(handles.showTracesMenu,'Checked','on');
end
updatePlots(handles.figure1,eventdata,handles);
end


% GUI Element Callbacks ---------------------------------------------------
% -------------------------------------------------------------------------

function vdoUpdate_Callback(hObject,src)
handles = guidata(hObject);

% Get the current selection value
oldKeys = cellstr(get(handles.stimMenu,'String'));
selValue = get(handles.stimMenu,'Value');
oldKey = oldKeys{selValue};

% Get the group keys from the VEPDataObject
groupKeys = getGroupKeys(handles.vdo,'all');
if isempty(groupKeys)
    return;
end
set(handles.stimMenu,'String',groupKeys);
% If the previously selected group exists, use it.
% If not, use the first group as the default selection
groupIndex = strcmp(groupKeys,oldKey);
if sum(groupIndex)
    set(handles.stimMenu,'Value',find(groupIndex == 1));
else
    set(handles.stimMenu,'Value',1);
end

% Setup the silder based on the current stimulus values
nStims = length(groupKeys);
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
stimMenu_Callback(handles.stimMenu,[],handles);
end

% Select the stimulus
function stimMenu_Callback(hObject, eventdata, handles)
if hObject ~= handles.stimMenu
    value = eventdata;
else
    value = get(hObject,'Value');
end
setStimKey(handles,value)
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

function setStimKey(handles,value)
set(handles.stimMenu,'Value',value);
set(handles.stimSlide,'Value',value);
handles.oldIndex = value;
guidata(handles.figure1,handles);
updatePlots(handles.figure1,[],handles)
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
else
    value = 'on';
end
set(handles.CH1_workingPlot,'Visible',value);
%set(handles.CH1Text,'Visible',value);
end

% Reset original position of any dragged plots
function resetBox_Callback(hObject, eventdata, handles)
manager = getappdata(handles.figure1,'managerObj');
manager.restorePlotsToOriginalPosition;
set(handles.resetBox,'Value',0);
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


% Plot Routines -----------------------------------------------------------
% -------------------------------------------------------------------------

% Draw the plots based on the selected stimulus and current VDO state
function updatePlots(hObject,eventData,handles)

appDataDict = getappdata(handles.figure1,'appDataDict');

% Update working plot with selected group data
groupKeys = cellstr(get(handles.stimMenu,'String'));
theKey = groupKeys{get(handles.stimMenu,'Value')};

origGrp = handles.vdo.groupRecords(theKey);
newGrp = VEPTraceGroupClass(handles.vdo,theKey);
newGrp.copyExistingGroup(origGrp,'OrphanGroup');

% Get rid of individual traces if they exist
delete(getappdata(handles.CH1_workingPlot,'ConstituentTraces'));
setappdata(handles.CH1_workingPlot,'ConstituentTraces',[]);

% Check to see if data should be averaged by animal
if strcmp( get(handles.avgByAnimalMenu,'Checked'), 'on')
    avgString = 'AverageByAnimal';
else
    avgString = '';
end

% Plot constituent traces if menu item is selected
if strcmp(get(handles.showTracesMenu,'Checked'), 'on')
    [groupTraces, tTr] = newGrp.getGroupData(avgString);
    [nTr,~] = size(groupTraces);
    phs = zeros(1,nTr);
    hold(handles.CH1axes,'on');
    for iP = 1:nTr
        phs(iP) = plot(handles.CH1axes,...
            tTr,groupTraces(iP,:),'color','k');
    end
    hold(handles.CH1axes,'off');
    setappdata(handles.CH1_workingPlot,'ConstituentTraces',phs);
end

% Plot the average voltage trace for the group
[voltageTrace, tTr, keys] =  getMeanTrace(newGrp,avgString);
if ~isempty(voltageTrace)
    set(handles.hideWPCheckbox,'Value',0);
    set(handles.CH1_workingPlot,'xdata',tTr,...
        'ydata',voltageTrace,...
        'visible','on');
    %     set(handles.CH1Text,'String',...
    %         sprintf('%1.0f$\\mu$V',score.vMag),...
    %         'Visible','on');
    n = length(keys);
    title(handles.CH1axes,sprintf('n=%i',n));
    setappdata(handles.figure1,'currentN',n)
else
    set(handles.CH1_workingPlot,'Visible','off');
    %     handles.CH1ScoreInd.setVisible('off');
    set(handles.CH1Text,'visible','off');
end
drawnow

end

function setAxes_Callback(src,~,handles)
switch src
    case handles.xAxesAutoMenu
        set(handles.CH1axes,'XLimMode','auto');
        set(handles.xAxesAutoMenu,'checked','on');
        set(handles.xAxesSelectMenu,'checked','off');
    case handles.xAxesSelectMenu
        xlim = userSelectAxes('X Axis','ms',{'0' '0.5'});
        if ~isempty(xlim)
            set(handles.CH1axes,'XLim',xlim,'XLimMode','manual');
            set(handles.xAxesAutoMenu,'checked','off');
            set(handles.xAxesSelectMenu,'checked','on');
        end
    case handles.yAxesAutoMenu
        set(handles.CH1axes,'YLimMode','auto');
        set(handles.yAxesAutoMenu,'checked','on');
        set(handles.yAxesSelectMenu,'checked','off');
    case handles.yAxesSelectMenu
        ylim = userSelectAxes('Y Axis','uV',{'-500' '500'});
        if ~isempty(ylim)
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


% Export control selection functions --------------------------------------
% -------------------------------------------------------------------------
function exportCtrlPanel_Callback(hObject,eventdata,handles)

% Select export function
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object
    case 'figureButton'
        setupForFigureExport(handles);
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
set(handles.addDataButton,'Visible','off');
options = {'Postscript','JPEG','Figure Only'};
set(handles.exportMenu,'String',options,'Callback',[],...
    'ToolTipString','Set figure export type','Enable','on',...
    'Visible','on');
set(handles.exportDataButton,'Enable','on','Visible','on','Callback',...
    @(hObject,eventdata)exportFigure_Callback(hObject,eventdata,guidata(hObject)),...
    'ToolTipString','Create formatted figure',...
    'String','Export');
end

function exportFigure_Callback(hObject,eventData,handles)
exportFigure(handles);
end

function exportFigure(handles,exportType,filename)

if nargin < 2 || isempty(exportType)
    % Get export type from GUI
    exportStrs = cellstr(get(handles.exportMenu,'String'));
    exportType = exportStrs{get(handles.exportMenu,'Value')};
end

% Copy the plot axes to a new figure
fh = figure('color',[1 1 1]);
ah = copyobj(handles.CH1axes,fh);
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
groupKeys = cellstr(get(handles.stimMenu,'String'));
currentGroup = groupKeys{get(handles.stimMenu,'Value')};
if ~isempty(keys)
    legStr = {};
    for iK = 1:numel(keys)
        theBinding = bindings(keys{iK});
        plotHandles(iK) = theBinding{2}.lineObj; %#ok<AGROW>
        legStr{end+1} = theBinding{1}; %#ok<AGROW>
    end
    % Add working plot title if it is visible
    if strcmp(get(handles.CH1_workingPlot,'visible'),'on')
        legStr{end+1} = currentGroup;
        plotHandles(end+1) = handles.CH1_workingPlot;
    end
    legend(ah,plotHandles,legStr,'location','northeast')
else
    legend(ah,currentGroup,'location','northeast');
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

switch exportType
    case 'Postscript'
        if nargin < 3 ||isempty(filename)
            [filename, pathname] = uiputfile('*.eps',...
                'Save figure as eps','tracePlot.eps');
        else
            pathname = '';
        end
        if isequal(filename,0) || isequal(pathname,0) % user select cancel
            return;
        end
        outputFile = fullfile(pathname,filename);
        print(fh,'-depsc',outputFile);
    case 'JPEG'
        if nargin < 3 ||isempty(filename)
            [filename, pathname] = uiputfile('*.jpeg',...
                'Save figure as jpeg','tracePlot.jpeg');
        else
            pathname = '';
        end
        if isequal(filename,0) || isequal(pathname,0) % user select cancel
            return;
        end
        outputFile = fullfile(pathname,filename);
        print(fh,'-djpeg',outputFile);
end
drawnow
%     [filename, pathname] = uiputfile('*.eps',...
%         'Save figure as eps','groupPlot.eps');
%     if isequal(filename,0) || isequal(pathname,0) % user select cancel
%         return;
%     end
%     outputFile = fullfile(pathname,filename);
%     print(fh,'-depsc',outputFile);
end


function setupForDataExport(handles)
options = {'Average Voltage Trace' 'Individual Traces'};
set(handles.exportMenu,'Visible','off');
set(handles.addDataButton,'Visible','on','Callback',...
    @(hObject,eventdata)addData_Callback(hObject,eventdata,guidata(hObject)));
set(handles.exportPendingCheckbox,'Value',0);
setappdata(handles.exportPendingCheckbox,'exportDict',containers.Map);
set([handles.exportDataButton handles.cancelExportButton],'Enable','off');
set(handles.exportDataButton,'Callback',...
    @(hObject,eventdata)executeDataExport_Callback(hObject,eventdata,guidata(hObject)),...
    'ToolTipString','Select data for export','String','Save');

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
        if ~isdeployed
            disp('Group Trace Export Dictionary saved to workspace');
            assignin('base','GroupTraceExportDict',exportDict);
        end
        
        % Package the data for export to file
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
        
        % Prompt for output file
        defaultName = 'GrpTraces';
        prompt = sprintf('Export data to csv file');
        [filename, pathname] = uiputfile('*.csv',prompt,defaultName);
        if isequal(filename,0) || isequal(pathname,0) % user selected cancel
            return;
        end
        cell2csv(outCell,filename,pathname);
        
        % warndlg('This should export the data');
end
rmappdata(handles.exportPendingCheckbox,'exportDict');
set([handles.figureButton handles.dataButton],'Enable','on');
setupForDataExport(handles);
end

function addData_Callback(hObject,evntdata,handles)
% Evoked by the ch1 and ch2 export buttons - stores data in a dictionary
% for later export to a file or the base workspace
exportDict = getappdata(handles.exportPendingCheckbox,'exportDict');
if isempty(exportDict)
    % Start saving data for export - lockdown options until the data is
    % either exported or canceled
    set(handles.exportPendingCheckbox,'Value',1);
    set(handles.dataExportHandles,'Enable','on');
    set(handles.exportDataButton,'Enable','on');
    %set(handles.exportMenu,'Enable','off');
    set([handles.figureButton handles.dataButton],'Enable','off');
    exportOptions = cellstr(get(handles.exportMenu,'String'));
    
end
hMenu = handles.stimMenu;
ph = handles.CH1_workingPlot;
grpStrs = cellstr(get(hMenu,'String'));
grpKey = grpStrs{get(hMenu,'Value')};
appDataDict = getappdata(handles.figure1,'appDataDict');
exportType = getappdata(handles.exportPendingCheckbox,'ExportType');
if ~exportDict.isKey('t')
    exportDict('t') = get(ph,'xdata');
end
exportDict(grpKey) = get(ph,'ydata');
if length(exportDict('t')) ~= length(exportDict(grpKey))
    warnstr = sprintf(...
        'Data length for %s does not match store time array.',...
        dataKey);
    warndlg(warnstr);
end
end

function checkboxOverride(hObject,evntData,handles)
oldValue = get(hObject,'Value');
set(hObject,'Value',~oldValue);
end

% Programatic interface functions -----------------------------------------
% -------------------------------------------------------------------------

function ShowGroups(figH,groupNames)
handles = findHandles(figH);
if ~iscell(groupNames)
    groupNames = {groupNames};
end
groupKeys = getGroupKeys(handles.vdo,'all');
for iG = 1:length(groupNames)
    index = find(strcmp(groupKeys,groupNames{iG}));
    if ~isempty(index)
        setStimKey(handles,index);
        addplotbutton_Callback(handles.figure1, [], handles)
    end
end
end

function ExportFigure(figH,exportType,filename)
    handles = findHandles(figH);
if nargin < 2 || isempty(exportType)
    exportType = 'Figure Only';
end
if nargin < 3
    filename = '';
end
exportFigure(handles,exportType,filename)
end

function SetYAxis(figH,ylim)
handles = findHandles(figH);
if ~isempty(ylim)
    set(handles.CH1axes,'YLim',ylim,'YLimMode','manual');
    set(handles.yAxesAutoMenu,'checked','off');
    set(handles.yAxesSelectMenu,'checked','on');
end
end

function setXAxis(figH,xlim)
handles = findHandles(figH);
if ~isempty(xlim)
    set(handles.CH1axes,'XLim',xlim,'XLimMode','manual');
    set(handles.xAxesAutoMenu,'checked','off');
    set(handles.xAxesSelectMenu,'checked','on');
end
end

function HideWorkingPlot(figH)
handles = findHandles(figH);
set(handles.hideWPCheckbox,'value',0)
set(handles.CH1_workingPlot,'Visible','off');
end

function close(figH)
closereq_Callback(figH)
end
