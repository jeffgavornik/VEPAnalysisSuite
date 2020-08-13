function varargout = PRGratingStims_sdf(varargin)
% GUI based function to calculate the stimulus event values for a PLX data
% file generated using the stimFnc_PRGrating routine
%
% Gavornik 4/29/11

%#ok<*DEFNU>

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PRGratingStims_OpeningFcn, ...
                   'gui_OutputFcn',  @PRGratingStims_OutputFcn, ...
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


function PRGratingStims_OpeningFcn(hObject, ~, handles, varargin)
set(hObject,'CloseRequestFcn',@(src,event)closeWithVerify());
setappdata(hObject,'ReturnData',false);
uiwait(handles.figure1);
end

function closeWithVerify()
uiresume;
end

function varargout = PRGratingStims_OutputFcn(~, ~, handles)
if getappdata(handles.figure1,'ReturnData')
    varargout{1} = getappdata(handles.figure1,'Output');
else
    warning('MATLAB:badreturn',...
        '%s returning without defining data',mfilename);
    varargout{1} = [];
end
delete(handles.figure1);
end

function doneButton_Callback(hObject, ~, handles)
execute(hObject);
setappdata(handles.figure1,'ReturnData',true);
uiresume;
end

function execute(hObject)
handles = guidata(hObject);
sfs = sort(getValues(handles.sfButton));
degs = sort(getValues(handles.degButton));
cons = sort(getValues(handles.conButton));
stimValues = containers.Map;
stimValues('Noise') = 0;
count = 0;
for iSf = 1:numel(sfs)
    sf = sfs(iSf);
    for iDeg = 1:numel(degs)
        deg = degs(iDeg);
        for iCon = 1:numel(cons)
            con = cons(iCon);
            count = count + 1;
            ev_vals = 2*count-1 + [0 1];
            theKey = sprintf('%1.2fcy/%c %i%c %i%%',...
                sf,char(176),deg,char(176),con);
            stimValues(theKey) = ev_vals;
        end
    end
end
setappdata(handles.figure1,'Output',stimValues);
end

function vals = getValues(hObject)
userData = get(hObject,'UserData');
if isnumeric(userData)
    vals = userData;
else
    vals = cell2mat(userData.vals);
end
end

function sfButton_Callback(hObject, ~, ~) 
currVal = get(hObject,'UserData');
challengeStr = 'Enter Spatial Frequencies (cy/deg)';
if isnumeric(currVal)
    resp = inputdlg(challengeStr,'',1,{num2str(currVal)});
else
    resp = inputdlg(challengeStr,'',1,{currVal.valStr});
end
if ~isempty(resp)
    vals = regexp(resp,',','split');
    processSFValues(hObject,vals{:});
end
end

function processSFValues(hObject,vals)
nV = numel(vals);
if nV == 1
    newUserData = str2double(vals{:});
    buttonStr = sprintf('Spatial Frequency: %1.2f',newUserData);
else
    valStr = '';
    for iV = 1:nV
        if iV == 1
            commaStr = '';
        else
            commaStr = ',';
        end
        valStr = sprintf('%s%s%s',valStr,commaStr,vals{iV});
        vals{iV} = str2double(vals{iV});
    end
    buttonStr = sprintf('Spatial Frequencies: %s',valStr);
    newUserData = struct;
    newUserData.vals = vals;
    newUserData.valStr = valStr;
end
set(hObject,'string',buttonStr);
set(hObject,'userdata',newUserData);
end

function degButton_Callback(hObject, ~, ~)
currVal = get(hObject,'UserData');
challengeStr = 'Enter Stimulus Angles';
if isnumeric(currVal)
    resp = inputdlg(challengeStr,'',1,{num2str(currVal)});
else
    str = regexprep(currVal.valStr,char(176),'');
    resp = inputdlg(challengeStr,'',1,{str});
end
if ~isempty(resp)
    vals = regexp(resp,',','split');
    processDegValues(hObject,vals{:});
end
end

function processDegValues(hObject,vals)
nV = numel(vals);
if nV == 1
    newUserData = str2double(vals{:});
    buttonStr = sprintf('Angle: %i%c',newUserData,char(176));
else
    valStr = '';
    for iV = 1:nV
        if iV == 1
            commaStr = '';
        else
            commaStr = ',';
        end
        valStr = sprintf('%s%s%s%c',valStr,commaStr,vals{iV},char(176));
        vals{iV} = str2double(vals{iV});
    end
    buttonStr = sprintf('Angles: %s',valStr);
    newUserData = struct;
    newUserData.vals = vals;
    newUserData.valStr = valStr;
end
set(hObject,'string',buttonStr);
set(hObject,'userdata',newUserData);
end

function conButton_Callback(hObject, ~, ~)
currVal = get(hObject,'UserData');
challengeStr = 'Enter Stimulus Contrasts';
if isnumeric(currVal)
    resp = inputdlg(challengeStr,'',1,{num2str(currVal)});
else
    resp = inputdlg(challengeStr,'',1,{currVal.valStr});
end
if ~isempty(resp)
    vals = regexp(resp,',','split');
    processConValues(hObject,vals{:});
end
end

function processConValues(hObject,vals)
nV = numel(vals);
if nV == 1
    newUserData = str2double(vals{:});
    buttonStr = sprintf('Contrast: %i%%',newUserData);
else
    valStr = '';
    for iV = 1:nV
        if iV == 1
            commaStr = '';
        else
            commaStr = ',';
        end
        valStr = sprintf('%s%s%s',valStr,commaStr,vals{iV});
        vals{iV} = str2double(vals{iV});
    end
    buttonStr = sprintf('Contrasts: %s %%',valStr);
    newUserData = struct;
    newUserData.vals = vals;
    newUserData.valStr = valStr;
end
set(hObject,'string',buttonStr);
set(hObject,'userdata',newUserData);
end

function loadPredefined_Callback(src,~,handles)
switch src
    case handles.acuityMenu
        sfVals = {'0.05' '0.1' '0.2' '0.3' '0.4' '0.5' '0.6' '0.7'};
        degVals = {'45'};
        conVals = {'100'};
    case handles.contrastMenu
        sfVals = {'0.05'};
        degVals = {'45'};
        conVals = {'2' '4' '6' '8' '10' '30 ' '50' '100'};
end
processSFValues(handles.sfButton,sfVals);
processDegValues(handles.degButton,degVals);
processConValues(handles.conButton,conVals);
end

function showStims_Callback(src,~,handles)
execute(src);
stimValues = getappdata(handles.figure1,'Output');
stimKeys = stimValues.keys;
nS = numel(stimKeys);
stringCell = cell(1,nS);
for iS = 1:nS
    theKey = stimKeys{iS};
    theVals = stimValues(theKey);
    outStr = sprintf('%i: ''%s'' = [',iS,theKey);
    for iV = 1:numel(theVals)
        outStr = sprintf('%s %i',outStr,theVals(iV));
    end
    outStr = sprintf('%s ]',outStr);
    stringCell{iS} = outStr;
    disp(stringCell{iS})
end
fig = openfig('stimTable.fig','new','invisible');
figHandles = guihandles(fig);
guidata(fig,figHandles);
set(figHandles.listbox1,'String',stringCell);
set(fig,'Visible','on');
end