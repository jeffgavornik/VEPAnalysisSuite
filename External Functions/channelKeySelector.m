function varargout = channelKeySelector(varargin)

%#ok<*INUSD,*INUSL,*DEFNU>

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @channelKeySelector_OpeningFcn, ...
                   'gui_OutputFcn',  @channelKeySelector_OutputFcn, ...
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

function channelKeySelector_OpeningFcn(hObject, eventdata, handles, varargin)
% Populate the panels with the channel keys and wait for the user to make a
% selection
set(hObject,'CloseRequestFcn',...
    @(src,event)closeWithVerify(src,event,guidata(src)));
channelKeys = varargin{1}; % Cell array with all key choices
currentCh1Key = varargin{2}; % Current ch1 selection key
iCh1 = find(strcmp(channelKeys,currentCh1Key));
currentCh2Key = varargin{3}; % current ch2 selection key
iCh2 = find(strcmp(channelKeys,currentCh2Key));

set(handles.ch1Menu,'String',channelKeys,'Value',iCh1);
set(handles.ch2Menu,'String',channelKeys,'Value',iCh2);

% nCh = numel(channelKeys);
% pos0 = [.05 0.85 .75 .1];
% handles.buttonHandles = zeros(2,nCh);
% for iCh = 1:nCh
%     pos = pos0 - [0 (iCh-1)*0.1 0 0];
%     value = iCh == iCh1;
%     handles.buttonHandles(1,iCh) = uicontrol('Style','radio',...
%         'Parent', handles.channel1Panel, ...
%         'Units','normalized', ...
%         'Position', pos, ...
%         'Value',value,...
%         'String',channelKeys{iCh});
%     value = iCh == iCh2;
%     handles.buttonHandles(2,iCh) = uicontrol('Style','radio',...
%         'Parent', handles.channel2Panel, ...
%         'Units','normalized', ...
%         'Position', pos, ...
%         'Value',value,...
%         'String',channelKeys{iCh});
% end
handles.returnValues = {currentCh1Key,currentCh2Key};
guidata(hObject, handles);
uiwait(handles.figure1);

function closeWithVerify(src,event,handles) 
uiresume;

% --- Outputs from this function are returned to the command line.
function varargout = channelKeySelector_OutputFcn(hObject, eventdata, handles) 
varargout = handles.returnValues;
delete(handles.figure1);

% --- Executes on button press in doneButton.
function doneButton_Callback(hObject, eventdata, handles)
% ch1Key = get(get(handles.channel1Panel,'SelectedObject'),'String');
% ch2Key = get(get(handles.channel2Panel,'SelectedObject'),'String');
% handles.returnValues = {ch1Key,ch2Key};

keys = get(handles.ch1Menu,'String');
ch1Val = get(handles.ch1Menu,'Value');
ch2Val = get(handles.ch2Menu,'Value');
handles.returnValues = keys([ch1Val ch2Val]);


guidata(hObject, handles);
uiresume;


% --- Executes on selection change in ch1Menu.
function ch1Menu_Callback(hObject, eventdata, handles)
% hObject    handle to ch1Menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ch1Menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ch1Menu


% --- Executes during object creation, after setting all properties.
function ch1Menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ch1Menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in ch2Menu.
function ch2Menu_Callback(hObject, eventdata, handles)
% hObject    handle to ch2Menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ch2Menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ch2Menu


% --- Executes during object creation, after setting all properties.
function ch2Menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ch2Menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
