function varargout = GroupDataBarPlotter(varargin)

%#ok<*DEFNU,*INUSL,*INUSD,*TRYNC>

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @GroupDataBarPlotter_OpeningFcn, ...
    'gui_OutputFcn',  @GroupDataBarPlotter_OutputFcn, ...
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
end
% End initialization code - DO NOT EDIT

function GroupDataBarPlotter_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for GroupDataBarPlotter
handles.output = hObject;

% Set GUI object callbacks
set(handles.figure1,'CloseRequestFcn',...
    @(hObject,eventdata)closereq_Callback(hObject));
set(handles.grpPanel,'SelectionChangeFcn',...
    @(src,event)GroupDataBarPlotter('grpPanel_Callback',...
    src,event,guidata(src)));
set(handles.selectionTable,'CellEditCallback',...
    @(src,event)updateGUI(hObject));
set(handles.plotTypePanel,'SelectionChangeFcn',...
    @(src,event)GroupDataBarPlotter('plotTypePanel_Callback',...
    src,event,guidata(src)));

% Initialize data selection table
set(handles.selectionTable,'Data',{''});
set(handles.selectionTable,'ColumnName',{});
set(handles.selectionTable,'ColumnFormat',{});
set(handles.selectionTable,'RowName',{});
setappdata(handles.figure1,'groupLabels',{});
setappdata(handles.figure1,'groupKeys',{'This is a Test' 'This also is a test'});
setappdata(handles.figure1,'DataDict',containers.Map);
setappdata(handles.figure1,'NormData',false);

% Create a bar plotter object that will be used to render the plots
dpo = dataPlotterClass;
dpo.ah = handles.axes;
setappdata(handles.figure1,'dpo',dpo);

% Set data export selection callback
set(handles.exportCtrlPanel,'SelectionChangeFcn',...
    @(src,event)exportCtrlPanel_Callback(src,event,guidata(src)));

% Setup for default data export
evntData.NewValue = handles.figureButton;
exportCtrlPanel_Callback([],evntData,handles);

% Get the filename for error handling
dbs = dbstack;
handles.mFileName = dbs(end).name;

% Update handles structure
guidata(hObject, handles);

% Setup analysis type
if nargin > 4
    setAnalysisType(hObject,handles,varargin{2});
else
    setAnalysisType(hObject,handles); % default based on GUI pre-sets
end

% Use input to setup
if nargin > 3
    if isa(varargin{1},'VEPDataClass')
        useVDO(hObject,varargin{1});
        updateDataFromVDO(hObject);
    end
end

end

function closereq_Callback(hObject)
handles = guidata(hObject);
delete(getappdata(handles.figure1,'dpo'));
if isfield(handles,'updateListener')
    delete(handles.updateListener);
end
if isfield(handles,'closeListener')
    delete(handles.closeListener);
end
delete(handles.figure1);
end

% Helper routines  --------------------------------------------------------
% -------------------------------------------------------------------------

function handles = findHandles(hFigure)
% This function finds the figure window and returns the handle - used for
% programatic interface where the calling function does not have access to
% any of the internal state but does know the figure, i.e. hFigure =
% GroupDataBarPlotter(vdo)
handles = guidata(hFigure);
end

% function handleError(ME,dbs)
% % ME is MException, db is the return value from dbstack
% msgStr = sprintf('%s\n%s',dbs.name,ME.message);
% errordlg(msgStr,'GroupDataBarPlotter');
% fprintf(2,'GroupDataBarPlotter.%s:\n %s\n',dbs.name,getReport(ME));
% end

function isUnique = assertUniqueName(handles,name)
% Return false is the name has already been used as a column or row label
isUnique = ~sum(strcmp(name,...
    cat(1,get(handles.selectionTable,'ColumnName'),...
    get(handles.selectionTable,'RowName'))));
end

% VEP Data Class Glue  ----------------------------------------------------
% -------------------------------------------------------------------------

function useVDO(hObject,vdo)
if isa(vdo,'VEPDataClass')
    handles = guidata(hObject);
    setappdata(handles.figure1,'vdo',vdo);
    dpo = getappdata(handles.figure1,'dpo');
    setTitle(dpo,vdo.ID);
    handles.updateListener = addlistener(vdo,'UpdateViewers',...
        @(src,event)vdoUpdate_Callback(hObject,src));
    handles.closeListener = addlistener(vdo,'CloseViewers',...
        @(src,eventdata)closereq_Callback(hObject));
    guidata(hObject,handles);
    
else
    errStr = 'GroupDataBarPlotter.useVDO()\nPassed variable is not a VEPDataClass Object';
    errordlg(errStr,...
        'GroupDataBarPlotter.useVDO()');
    error(errStr);
end
end

function updateDataFromVDO(hObject)
% Get and store the current groupKeys from the vdo, update the GUI
handles = guidata(hObject);
vdo = getappdata(handles.figure1,'vdo');
groupKeys = getGroupKeys(vdo,'all');
groupKeys = [{' '} groupKeys];
setappdata(handles.figure1,'groupKeys',groupKeys);
updateGUI(hObject);
end

function analysisTypeMenu_Callback(hObject, eventdata, handles)
switch get(hObject,'tag')
    case 'magnitudeMenu'
        set(handles.magnitudeMenu,'Checked','on');
        set(handles.negMagnitudeMenu,'Checked','off');
        set(handles.latencyMenu,'Checked','off');
    case 'negMagnitudeMenu'
        set(handles.magnitudeMenu,'Checked','off');
        set(handles.negMagnitudeMenu,'Checked','on');
        set(handles.latencyMenu,'Checked','off');
    case 'latencyMenu'
        set(handles.magnitudeMenu,'Checked','off');
        set(handles.negMagnitudeMenu,'Checked','off');
        set(handles.latencyMenu,'Checked','on');
end
setAnalysisType(hObject,handles);
end

function setAnalysisType(hObject,handles,analysisType)
if nargin < 3
    if strcmp(get(handles.magnitudeMenu,'Checked'),'on')
        analysisType = 'vep score';
    elseif strcmp(get(handles.negMagnitudeMenu,'Checked'),'on')
        analysisType = 'vep negative score';
    elseif strcmp(get(handles.latencyMenu,'Checked'),'on')
        analysisType = 'vep latency';
    end
end
switch lower(analysisType)
    case 'vep score'
        setappdata(handles.figure1,'analysisType',analysisType);
        dpo = getappdata(handles.figure1,'dpo');
        setYLabel(dpo,'VEP Mag (\muV)');
        set(handles.normalizeMenu,'Label','Normalized','Checked','off');
    case 'vep negative score'
        setappdata(handles.figure1,'analysisType',analysisType);
        dpo = getappdata(handles.figure1,'dpo');
        setYLabel(dpo,'Peak Negativity (\muV)');
        set(handles.normalizeMenu,'Label','Normalized','Checked','off');
    case 'vep latency'
        setappdata(handles.figure1,'analysisType',analysisType);
        dpo = getappdata(handles.figure1,'dpo');
        setYLabel(dpo,'Negative Latency (ms)');
        set(handles.normalizeMenu,'Label','Positive Latency','Checked','off');
    otherwise
        errStr = sprintf('GroupDataBarPlotter.setAnalysisType()\nInvalid analysis type ''%s''',...
            analysisType);
        errordlg(errStr,'GroupDataBarPlotter');
        error(errStr); %#ok<SPERR>
end
setappdata(handles.figure1,'NormData',0);
if isappdata(handles.figure1,'vdo')
    updateGUI(hObject);
end
end

function varargout = GroupDataBarPlotter_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;
end



% Data Routines -----------------------------------------------------------
% -------------------------------------------------------------------------
% Functions to define classes and conditions - provide programatic access
% with optional variables conditionName and className
function newColumnButton_Callback(hObject, eventdata, handles)
condName = inputdlg('Enter new column name','Create New Column');
if isempty(condName)
    return
else
    condName = condName{:};
end
newColumn(handles,condName);
end

function newColumn(handles,colNames)
% Add a new column to the data selector table with label colName
% handles should either be the gui handles or the figure
if isa(handles,'double') || isa(handles,'matlab.ui.Figure')
    handles = findHandles(handles);
end
if ~iscell(colNames)
    colNames = {colNames};
end
for iC = 1:length(colNames)
    colName = colNames{iC};
    if ~assertUniqueName(handles,colName)
        errordlg({'newColumn: non-unique name';colName});
    else
        dataTable = get(handles.selectionTable,'Data');
        ColumnNames = get(handles.selectionTable,'ColumnName');
        ColumnEditable = get(handles.selectionTable,'ColumnEditable');
        ColumnFormat = get(handles.selectionTable,'ColumnFormat');
        groupKeys = getappdata(handles.figure1,'groupKeys');
        if isempty(ColumnNames)
            ColumnNames = {colName};
            ColumnEditable = true;
            ColumnFormat = {groupKeys};
        else
            ColumnNames{end+1} = colName; %#ok<AGROW>
            ColumnEditable(end+1) = true; %#ok<AGROW>
            ColumnFormat{end+1} = groupKeys; %#ok<AGROW>
            [~,cols] = size(dataTable);
            dataTable(:,cols+1) = {''};
        end
        set(handles.selectionTable,'Data',dataTable);
        set(handles.selectionTable,'ColumnName',ColumnNames);
        set(handles.selectionTable,'ColumnEditable',ColumnEditable);
        set(handles.selectionTable,'ColumnFormat',ColumnFormat);
    end
end
end

function deleteColumnButton_Callback(hObject, eventdata, handles)

% Get the column names and allow user to select which to delete
ColumnNames = get(handles.selectionTable,'ColumnName');
if isempty(ColumnNames)
    return;
end
s = listdlg('PromptString','Select Condition to Delete',...
    'SelectionMode','single','ListSize',[160 100],...
    'ListString',ColumnNames);
if isempty(s)
    return;
end
try
    set(handles.figure1,'Pointer','watch');
    drawnow
    colName = ColumnNames{s};
    % Get the current table values and replace after deleting the column
    indici = ~strcmp(ColumnNames,colName);
    dataTable = get(handles.selectionTable,'Data');
    ColumnEditable = get(handles.selectionTable,'ColumnEditable');
    ColumnFormat = get(handles.selectionTable,'ColumnFormat');
    set(handles.selectionTable,'Data',dataTable(:,indici));
    set(handles.selectionTable,'ColumnName',ColumnNames(indici));
    set(handles.selectionTable,'ColumnEditable',ColumnEditable(:,indici));
    set(handles.selectionTable,'ColumnFormat',ColumnFormat(:,indici));
    updateGUI(hObject);
catch ME
    handleError(ME,true,handles.mFileName);
end
set(handles.figure1,'Pointer','arrow');
end

function newRowButton_Callback(hObject, eventdata, handles)
rowName = inputdlg('Enter new row name','Create New Row');
if isempty(rowName)
    return
else
    rowName = rowName{:};
end
newRow(handles,rowName);
end

function newRow(handles,rowNames)
% Add a new column to the data selector table with label rowName
% handles should either be the gui handles or the figure
if isa(handles,'double') || isa(handles,'matlab.ui.Figure')
    handles = findHandles(handles);
end
if ~iscell(rowNames)
    rowNames = {rowNames};
end
for iC = 1:length(rowNames)
    rowName = rowNames{iC};
    if ~assertUniqueName(handles,rowName)
        errordlg({'newRow: non-unique name';rowName});
    else
        dataTable = get(handles.selectionTable,'Data');
        RowNames = get(handles.selectionTable,'RowName');
        if isempty(RowNames)
            RowNames = {rowName};
        else
            RowNames{end+1} = rowName; %#ok<AGROW>
            [rows,~] = size(dataTable);
            dataTable(rows+1,:) = {''};
        end
        if isempty(dataTable)
            groupKeys = getappdata(handles.figure1,'groupKeys');
            set(handles.selectionTable,'ColumnFormat',{groupKeys});
            dataTable = {''};
        end
        set(handles.selectionTable,'Data',dataTable);
        set(handles.selectionTable,'RowName',RowNames);
    end
end
end

function deleteRowButton_Callback(hObject, eventdata, handles)
% Get the row names and allow user to select which to delete
RowNames = get(handles.selectionTable,'RowName');
if isempty(RowNames)
    return;
end
s = listdlg('PromptString','Select Condition to Delete',...
    'SelectionMode','single','ListSize',[160 100],...
    'ListString',RowNames);
if isempty(s)
    return;
end
try
    set(handles.figure1,'Pointer','watch');
    drawnow
    rowName = RowNames{s};
    % Get the current table values and replace after deleting the column
    indici = ~strcmp(RowNames,rowName);
    dataTable = get(handles.selectionTable,'Data');
    % ColumnEditable = get(handles.selectionTable,'ColumnEditable');
    % ColumnFormat = get(handles.selectionTable,'ColumnFormat');
    set(handles.selectionTable,'Data',dataTable(indici,:));
    set(handles.selectionTable,'RowName',RowNames(indici));
    % set(handles.selectionTable,'ColumnEditable',ColumnEditable(indici,:));
    % set(handles.selectionTable,'ColumnFormat',ColumnFormat(indici,:));
    updateGUI(hObject);
catch ME
    handleError(ME,true,handles.mFileName);
end
set(handles.figure1,'Pointer','arrow');
end

function avgByAnimalMenu_Callback(hObject, eventdata, handles)
try
    set(handles.figure1,'Pointer','watch');
    drawnow
    switch get(hObject,'checked')
        case 'on'
            set(hObject,'checked','off');
        case 'off'
            set(hObject,'checked','on');
    end
    updateGUI(hObject);
catch ME
    handleError(ME,true,handles.mFileName);
end
set(handles.figure1,'Pointer','arrow');
end

function showDataPtsMenu_Callback(hObject, eventdata, handles)
try
    set(handles.figure1,'Pointer','watch');
    drawnow
    switch get(hObject,'checked')
        case 'on'
            set(hObject,'checked','off');
        case 'off'
            set(hObject,'checked','on');
    end
    toggleShowDataPts(getappdata(handles.figure1,'dpo'));
    updateGUI(hObject);
catch ME
    handleError(ME,true,handles.mFileName);
end
set(handles.figure1,'Pointer','arrow');
end


% Plot Routines -----------------------------------------------------------
% -------------------------------------------------------------------------

function updateGUI(hObject)

handles = guidata(hObject);
% Populate the data table with menus for the current group keys - if the
% previous selection is a current group, keep it. Otherwise select no key.
% If there is a valid selection, make a copy of the group data and format
% based on the analysis type
dataTable = get(handles.selectionTable,'Data');
condNames = get(handles.selectionTable,'ColumnName');
classNames = get(handles.selectionTable,'RowName');
if isempty(condNames) && isempty(classNames)
    return % nothing defined yet so return without update
end
groupKeys = getappdata(handles.figure1,'groupKeys');
[rows,cols] = size(dataTable);
validKeys = {};
for col = 1:cols
    if isempty(condNames)
        condName = ' ';
    else
        condName = condNames{col};
    end
    for row = 1:rows
        if isempty(classNames)
            className = ' ';
        else
            className = classNames{row};
        end
        oldSel = dataTable{row,col};
        if ~strcmp(groupKeys,oldSel)
            newSel = groupKeys{1}; % Default to no selection
        else
            newSel = oldSel;
        end
        dataTable{row,col} = newSel;
        if ~(strcmp(newSel,' ') || isempty(newSel))
            keyStr = sprintf('%s_%s_%s',...
                condName,className,newSel);
            validKeys{end+1} = keyStr; %#ok<AGROW>
            % disp(keyStr)
        end
    end
end
if isempty(dataTable) || isempty(validKeys)
    dpo = getappdata(handles.figure1,'dpo');
    resetData(dpo);
    render(dpo);
    return;
end
set(handles.selectionTable,'Data',dataTable);
setappdata(handles.figure1,'validKeys',validKeys);

% Get data for all valid keys based on the analysis type, ie VEPMag or
% Latency
fncName = sprintf('GDBPgetData_%s',...
    genvarname(lower(getappdata(handles.figure1,'analysisType'))));
fncHandle = str2func(fncName);
fncHandle(hObject);

% Draw the plots
render(getappdata(handles.figure1,'dpo'));

end

% Data Extraction ---------------------------------------------------------
% -------------------------------------------------------------------------

% Analysis type specific functions to populate the dataDict with data
% returned by the VDO
function GDBPgetData_vepScore(hObject)
handles = guidata(hObject);
try
    set(handles.figure1,'Pointer','watch');
    drawnow
%rmappdata(handles.figure1,'DataDict');
DataDict = containers.Map;
validKeys = getappdata(handles.figure1,'validKeys');
vdo = getappdata(handles.figure1,'vdo');
dpo = getappdata(handles.figure1,'dpo');
resetData(dpo);
% Check to see if data should be averaged by animal
if strcmp( get(handles.avgByAnimalMenu,'Checked'), 'on')
    avgString = 'AverageByAnimal';
else
    avgString = '';
end
for iK = 1:numel(validKeys)
    dataKey = validKeys{iK};
    parts = regexp(dataKey,'_','split');
    condKey = parts{1};
    classKey = parts{2};
    grpKey = parts{3};
    origGrp = vdo.groupRecords(grpKey);
    newGrp = VEPMagGroupClass(vdo,grpKey);
    newGrp.copyExistingGroup(origGrp,'OrphanGroup');
    [grpData,normData] = newGrp.getGroupData(avgString);
    if getappdata(handles.figure1,'NormData')
        addData(dpo,condKey,classKey,normData);
    else
        addData(dpo,condKey,classKey,grpData);
    end
end
setappdata(handles.figure1,'DataDict',DataDict);
catch ME
    handleError(ME,true,handles.mFileName);
end
set(handles.figure1,'Pointer','arrow');
end

% Analysis type specific functions to populate the dataDict with data
% returned by the VDO
function GDBPgetData_vepNegativeScore(hObject)
handles = guidata(hObject);
try
    set(handles.figure1,'Pointer','watch');
    drawnow
%rmappdata(handles.figure1,'DataDict');
DataDict = containers.Map;
validKeys = getappdata(handles.figure1,'validKeys');
vdo = getappdata(handles.figure1,'vdo');
dpo = getappdata(handles.figure1,'dpo');
resetData(dpo);
% Check to see if data should be averaged by animal
if strcmp( get(handles.avgByAnimalMenu,'Checked'), 'on')
    avgString = 'AverageByAnimal';
else
    avgString = '';
end
for iK = 1:numel(validKeys)
    dataKey = validKeys{iK};
    parts = regexp(dataKey,'_','split');
    condKey = parts{1};
    classKey = parts{2};
    grpKey = parts{3};
    origGrp = vdo.groupRecords(grpKey);
    newGrp = VEPMagGroupClass(vdo,grpKey,'VEPNegMag');
    newGrp.copyExistingGroup(origGrp,'OrphanGroup');
    [grpData,normData] = newGrp.getGroupData(avgString);
    if getappdata(handles.figure1,'NormData')
        addData(dpo,condKey,classKey,abs(normData));
    else
        addData(dpo,condKey,classKey,abs(grpData));
    end
end
setappdata(handles.figure1,'DataDict',DataDict);
catch ME
    handleError(ME,true,handles.mFileName);
end
set(handles.figure1,'Pointer','arrow');
end

function GDBPgetData_vepLatency(hObject)
handles = guidata(hObject);
try
    set(handles.figure1,'Pointer','watch');
    drawnow
    %rmappdata(handles.figure1,'DataDict');
    DataDict = containers.Map;
    validKeys = getappdata(handles.figure1,'validKeys');
    vdo = getappdata(handles.figure1,'vdo');
    dpo = getappdata(handles.figure1,'dpo');
    resetData(dpo);
    % Check to see if data should be averaged by animal
    if strcmp( get(handles.avgByAnimalMenu,'Checked'), 'on')
        avgString = 'AverageByAnimal';
    else
        avgString = '';
    end
    for iK = 1:numel(validKeys)
        dataKey = validKeys{iK};
        parts = regexp(dataKey,'_','split');
        condKey = parts{1};
        classKey = parts{2};
        grpKey = parts{3};
        origGrp = vdo.groupRecords(grpKey);
        newGrp = VEPLatencyGroupClass(vdo,grpKey);
        newGrp.copyExistingGroup(origGrp,'OrphanGroup');
        [negLats,posLats] = newGrp.getGroupData(avgString);
        %[negLats posLats] = newGrp.getGroupData('AverageByAnimal');
        if getappdata(handles.figure1,'NormData')
            addData(dpo,condKey,classKey,1e3*posLats);
        else
            addData(dpo,condKey,classKey,1e3*negLats);
        end
    end
    setappdata(handles.figure1,'DataDict',DataDict);
catch ME
    handleError(ME,true,handles.mFileName);
end
set(handles.figure1,'Pointer','arrow');
end

function normalizeMenu_Callback(hObject, eventdata, handles)
% Note: normalizeMenu is used for both normalization in the VEP magnitude
% latency analysis and to set positive/negative latency in the latency
% analysis
try
    set(handles.figure1,'Pointer','watch');
    drawnow;
    posLat = strcmp(get(handles.normalizeMenu,'Label'),'Positive Latency');
    dpo = getappdata(handles.figure1,'dpo');
    switch get(hObject,'Checked')
        case 'on'
            set(hObject,'Checked','off')
            setappdata(handles.figure1,'NormData',0);
            if posLat
                setYLabel(dpo,'Negative Latency (ms)');
            else
                setYLabel(dpo,'VEP Mag (\muV)');
                
            end
        case 'off'
            set(hObject,'Checked','on')
            setappdata(handles.figure1,'NormData',1);
            if posLat
                setYLabel(dpo,'Positive Latency (ms)');
            else
                setYLabel(dpo,'Normalized VEP Mag');
            end
    end
    updateGUI(hObject);
catch ME
    handleError(ME,true,handles.mFileName);
end
set(handles.figure1,'Pointer','arrow');
end

% Data Export Routines  ---------------------------------------------------
% -------------------------------------------------------------------------

% Export control selection functions --------------------------------------
% -------------------------------------------------------------------------
function exportCtrlPanel_Callback(hObject,eventdata,handles)

% Select export function
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object
    case 'figureButton'
        setupForFigureExport(handles);
    case 'dataButton'
        setupForDataExport(handles);
    otherwise
        error('VEPDataObjectViewer.exportCtrlPanel_Callback');
end
end

% Prepare to export axes data as a figure
function setupForFigureExport(handles)
options = {'Postscript','JPEG','Figure Only'};
set(handles.exportMenu,'String',options,'Value',1,...
    'ToolTipString','Set figure export type');
set(handles.exportDataButton,'Callback',...
    @(hObject,eventdata)exportFigure_Callback(hObject,eventdata,guidata(hObject)),...
    'ToolTipString','Create formatted figure');
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

% Get the objects of interest from the GUI and figure out their sizes
% relative to each other
panelPos = get(handles.uipanel1,'position');
panelWidth = panelPos(3);
panelHeight = panelPos(4);
kids = get(handles.uipanel1,'Children');
hAx = handles.axes;
hLeg = findobj(kids,'Tag','legend');
if isempty(hLeg)
    warndlg('Will not export an empty figure');
    return
end
% Heurestic scaling to make everything look nice
plotPos = get(hAx,'Position');
legPos = get(hLeg,'Position');
plotPosNorm = ([1.4 1 0.95 1].*plotPos)./...
    [panelWidth panelHeight panelWidth panelHeight];
legPosNorm = ([1 1.1 1 1].*legPos)./...
    [panelWidth panelHeight panelWidth panelHeight];
% Copy the objects to a new figure
fh = figure('color',[1 1 1]);
if verLessThan('matlab', '8.4')
    ah = copyobj(hAx,fh);
	lh = copyobj(hLeg,fh);
    % Resize to fit in the new figure
    set(ah,'units','normalized','position',plotPosNorm);
    set(lh,'units','normalized','position',legPosNorm);
else
    % R2014b changed graphics handling quite a bit.  See 
    % http://blogs.mathworks.com/loren/2014/11/05/matlab-r2014b-graphics-part-3-compatibility-considerations-in-the-new-graphics-system/
    dpo = getappdata(handles.figure1,'dpo');
    objs = copyobj([hLeg dpo.ah],fh);
    %ah = objs(2);
    %lh = objs(1);
    set(objs(2),'units','normalized','position',plotPosNorm);
end

% Turn off clipping everywhere
objs = findobj(fh,'-property','Clipping');
for iO = 1:numel(objs)
    set(objs(iO),'Clipping','off');
end

if strcmp(exportType,'Figure Only')
    return;
end
% Get the export directory from the VDO if there is one
vdo = getappdata(handles.figure1,'vdo');
if isappdata(vdo.fh,'ExportDirectory')
    startDirectory = getappdata(vdo.fh,'ExportDirectory');
else
    startDirectory = pwd;
end
% Prompt for filename and export
switch getappdata(handles.figure1,'analysisType')
    case 'vep score'
        defaultName = 'grpMags';
    case 'vep latency'
        defaultName = 'grpLats';
end
switch exportType
    case 'Postscript'
        if nargin < 3 ||isempty(filename)
            [filename, pathname] = uiputfile([startDirectory '*.eps'],...
                'Save figure as eps',[defaultName '.eps']);
        else
            pathname = '';
        end
        if ~isequal(filename,0) || ~isequal(pathname,0)
            print(fh,'-depsc',fullfile(pathname,filename));
        end
    case 'JPEG'
        if nargin < 3 ||isempty(filename)
            [filename, pathname] = uiputfile([startDirectory '*.jpeg'],...
                'Save figure as jpeg',[defaultName 'jpeg']);
        else
            pathname = '';
        end
        if ~isequal(filename,0) || ~isequal(pathname,0)
            print(fh,'-djpeg',fullfile(pathname,filename));
        end
end
delete(fh);
end

function setupForDataExport(handles)
options = {'Table' 'Indexed'};
set(handles.exportMenu,'String',options,'Value',1,...
    'ToolTipString','Select data export format option');
set(handles.exportDataButton,'Callback',...
    @(hObject,eventdata)executeDataExport_Callback(hObject,eventdata,guidata(hObject)),...
    'ToolTipString','Export data to spreadsheet');
end

function executeDataExport_Callback(hObject,evntData,handles)

% Get all selected data from the GUI
vdo = getappdata(handles.figure1,'vdo');
colNames = get(handles.selectionTable,'ColumnName');
rowNames = get(handles.selectionTable,'RowName');
tableData = get(handles.selectionTable,'Data');
normFlag = strcmp(get(handles.normalizeMenu,'Checked'),'on');
avgByAnimalFlag = strcmp(get(handles.avgByAnimalMenu,'Checked'),'on');
showSrc = true;
exportTypes = get(handles.exportMenu,'String');
exportType = exportTypes{get(handles.exportMenu,'Value')};
switch exportType
    case 'Table'
        outputType = 'Columns';
        defaultName = 'StatTable_Cols.csv';
    case 'Indexed'
        outputType = 'Indexed';
        defaultName = 'StatTable_Indexed.csv';
    otherwise
        errordlg(sprintf('Unknown export type error %s',exportType));
        return
end

% Prompt for output file
prompt = sprintf('Export group data to csv file');
[filename, filepath] = uiputfile('*.csv',prompt,defaultName);
if isequal(filename,0) || isequal(filepath,0) % user selected cancel
    return;
end
fid = fopen(fullfile(filepath,filename),'wb');

% Send column selections row-wise to the export routine
nR = length(rowNames);
if nR == 0
    nR = 1;
    rowNames = {'Row1'};
end
% nC = length(colNames);
for iR = 1:nR
    if iR == 1
        printHeader = true;
    else
        printHeader = false;
    end
    rowName = rowNames{iR};
    grpKeys = tableData(iR,:);
    generateStatsTableForGroups(vdo,...
        grpKeys,'',rowName,printHeader,normFlag,avgByAnimalFlag,showSrc,...
        fid,outputType,colNames);
end
fclose(fid);
end

function grpPanel_Callback(hObject, eventdata, handles)
try
    set(handles.figure1,'Pointer','watch');
    drawnow;
    toggleGroupType(getappdata(handles.figure1,'dpo'))
catch ME
    handleError(ME,true,handles.mFileName);
end
set(handles.figure1,'Pointer','arrow');
end

function plotTypePanel_Callback(hObject, eventdata, handles)
dpo = getappdata(handles.figure1,'dpo');
try
    set(handles.figure1,'Pointer','watch');
    drawnow;
    dpo.setRenderType(get(get(hObject,'SelectedObject'),'String'));
    updateGUI(hObject);
catch ME
    handleError(ME,true,handles.mFileName);
end
set(handles.figure1,'Pointer','arrow');
end

function SetPlotStyle(handles,renderTypeString)
if isa(handles,'double') || isa(handles,'matlab.ui.Figure')
    handles = findHandles(handles);
end
try
    radioButtons = get(handles.plotTypePanel,'Children');
    switch lower(renderTypeString)
        case 'bar'
            hObject = findobj(radioButtons,'Tag','barPlotButton');
        case 'box'
            hObject = findobj(radioButtons,'Tag','boxPlotButton');
        case 'notched box'
            hObject = findobj(radioButtons,'Tag','notchBoxBotton');
        case 'line'
            hObject = findobj(radioButtons,'Tag','linePlotButton');
        otherwise
            error('unknown renderType %s',renderType);
    end
    %handles.plotTypePanel.SelectedObject = hObject;
    set(handles.plotTypePanel,'SelectedObject',hObject);
    plotTypePanel_Callback(handles.plotTypePanel, [], handles);
catch ME
    handleError(ME,true,handles.mFileName);
end
end

function exportdpo_Callback(hObject, eventdata, handles)
% Temporary function to put the dpo where the user can get at it
fprintf('GroupDataBarPlotter: Transfering dpo to base workspace\n');
assignin('base','dpo',getappdata(handles.figure1,'dpo'))
end

% Routines to try and Autofill the selection table ------------------------
% -------------------------------------------------------------------------

function autofillButton_Callback(hObject,eventdata,handles)
AutoFill(handles)
end

function AutoFill(handles)
% Use the group names to attempt and fill in the table based on class and
% condition names

if isa(handles,'double') || isa(handles,'matlab.ui.Figure')
    handles = findHandles(handles);
end
set(handles.figure1,'Pointer','watch');
drawnow;
try
    groupKeys = getappdata(handles.figure1,'groupKeys');
    lowerKeys = groupKeys;
    for iG = 1:length(groupKeys)
        theKey = groupKeys{iG};
        lowerKeys{iG} = lower(theKey(~isspace(theKey)));
    end
    condNames = get(handles.selectionTable,'ColumnName');
    if isempty(condNames)
        condNames = {' '};
    end
    for iC = 1:length(condNames)
        theName = condNames{iC};
        condNames{iC} = lower(theName(~isspace(theName)));
    end
    classNames = get(handles.selectionTable,'RowName');
    if isempty(classNames)
        classNames = {' '};
    end
    for iC = 1:length(classNames)
        theName = classNames{iC};
        classNames{iC} = lower(theName(~isspace(theName)));
    end
    dataTable = get(handles.selectionTable,'Data');
    for iC = 1:length(condNames)
        for iR = 1:length(classNames)
            ind = false(1,length(groupKeys));
            guesses = { ...
                sprintf('%s_%s',condNames{iC},classNames{iR}) ...
                sprintf('%s%s',condNames{iC},classNames{iR}) ...
                sprintf('%s_%s',classNames{iR},condNames{iC}) ...
                sprintf('%s%s',classNames{iR},condNames{iC}) ...
                sprintf('%s-%s',condNames{iC},classNames{iR}) ...
                sprintf('%s-%s',classNames{iR},condNames{iC}) ...
                };
            for iG = 1:length(guesses)
                ind = ind | strcmp(lowerKeys,guesses{iG});
            end
            if sum(ind) == 1
                dataTable{iR,iC} = groupKeys{ind};
                % fprintf('row %i col %i: %s %s GrpName = %s \n',...
                %     iR,iC,condNames{iC},classNames{iR},groupKeys{ind});
            end
        end
    end
    set(handles.selectionTable,'Data',dataTable);
    updateGUI(handles.figure1);
catch ME
    handleError(ME,true,handles.mFileName);
end
set(handles.figure1,'Pointer','arrow');
end

% Programatic interface functions -----------------------------------------
% -------------------------------------------------------------------------

function newClass(handles,className)
% Wrapper function for programatic interface - add as row in GUI table
newRow(handles,className);
end

function newCondition(handles,condName)
% Wrapper function for programatic interface - add as column in GUI table
newColumn(handles,condName);
end

function ExportFigure(figH,exportType,filename)
% Export Type can be 'Figure Only','JPEG',or 'Postscript'
if nargin < 2 || isempty(exportType)
    exportType = 'Figure Only';
end
if nargin < 3
    filename = '';
end
exportFigure(findHandles(figH),exportType,filename)
end

function close(figH)
closereq_Callback(figH)
end

function setAverageByAnimal(figH,onOrOff)
handles = guidata(figH);
switch lower(onOrOff)
    case 'on'
        set(handles.avgByAnimalMenu,'Checked','on');
    case 'off'
        set(handles.avgByAnimalMenu,'Checked','off');
end
updateGUI(handles.figure1);
end

function selectAnalysisType(figH,analysisType)
handles = guidata(figH);
setAnalysisType(figH,handles,analysisType);
end
