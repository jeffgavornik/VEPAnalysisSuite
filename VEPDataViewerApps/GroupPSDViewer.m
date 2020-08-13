function varargout = GroupPSDViewer(varargin)

% Inhibit mlint messages
%#ok<*INUSL,*INUSD,*DEFNU,*NASGU>

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
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
handles.slideListener = handle.listener(handles.stimSlide,'ActionEvent',...
    @stimSlide_listener_callBack);
% set(handles.stimSlide,'Visible','off');

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

% Set default axes  and line properties
xlabel(handles.CH1axes,'f (Hz)','fontsize',12,'fontweight','bold');
ylabel(handles.CH1axes,'db','fontsize',12,'fontweight','bold');

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
    @(src,event)vdoUpdate_Callback(hObject));
handles.closeListener = addlistener(vdo,'CloseViewers',...
    @(src,eventdata)closereq_Callback(hObject));
guidata(hObject,handles);
vdoUpdate_Callback(hObject);
end

function closereq_Callback(hObject)
handles = guidata(hObject);
delete(handles.updateListener);
delete(handles.closeListener);
delete(handles.slideListener);
delete(handles.figure1);
end

function varargout = GroupTraceViewer_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;
end

% GUI Element Create Functions --------------------------------------------
% -------------------------------------------------------------------------


function stimMenu_CreateFcn(hObject, eventdata, handles)
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

function vdoUpdate_Callback(hObject)
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
nGrps = length(groupKeys);
if nGrps == 1
    minVal = 0.9;
    sliderStepValues = [1 1];
else
    minVal = 1;
    sliderStepValues = [1/(nGrps-1) 1/(nGrps-1)];
end
set(handles.stimSlide,'Min',minVal,'Max',nGrps,...
    'Value',selValue,'SliderStep',sliderStepValues);
stimMenu_Callback(handles.stimMenu,[],handles);
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

% Draw the plot
updatePlots(handles.figure1,eventdata,handles)
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
else
    value = 'on';
end
set(handles.CH1_workingPlot,'Visible',value);
end

% Reset original position of any dragged plots
function resetBox_Callback(hObject, eventdata, handles)
manager = getappdata(handles.figure1,'managerObj');
manager.restorePlotsToOriginalPosition;
set(handles.resetBox,'Value',0);
end

% Turn VEP mag indictors on/off
function hideMagsBox_Callback(hObject, eventdata, handles)
manager = getappdata(handles.figure1,'managerObj');
manager.toggleTickVisibility;
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

% Draw the plots based on the selected stimulus
function updatePlots(hObject,eventData,handles)
appDataDict = getappdata(handles.figure1,'appDataDict');

% Update working plot with selected group data
groupKeys = cellstr(get(handles.stimMenu,'String'));
theKey = groupKeys{get(handles.stimMenu,'Value')};

origGrp = handles.vdo.groupRecords(theKey);
newGrp = PSDGroupClass(handles.vdo,theKey);
newGrp.copyExistingGroup(origGrp,'OrphanGroup');
[groupPxxs,freqs] = newGrp.getGroupData(theKey);
freqs = freqs{1};
Pxx = mean(groupPxxs,1);

freqs = freqs(2:end);
Pxx = Pxx(2:end); % Don't show DC

yLabel = 'Raw PSD';

 % Apply any normalization and presentation selections
 normTypes = get(handles.normMenu,'String');
 normType = normTypes{get(handles.normMenu,'Value')};
 switch normType
     case 'Percent Total'
         yLabel = '% Total PSD';
         Pxx = 100 * Pxx/sum(Pxx);
     case 'By Frequency'
         yLabel = 'PSD/freq';
         Pxx = Pxx./freqs;
 end
 
 presTypes = get(handles.presMenu,'String');
 presType = presTypes{get(handles.presMenu,'Value')};
 switch presType
     case '10 log10'
         Pxx = 10*log10(Pxx);
         yLabel = sprintf('%s (dB)',yLabel);
 end

if ~isempty(Pxx)
    set(handles.hideWPCheckbox,'Value',0);
    set(handles.CH1_workingPlot,'xdata',freqs,'ydata',Pxx,...
        'visible','on');
    title(handles.CH1axes,theKey);
else
    set(handles.CH1_workingPlot,'Visible','off');
end

ylabel(handles.CH1axes,yLabel);
setXRangeCheckbox_Callback([],[],handles);

end

function setAxes_Callback(src,~,handles)
switch src
    case handles.yAxesAutoMenu
        set(handles.CH1axes,'YLimMode','auto');
        set(handles.yAxesAutoMenu,'checked','on');
        set(handles.yAxesSelectMenu,'checked','off');
    case handles.yAxesSelectMenu
        ylim = userSelectAxes('Y Axis','uV',{'0' '50'});
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

function setXRangeCheckbox_Callback(src,~,handles)
xMin = str2double(get(handles.minXRange,'string'));
xMax = str2double(get(handles.maxXRange,'string'));
xlim = [xMin xMax];
set(handles.CH1axes,'XLim',xlim,'XLimMode','manual');
end

function exportToEPSMenu_Callback(hObject,eventData,handles)

    % Copy the plot axes to a new figure
    fh = figure('color',[1 1 1]);
    ah = copyobj(handles.CH1axes,fh);    
    set(ah,'units','normalized','position',[0.13 0.11 0.775 0.815]);
    oldTitle = get(ah,'Title');
    oldTitle = get(oldTitle,'String');
    title(ah,[]);
    
    % Truncate underlying data at the axis limits so that lines don't
    % extend beyond axes when clipping is turned off
    lineObjs = findobj(ah,'type','line');
    xTicks = get(ah,'XTick');
    yTicks = get(ah,'YTick');
    for iL = 1:numel(lineObjs)
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
    
    % Create a legend using binding labels
    manager = getappdata(handles.figure1,'managerObj');
    bindings = manager.getBindings;
    keys = bindings.keys;
    if ~isempty(keys)
        legStr = {};
        for iK = 1:numel(keys)
            theBinding = bindings(keys{iK});
            plotHandles(iK) = theBinding{2}.lineObj; %#ok<AGROW>
            legStr{end+1} = theBinding{1}; %#ok<AGROW>
        end
        % Add working plot title if it is visible
        if strcmp(get(handles.CH1_workingPlot,'visible'),'on')
            legStr{end+1} = oldTitle;
            plotHandles(end+1) = handles.CH1_workingPlot;
        end
        legend(ah,plotHandles,legStr,'location','northeast','fontsize',16)
    else
        legend(ah,oldTitle,'location','northeast','fontsize',16);
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
    
    % Turn on the grid and set fontsizes
    grid(ah,'on');
    set(ah,'fontsize',12);
    set(get(ah,'xlabel'),'fontsize',16,'fontweight','normal');
    set(get(ah,'ylabel'),'fontsize',16,'fontweight','normal');
    
    [filename, pathname] = uiputfile('*.eps',...
        'Save figure as eps','groupPlot.eps');
    if isequal(filename,0) || isequal(pathname,0) % user select cancel
        return;
    end
    outputFile = fullfile(pathname,filename);
    print(fh,'-depsc',outputFile);
end

