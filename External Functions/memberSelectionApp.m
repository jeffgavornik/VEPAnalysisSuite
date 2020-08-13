function varargout = memberSelectionApp(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @memberSelectionApp_OpeningFcn, ...
    'gui_OutputFcn',  @memberSelectionApp_OutputFcn, ...
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

function varargout = memberSelectionApp_OutputFcn(~, ~, handles)
varargout{1} = handles.output;
end

function memberSelectionApp_OpeningFcn(hObject, ~, handles, varargin)

% Choose default command line output for memberSelectionApp
handles.output = hObject;

% Associate the app with instances of groupDataRecordClass and VEPDataClass
handles.gdro = varargin{1};
set(handles.grpNameTxt,'String',sprintf('Group: %s',handles.gdro.ID));
handles.vdo = handles.gdro.parent;
handles.gdro.manageGroup;

% Create a template that will be used to get the keys
setappdata(handles.figure1,'dsoTemplate',...
    getDataSpecifierTemplate('kidKeys'));

% Create cell arrays that will hold the keys for each layer of the hiearchy
% and put in the animalKeys
animalKeys = handles.vdo.getAnimalKeys;
animalKeysCell = cell(numel(animalKeys),2);
animalKeysCell(:,1) = {0};
animalKeysCell(:,2) = animalKeys';
setappdata(handles.figure1,'animalKeys',animalKeysCell);
setappdata(handles.figure1,'sessionKeys',cell(0,2));
setappdata(handles.figure1,'stimKeys',cell(0,2));
setappdata(handles.figure1,'channelKeys',cell(0,2));

addlistener(handles.vdo,'CloseMemberSelection',...
    @(src,event)closereq);
addlistener(handles.vdo,'CloseViewers',...
    @(src,event)closereq);

% Update handles structure
guidata(hObject, handles);

% Draw the table
drawTable(handles);

end

% Populate the uiTable
function drawTable(handles)
% Figure out how many rows of data are needed
nAnimals = size(getappdata(handles.figure1,'animalKeys'),1);
nSessions = size(getappdata(handles.figure1,'sessionKeys'),1);
nStims = size(getappdata(handles.figure1,'stimKeys'),1);
nChannels = size(getappdata(handles.figure1,'channelKeys'),1);
nRows = max([nAnimals,nSessions,nStims,nChannels]);
% Create an empty cell array to hold the data
tableContents = cell(nRows,8);
% Add the appropriate keys for the current selections
tableContents(1:nAnimals,1:2) = getappdata(handles.figure1,'animalKeys');
colFormats = get(handles.selectionTable,'ColumnFormat');
validCols = 2;
if nSessions > 0
    tableContents(1:nSessions,3:4) = ...
        getappdata(handles.figure1,'sessionKeys');
    colFormats{3} = 'logical';
    validCols = 4;
    if nSessions == 1 && ~tableContents{1,3}
        autoEventData.Indices = [1 4];
    end
else
    tableContents(1:nRows,3:4) = {''};
    colFormats{4} = [];
end
if nStims > 0
    tableContents(1:nStims,5:6) = getappdata(handles.figure1,'stimKeys');
    colFormats{5} = 'logical';
    validCols = 6;
    if nStims == 1 && ~tableContents{1,5}
        autoEventData.Indices = [1 6];
    end
else
    tableContents(1:nRows,5:6) = {''};
    colFormats{6} = [];
end
if nChannels > 0
    tableContents(1:nChannels,7:8) = getappdata(handles.figure1,'channelKeys');
    colFormats{7} = 'logical';
    validCols = 8;
    if nChannels == 1 && ~tableContents{1,7}
        autoEventData.Indices = [1 8];
    end
else
    tableContents(1:nRows,7:8) = {''};
    colFormats{8} = [];
end
set(handles.selectionTable,'Data',tableContents);
set(handles.selectionTable,'ColumnFormat',colFormats);
% Save the number of columns that are valid for selection
setappdata(handles.figure1,'validSelectionCols',validCols);
% Autoselect if there is a single choice
if exist('autoEventData','var')
    select_Callback(handles.vdo,autoEventData,handles);
else
    checkValidSelection(handles);
end
end

% Enable the addButton if any channels are selected
function checkValidSelection(handles)
tableData = get(handles.selectionTable,'data');
channelSelections = tableData(:,7);
enableFlag = 'off';
for iC = 1:numel(channelSelections)
    if channelSelections{iC} == true
        enableFlag = 'on';
    end
end
set(handles.addButton,'Enable',enableFlag);
end

% Pass the selected data to the group
function addButton_Callback(~, ~, handles) %#ok<DEFNU>
dsoTemplate = getappdata(handles.figure1,'dsoTemplate');
tableData = get(handles.selectionTable,'data');
channelKeys = tableData(:,8);
channelSelections = tableData(:,7);
for iC = 1:numel(channelSelections)
    if channelSelections{iC} == true
        dsoTemplate.setHierarchyLevel(4,channelKeys{iC});
        dsoTemplate.hierarchyKeys;
        handles.gdro.addDataSpecifier(dsoTemplate);
    end
end
end

% Respond to table selections
function select_Callback(~, eventdata, handles)
% % Get the list of currently selected table cells
selection = eventdata.Indices; % Get selection indices (row, col)
if ~isempty(selection)
    % Check to make sure the selection is in a valid region of the tables
    performUpdate = true;
    col = selection(1,2);
    if col <= getappdata(handles.figure1,'validSelectionCols')
        row = selection(1,1);
        dsoTemplate = getappdata(handles.figure1,'dsoTemplate');
        switch col
            case {1,2} % Animal Selection
                % Mark the selection and get the selected key
                animalKeysCell = getappdata(handles.figure1,'animalKeys');
                nAnimals = size(animalKeysCell,1);
                animalKeysCell{row,1} = true;
                animalKeysCell(1:nAnimals ~= row,1) = {false};
                setappdata(handles.figure1,'animalKeys',animalKeysCell);
                animalKey = animalKeysCell{row,2};
                % Get conditions for the selected animal
                dsoTemplate.resetDataPath();
                dsoTemplate.setHierarchyLevel(1,animalKey);
                sessionKeys = handles.vdo.getData(dsoTemplate);
                sessionKeysCell = cell(numel(sessionKeys),2);
                sessionKeysCell(:,1) = {false};
                sessionKeysCell(:,2) = sessionKeys';
                setappdata(handles.figure1,'sessionKeys',sessionKeysCell);
                % Zero out past session
                setappdata(handles.figure1,'stimKeys',cell(0,2));
                setappdata(handles.figure1,'channelKeys',cell(0,2));
            case {3,4} % Session Selection
                % Mark the selection and get the selected key
                sessionKeysCell = getappdata(handles.figure1,'sessionKeys');
                nSessions = size(sessionKeysCell,1);
                if row <= nSessions
                    sessionKeysCell{row,1} = true;
                    sessionKey = sessionKeysCell{row,2};
                    sessionKeysCell(1:nSessions ~= row,1) = {false};
                    setappdata(handles.figure1,'sessionKeys',sessionKeysCell);
                    % Get stims for the selected session
                    dsoTemplate.setHierarchyLevel(2,sessionKey,true);
                    stimKeys = handles.vdo.getData(dsoTemplate);
                    stimKeysCell = cell(numel(stimKeys),2);
                    stimKeysCell(:,1) = {false};
                    stimKeysCell(:,2) = stimKeys';
                    setappdata(handles.figure1,'stimKeys',stimKeysCell);
                    % Zero out past stim
                    setappdata(handles.figure1,'channelKeys',cell(0,2));
                else
                    performUpdate = false;
                end
            case {5,6} % Stim Selection
                % Mark the selection and get the selected key
                stimKeysCell = getappdata(handles.figure1,'stimKeys');
                nStims = size(stimKeysCell,1);
                if row <= nStims
                    stimKeysCell{row,1} = true;
                    stimKey = stimKeysCell{row,2};
                    stimKeysCell(1:nStims ~= row,1) = {false};
                    setappdata(handles.figure1,'stimKeys',stimKeysCell);
                    % Get channels for the selected stim
                    dsoTemplate.setHierarchyLevel(3,stimKey,true);
                    channelKeys = handles.vdo.getData(dsoTemplate);
                    channelKeysCell = cell(numel(channelKeys),2);
                    channelKeysCell(:,1) = {false};
                    channelKeysCell(:,2) = channelKeys';
                    setappdata(handles.figure1,'channelKeys',channelKeysCell);
                else
                    performUpdate = false;
                end
            case {7,8} % Channel Selection
                % Mark the selection
                channelKeysCell = getappdata(handles.figure1,'channelKeys');
                nChannels = size(channelKeysCell,1);
                if row <= nChannels
                    channelKeysCell{row,1} = ~channelKeysCell{row,1};
                    setappdata(handles.figure1,'channelKeys',channelKeysCell);
                else
                    performUpdate = false;
                end
        end
        if performUpdate
            drawTable(handles);
        end
    end
end
end

