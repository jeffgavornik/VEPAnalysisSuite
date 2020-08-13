function varargout = PSDViewer(varargin)

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

% Create a dictionary to hold application data
appDataDict = containers.Map;
setappdata(hObject,'appDataDict',appDataDict);

% Set the default plot behavior
dataKeys = {'dB' 'freqs' 'muPxx'};
setappdata(hObject,'dataKeys',dataKeys);

% Setup button group selection change behavior
set(handles.displayTypePanel,'SelectionChangeFcn',...
    @dataTypeSelectionGrp_Callback);

% Create a management object to keep track of plots
managerObj = PSDPlotManagerClass(dataKeys{2},dataKeys{3});
setappdata(hObject,'managerObj',managerObj);

% Create variables that will be used for data selection
appDataDict('animal') = [];
appDataDict('condition') = [];
appDataDict('stim') = [];

% By default, use LH and RH as the channel data keys
appDataDict('ch1Key') = 'LH';
appDataDict('ch2Key') = 'RH';

% Create dataSpecifierObjects to retrieve keys and VEP traces
handles.kidKeyTemplate = getDataSpecifierTemplate('kidKeys');
handles.PSDTemplate = getDataSpecifierTemplate('PSD');

% Create the working plot handles - these will be used to show the current
% selection
handles.LH_workingPlot = plot(handles.LHaxes,[0 1],[0 1],...
    'color','k','Visible','off','linewidth',2);
handles.RH_workingPlot = plot(handles.RHaxes,[0 1],[0 1],...
    'color','k','Visible','off','linewidth',2);

% Set default axes  and line properties
handles.LHXLabel = xlabel(handles.LHaxes,'f (Hz)','fontsize',12,...
    'fontweight','bold');
handles.LHYLabel = ylabel(handles.LHaxes,'dB','fontsize',12,...
    'fontweight','bold');
handles.RHXLabel = xlabel(handles.RHaxes,'f (Hz)','fontsize',12,...
    'fontweight','bold');
handles.RHYLabel = ylabel(handles.RHaxes,'dB','fontsize',12,...
    'fontweight','bold');

% Setup text to show distribution info
handles.LHText = text(0.05,0.85,'tmp',...
    'Units','Normalized',...
    'Parent',handles.LHaxes,...
    'Visible','off',...
    'Interpreter','LaTeX',...
    'FontName','Helvetica',...
    'Fontsize',14);
handles.RHText = text(0.05,0.85,'tmp',...
    'Units','Normalized',...
    'Parent',handles.RHaxes,...
    'Visible','off',...
    'Interpreter','LaTeX',...
    'FontName','Helvetica',...
    'Fontsize',14);

hold(handles.LHaxes,'off');
hold(handles.RHaxes,'off');

% Update handles structure
guidata(hObject, handles);

% If a VEPDataObject was passed, add it to the app data
if numel(varargin) > 0
    if isa(varargin{1},'VEPDataClass')
        associateVEPDataObject(hObject,varargin{1})
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
delete(handles.updateListener);
delete(handles.closeListener);
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

function channelSelectionMenu_Callback(hObject, eventdata, handles)
% Spawn a gui that allows the user to select which channel data to display
channelKeys = handles.vdo.getData(handles.channelsTemplate);
appDataDict = getappdata(handles.figure1,'appDataDict');
[ch1Key,ch2Key] = channelKeySelector(channelKeys,...
    appDataDict('ch1Key'),appDataDict('ch2Key'));
appDataDict('ch1Key') = ch1Key;
appDataDict('ch2Key') = ch2Key;
updatePlots(handles.figure1,eventdata,handles);
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
handles.PSDTemplate.resetDataPath();
handles.PSDTemplate.setHierarchyLevel(1,animalKey);
conditionKeys = handles.vdo.getData(handles.kidKeyTemplate);
set(handles.conditionMenu,'String',conditionKeys);

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
contents = cellstr(get(hObject,'String'));
%appDataDict = getappdata(handles.figure1,'appDataDict');

% Get the current stimulus selection value
oldStimKeys = cellstr(get(handles.stimMenu,'String'));
oldStimKey = oldStimKeys{get(handles.stimMenu,'Value')};

% Populate condition menu with conditions for the selected animal
conditionKey = contents{get(hObject,'Value')};
handles.kidKeyTemplate.setHierarchyLevel(2,conditionKey);
handles.PSDTemplate.setHierarchyLevel(2,conditionKey);
stimKeys = handles.vdo.getData(handles.kidKeyTemplate);
set(handles.stimMenu,'String',stimKeys)

% If the previously selected stim exists for the new animal, use it.
% If not, use the first stim as the default selection
stimIndex = strcmp(stimKeys,oldStimKey);
if sum(stimIndex)
    selValue = find(stimIndex == 1);
else
    selValue = 1;
end
set(handles.stimMenu,'Value',selValue);

% Setup the silder base on the current stimulus values
nStims = length(stimKeys);
if nStims > 1
    set(handles.stimSlide,'Min',1,'Max',nStims,...
        'Value',selValue,'SliderStep',[1/(nStims-1) 1/(nStims-1)]);
end

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

contents = cellstr(get(handles.stimMenu,'String'));
stimKey = contents{get(handles.stimMenu,'Value')};
handles.PSDTemplate.setHierarchyLevel(3,stimKey);

% Draw the plot in LH and RH axes.
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
set(handles.LH_workingPlot,'Visible',value);
set(handles.LHText,'Visible',value);
set(handles.RH_workingPlot,'Visible',value);
set(handles.RHText,'Visible',value);
end

% Reset original position of any dragged plots
function resetBox_Callback(hObject, eventdata, handles)
manager = getappdata(handles.figure1,'managerObj');
manager.restorePlotsToOriginalPosition;
set(handles.resetBox,'Value',0);
end

function dragOptions_Callback(hObject, eventdata, handles)
manager = getappdata(handles.figure1,'managerObj');
manager.toggleHorizontalDragging;
end


% Plot Routines -----------------------------------------------------------
% -------------------------------------------------------------------------

% Draw the plots based on the selected stimulus
function updatePlots(hObject,eventData,handles)

% Get the data keys
dataKeys = getappdata(handles.figure1,'dataKeys');
yLabel = dataKeys{1};
xKey = dataKeys{2};
yKey = dataKeys{3};

% Update working plot with current LH data
handles.PSDTemplate.setHierarchyLevel(4,'LH');
psdResults = handles.vdo.getData(handles.PSDTemplate);
xData = psdResults(xKey);
yData = 10*log10(psdResults(yKey));
yData = psdResults(yKey);
if ~isempty(yData)
    set(handles.hideWPCheckbox,'Value',0);
    set(handles.LH_workingPlot,'xdata',xData,'ydata',yData,...
        'visible','on');
    %set(handles.LHText,'String',...
    %    sprintf('E[v]=%1.0f$\\mu$V',psdResults('meanKey')),...
    %    'Visible','on');
else
    set(handles.LH_workingPlot,'Visible','off');
    set(handles.LHText,'visible','off');
end
set(handles.LHYLabel,'String',yLabel);
setappdata(handles.figure1,'LHPSDResults',psdResults);

% Update working plot with current RH data
handles.PSDTemplate.setHierarchyLevel(4,'RH');
psdResults = handles.vdo.getData(handles.PSDTemplate);
xData = psdResults(xKey);
yData = 10*log10(psdResults(yKey));
yData = psdResults(yKey);
if ~isempty(yData)
    set(handles.hideWPCheckbox,'Value',0);
    set(handles.RH_workingPlot,'xdata',xData,'ydata',yData,...
        'visible','on');
    %set(handles.RHText,'String',...
    %    sprintf('E[v]=%1.0f$\\mu$V',tmdaResults('meanKey')),...
    %    'Visible','on');
else
    set(handles.RH_workingPlot,'Visible','off');
    set(handles.RHText,'visible','off');
end
set(handles.RHYLabel,'String',yLabel);
setappdata(handles.figure1,'RHPSDResults',psdResults);
setXRangeCheckbox_Callback([],[],handles);

end

function dataTypeSelectionGrp_Callback(hObject,eventdata)
    handles = guidata(hObject);
    switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
        case 'linearButton'
            dataKeys = {'Raw PSD' 'epdf_x' 'epdf_f'};
            setappdata(handles.figure1,'dataKeys',dataKeys);
            %set(handles.LHaxes,'YLim',[0 5e-3]);
            %set(handles.RHaxes,'YLim',[0 5e-3]);
        case 'dbButton'
            dataKeys = {'dB' 'ecdf_x' 'ecdf_f'};
            setappdata(handles.figure1,'dataKeys',dataKeys);
            %set(handles.LHaxes,'YLim',[0 1]);
            %set(handles.RHaxes,'YLim',[0 1]);
    end
    set(handles.yAxesAutoMenu,'checked','off');
    set(handles.yAxesSelectMenu,'checked','on');
    updatePlots(hObject,[],handles);
    managerObj = getappdata(handles.figure1,'managerObj');
    managerObj.changeDataRepresentation(dataKeys{2},dataKeys{3})
end

function setAxes_Callback(src,~,handles)
switch src
    case handles.xAxesAutoMenu
        set(handles.RHaxes,'XLimMode','auto');
        set(handles.LHaxes,'XLimMode','auto');
        set(handles.xAxesAutoMenu,'checked','on');
        set(handles.xAxesSelectMenu,'checked','off');
    case handles.xAxesSelectMenu
        xlim = userSelectAxes('X Axis','ms',{'0' '100'});
        if ~isempty(xlim)
            set(handles.RHaxes,'XLim',xlim,'XLimMode','manual');
            set(handles.LHaxes,'XLim',xlim,'XLimMode','manual');
            set(handles.xAxesAutoMenu,'checked','off');
            set(handles.xAxesSelectMenu,'checked','on');
        end
    case handles.yAxesAutoMenu
        set(handles.RHaxes,'YLimMode','auto');
        set(handles.LHaxes,'YLimMode','auto');
        set(handles.yAxesAutoMenu,'checked','on');
        set(handles.yAxesSelectMenu,'checked','off');
    case handles.yAxesSelectMenu
        dataKeys = getappdata(handles.figure1,'dataKeys');
        yLabel = dataKeys{1};
        switch yLabel
            case 'Raw PSD'
                defaultSelections ={'0' '1'};
            case 'dB'
                defaultSelections = {'0' '40'};
        end
        ylim = userSelectAxes('Y Axis','uV',defaultSelections);
        if ~isempty(ylim)
            set(handles.RHaxes,'YLim',ylim,'YLimMode','manual');
            set(handles.LHaxes,'YLim',ylim,'YLimMode','manual');
            set(handles.yAxesAutoMenu,'checked','off');
            set(handles.yAxesSelectMenu,'checked','on');
        end
    case handles.lineWidthMenu
        userResponse = inputdlg('Select Line Width','',1,{'2'});
        if ~isempty(userResponse)
            manager = getappdata(handles.figure1,'managerObj');
            linewidth = str2double(userResponse{1});
            set(handles.LH_workingPlot,'LineWidth',linewidth);
            set(handles.RH_workingPlot,'LineWidth',linewidth);
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
set(handles.RHaxes,'XLim',xlim,'XLimMode','manual');
set(handles.LHaxes,'XLim',xlim,'XLimMode','manual');
set(handles.xAxesAutoMenu,'checked','off');
set(handles.xAxesSelectMenu,'checked','on');
end

function dataExport_Callback(hObject, eventdata, handles)
% Get the selected data keys
animalKeys = cellstr(get(handles.animalMenu,'String'));
animalKey = animalKeys{get(handles.animalMenu,'Value')};
sessionKeys = cellstr(get(handles.conditionMenu,'String'));
sessionKey = animalKeys{get(handles.conditionMenu,'Value')};
stimKeys = cellstr(get(handles.stimMenu,'String'));
stimKey = animalKeys{get(handles.stimMenu,'Value')};
% Get the current data - note: for plotting ecdf returns an n+1 sized array
% that duplicates the first point, return the raw data by removing this
% duplicate
handles.PSDTemplate.setHierarchyLevel(4,'LH');
psdResults = handles.vdo.getData(handles.PSDTemplate);
lh_xData = psdResults(xKey);
lh_fData = psdResults(fKey);
lh_data = lh_xData(2:end);
handles.PSDTemplate.setHierarchyLevel(4,'RE');
psdResults = handles.vdo.getData(handles.PSDTemplate);
rh_xData = psdResults(xKey);
rh_fData = psdResults(fKey);
rh_data = rh_xData(2:end);
% Create a structure to hold the data and send it to the base workspace
returnData.lh_xData = lh_xData;
returnData.lh_fData = lh_fData;
returnData.lh_data = lh_data;
returnData.rh_xData = rh_xData;
returnData.rh_fData = rh_fData;
returnData.rh_data = rh_data;
varName = sprintf('psd_%s_%s_%s',animalKey,sessionKey,stimKey);
fprintf('Exporting PSD data to base workspace as %s\n',varName);
assignin('base',varName,returnData);
end
