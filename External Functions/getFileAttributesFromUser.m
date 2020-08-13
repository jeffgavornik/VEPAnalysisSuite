function varargout = getFileAttributesFromUser(varargin)
% Allow user to specify the data attributes of data for a particular plx 
% file

%#ok<*INUSD,*INUSL,*DEFNU>

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @getAttributesFromUser_OpeningFcn, ...
                   'gui_OutputFcn',  @getAttributesFromUser_OutputFcn, ...
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


function getAttributesFromUser_OpeningFcn(hObject, eventdata, handles, varargin)
set(hObject,'CloseRequestFcn',@(src,event)closeWithVerify(src,event,guidata(src)));
handles.outputValues = {};
guidata(hObject, handles);
if numel(varargin) > 0
    set(handles.figure1,'Name',varargin{1}.fileName);
end
uiwait(handles.figure1); % hold till accept button is pushed

function closeWithVerify(src,event,handles)
uiresume;

function varargout = getAttributesFromUser_OutputFcn(hObject, eventdata, handles)
disp('getAttributesFromUser_OutputFcn')
varargout = handles.outputValues;
delete(handles.figure1);

function animalID_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function sessionName_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function viewingEye_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function acceptButton_Callback(hObject, eventdata, handles)
animalID = get(handles.animalID,'string');
sessionName = get(handles.sessionName,'string');
% viewingEyeStrings = get(handles.viewingEye,'string');
% switch viewingEyeStrings{get(handles.viewingEye,'value')}
%     case 'Right'
%         viewingEye = 'R';
%     case 'Left'
%         viewingEye = 'L';
%     case 'Binocular'
%         viewingEye = 'B';
% end
viewingEye = 'N/A';
handles.outputValues{1} = animalID;
handles.outputValues{2} = sessionName;
handles.outputValues{3} = viewingEye;
guidata(hObject, handles);
uiresume; % this will trigger output function
