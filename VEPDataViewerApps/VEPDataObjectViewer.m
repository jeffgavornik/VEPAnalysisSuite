function varargout = VEPDataObjectViewer(varargin)

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
handles.slideListener = handle.listener(handles.stimSlide,'ActionEvent',...
    @stimSlide_listener_callBack);

% Set data source selection callback
set(handles.dataSrcPanel,'SelectionChangeFcn',...
    @(src,event)dataSrcPanel_Callback(src,event,guidata(src)));

% Hide the scoring panel
figPos = get(handles.figure1,'Position');
figPos(3) = 127.6;
set(handles.figure1,'Position',figPos);

% Create a dictionary to hold application data
appDataDict = containers.Map;
setappdata(hObject,'appDataDict',appDataDict);

% % Create a management object to keep track of plots
managerObj = VEPPlotManagerClass;
setappdata(hObject,'managerObj',managerObj);

% Create variables that will be used for data selection
appDataDict('animal') = [];
appDataDict('condition') = [];
appDataDict('stim') = [];

% By default, use LH and RH as the channel data keys
appDataDict('ch1Key') = 'LH';
appDataDict('ch2Key') = 'RH';

% By default, use Animal-Sequence-Stim data selection
% setASSDataSrc;
appDataDict('srcChangeHandles') = [handles.animalTxt handles.sessionTxt ...
    handles.animalMenu handles.conditionMenu handles.CH2axes];

% Create dataSpecifierObjects to retrieve keys and VEP traces
handles.kidKeyTemplate = getDataSpecifierTemplate('kidKeys');
handles.VEPTraceTemplate = getDataSpecifierTemplate('VEPTrace');
handles.VEPScoreTemplate = getDataSpecifierTemplate('VEPscore');
handles.channelsTemplate = getDataSpecifierTemplate('channelKeys');

% Create the working plot handles - these will be used to show the current
% selection
handles.CH1_workingPlot = plot(handles.CH1axes,[0 1],[0 1],...
    'color','k','Visible','off','linewidth',2);
handles.CH2_workingPlot = plot(handles.CH2axes,[0 1],[0 1],...
    'color','k','Visible','off','linewidth',2);

% Set default axes  and line properties
appDataDict('ylim') = [-500 500];
%appDataDict('xlim') = [0 0.4];
xlabel(handles.CH1axes,'t (ms)','fontsize',12,'fontweight','bold');
ylabel(handles.CH1axes,'V (\muV)','fontsize',12,'fontweight','bold');
set(handles.CH1axes,'YLim',appDataDict('ylim'));
% set(handles.CH1axes,'XLim',appDataDict('xlim'));
xlabel(handles.CH2axes,'t (ms)','fontsize',12,'fontweight','bold');
ylabel(handles.CH2axes,'V (\muV)','fontsize',12,'fontweight','bold');
set(handles.CH2axes,'YLim',appDataDict('ylim'));
% set(handles.CH2axes,'XLim',appDataDict('xlim'));

% Setup plots to show scoring data on the working plots
handles.CH1ScoreInd = VEPScoringIndicatorClass(handles.CH1_workingPlot);
handles.CH1ScoreInd.setVisible('on');
handles.CH2ScoreInd = VEPScoringIndicatorClass(handles.CH2_workingPlot);
handles.CH2ScoreInd.setVisible('on');

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
delete(handles.updateListener);
delete(handles.closeListener);
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
handles.VEPTraceTemplate.resetDataPath();
handles.VEPTraceTemplate.setHierarchyLevel(1,animalKey);
handles.VEPScoreTemplate.resetDataPath();
handles.VEPScoreTemplate.setHierarchyLevel(1,animalKey);
handles.channelsTemplate.resetDataPath();
handles.channelsTemplate.setHierarchyLevel(1,animalKey);
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
handles.VEPTraceTemplate.setHierarchyLevel(2,conditionKey);
handles.VEPScoreTemplate.setHierarchyLevel(2,conditionKey);
handles.channelsTemplate.setHierarchyLevel(2,conditionKey);
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

% Setup the silder based on the current stimulus values
nStims = length(stimKeys);
set(handles.stimSlide,'Min',1,'Max',nStims,...
    'Value',selValue,'SliderStep',[1/(nStims-1) 1/(nStims-1)]);

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
handles.VEPTraceTemplate.setHierarchyLevel(3,stimKey);
handles.VEPScoreTemplate.setHierarchyLevel(3,stimKey);
handles.channelsTemplate.setHierarchyLevel(3,stimKey);

% Draw the plot in CH1 and CH2 axes.
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
set(handles.CH1Text,'Visible',value);
handles.CH1ScoreInd.setVisible(value);
set(handles.CH2_workingPlot,'Visible',value);
set(handles.CH2Text,'Visible',value);
handles.CH2ScoreInd.setVisible(value);
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

handles.CH1ScoreInd.toggleVisibility;
handles.CH2ScoreInd.toggleVisibility;

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


function dataSrcPanel_Callback(hObject,eventdata,handles)
disp(get(eventdata.NewValue,'Tag'))
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'assButton'
        %setASSDataSrc(handles);
    case 'groupButton'
        %setGroupDataSrc(handles);
    otherwise
        error('VEPDataObjectViewer.dataSecPanel_Callback: unknown selection');
end
end

% Data source selection functions -----------------------------------------
% -------------------------------------------------------------------------
function setGroupDataSrc(handles)
appDataDict = getappdata(handles.figure1,'appDataDict');
hideHandles = appDataDict('srcChangeHandles');
set(hideHandles,'Visible','off');
set(handles.stimTxt,'String','Group');
end

function setASSDataSrc(handles)
appDataDict = getappdata(handles.figure1,'appDataDict');
hideHandles = appDataDict('srcChangeHandles');
set(hideHandles,'Visible','on');
set(handles.stimTxt,'String','Stimulus');
end


% VEP Scoring Functions ---------------------------------------------------
% -------------------------------------------------------------------------

function setupForManualScoring(hObject)
handles = guidata(hObject);
setappdata(handles.figure1,'ScoreChangedListeners',[]);
guidata(hObject,handles);
end

% Activate Manual VEP Scoring function
function scoringMenu_Callback(hObject,eventdata,handles)
if strcmp(get(handles.scoringMenu,'Checked'),'on')
    % Hide the scoring panel and inhibit drag-based scoring
    set(handles.scoringMenu,'Checked','off');
    set(handles.scoringPanel,'Visible','off');
    figPos = get(handles.figure1,'Position');
    figPos(3) = 127.6; % shrink figure window
    %figPos(4) = 40.2;
    set(handles.figure1,'Position',figPos);
    handles.CH1ScoreInd.enableScoring(false);
    handles.CH2ScoreInd.enableScoring(false);
    % Remove listener callbacks
    delete(getappdata(handles.figure1,'ScoreChangedListeners'));
    setappdata(handles.figure1,'ScoreChangedListeners',[]);
else
    % Show the scoring panel and enable drag-based scoring
    set(handles.scoringMenu,'Checked','on');
    set(handles.scoringPanel,'Visible','on');
    figPos = get(handles.figure1,'Position');
    figPos(3) = 160; % expand figure window
    set(handles.figure1,'Position',figPos);
    handles.CH1ScoreInd.enableScoring(true);
    handles.CH2ScoreInd.enableScoring(true);
    % Create a callback to update the displayed scores
    callbackFnc = @(src,event)scoresChanged_Callback(src,handles);
    setappdata(handles.figure1,'ScoreChangedListeners',...
        [addlistener(handles.CH1ScoreInd,'ScoreChanged',callbackFnc)...
        addlistener(handles.CH2ScoreInd,'ScoreChanged',callbackFnc)]);
    % Update the displayed score data
    scoresChanged_Callback([],handles);
end
end

% Update the text field displaying the manual score values
function scoresChanged_Callback(src,handles)
if strcmp(get(handles.scoringMenu,'Checked'),'on')
    appDataDict = getappdata(handles.figure1,'appDataDict');
    ch1Key = appDataDict('ch1Key');
    ch2Key = appDataDict('ch2Key');
    scoresStr = sprintf('%s:%s\n%s:%s',...
        ch1Key,handles.CH1ScoreInd.getScoreStr,...
        ch2Key,handles.CH2ScoreInd.getScoreStr);
    set(handles.scoreText,'String',scoresStr);
end
end

function updateScoresButton_Callback(hObject,eventdata,handles)
scoreDictName = get(handles.scoreNameTxt,'String');
% Make a DataSelectionObject to find the active channelDataObjects
dso = handles.VEPTraceTemplate.copy();
dso.setDataSpecifier('returnTheObject');
appDataDict = getappdata(handles.figure1,'appDataDict');
% Get scores and save back to the VEPDataObject
if handles.CH1ScoreInd.scoreChanged
    dso.setDataPathElement('channel',appDataDict('ch1Key'));
    theChannel = handles.vdo.getData(dso);
    theScore = handles.CH1ScoreInd.getScore;
    theChannel.addScoreFromSrc(scoreDictName,theScore);
end
if handles.CH2ScoreInd.scoreChanged
    dso.setDataPathElement('channel',appDataDict('ch2Key'));
    theChannel = handles.vdo.getData(dso);
    theScore = handles.CH2ScoreInd.getScore;
    theChannel.addScoreFromSrc(scoreDictName,theScore);
end
end

function scoreResetButton_Callback(hObject,eventdata,handles)
handles.CH1ScoreInd.restoreOriginalPosition;
handles.CH2ScoreInd.restoreOriginalPosition;
scoresChanged_Callback([],handles);
end



% Plot Routines -----------------------------------------------------------
% -------------------------------------------------------------------------

% Draw the plots based on the selected stimulus
function updatePlots(hObject,eventData,handles)

% Get the channel keys
appDataDict = getappdata(handles.figure1,'appDataDict');
ch1Key = appDataDict('ch1Key');
ch2Key = appDataDict('ch2Key');

% Update working plot with current CH1 data
handles.VEPTraceTemplate.setHierarchyLevel(4,ch1Key);
handles.VEPScoreTemplate.setHierarchyLevel(4,ch1Key);
[voltageTrace tTr] = handles.vdo.getData(handles.VEPTraceTemplate);
score = handles.vdo.getData(handles.VEPScoreTemplate);
if ~isempty(voltageTrace)
    set(handles.hideWPCheckbox,'Value',0);
    set(handles.CH1_workingPlot,'xdata',tTr,'ydata',voltageTrace,...
        'visible','on');
    handles.CH1ScoreInd.setScore(score);
    % handles.CH1ScoreInd.setVisible('on');
    set(handles.CH1Text,'String',...
        sprintf('%1.0f$\\mu$V',score.vMag),...
        'Visible','on');
    title(handles.CH1axes,ch1Key);
else
    set(handles.CH1_workingPlot,'Visible','off');
    % handles.CH1ScoreInd.setVisible('off');
    set(handles.CH1Text,'visible','off');
end

% Update working plot with current CH2 data
handles.VEPTraceTemplate.setHierarchyLevel(4,ch2Key);
handles.VEPScoreTemplate.setHierarchyLevel(4,ch2Key);
[voltageTrace tTr] = handles.vdo.getData(handles.VEPTraceTemplate);
score = handles.vdo.getData(handles.VEPScoreTemplate);
if ~isempty(voltageTrace)
    set(handles.hideWPCheckbox,'Value',0);
    set(handles.CH2_workingPlot,'xdata',tTr,'ydata',voltageTrace,...
        'visible','on');
    handles.CH2ScoreInd.setScore(score);
    % handles.CH2ScoreInd.setVisible('on');
    set(handles.CH2Text,'String',...
        sprintf('%1.0f$\\mu$V',score.vMag),...
        'Visible','on');
    title(handles.CH2axes,ch2Key);
else
    set(handles.CH2_workingPlot,'Visible','off');
    % handles.CH2ScoreInd.setVisible('off');
    set(handles.CH2Text,'visible','off');
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
