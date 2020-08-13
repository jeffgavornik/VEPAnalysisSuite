function varargout = BaseDataViewer(varargin)
% BASEDATAVIEWER MATLAB code for BaseDataViewer.fig
%      BASEDATAVIEWER, by itself, creates a new BASEDATAVIEWER or raises the existing
%      singleton*.
%
%      H = BASEDATAVIEWER returns the handle to a new BASEDATAVIEWER or the handle to
%      the existing singleton*.
%
%      BASEDATAVIEWER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BASEDATAVIEWER.M with the given input arguments.
%
%      BASEDATAVIEWER('Property','Value',...) creates a new BASEDATAVIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BaseDataViewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BaseDataViewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BaseDataViewer

% Last Modified by GUIDE v2.5 15-May-2012 08:17:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @BaseDataViewer_OpeningFcn, ...
                   'gui_OutputFcn',  @BaseDataViewer_OutputFcn, ...
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


% --- Executes just before BaseDataViewer is made visible.
function BaseDataViewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to BaseDataViewer (see VARARGIN)

% Choose default command line output for BaseDataViewer
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes BaseDataViewer wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = BaseDataViewer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in holdCurrentButton.
function holdCurrentButton_Callback(hObject, eventdata, handles)
% hObject    handle to holdCurrentButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in deleteSelectedButton.
function deleteSelectedButton_Callback(hObject, eventdata, handles)
% hObject    handle to deleteSelectedButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in hideCurrentBox.
function hideCurrentBox_Callback(hObject, eventdata, handles)
% hObject    handle to hideCurrentBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hideCurrentBox


% --- Executes on button press in annotationsBox.
function annotationsBox_Callback(hObject, eventdata, handles)
% hObject    handle to annotationsBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of annotationsBox


% --- Executes on button press in resetPlotsBox.
function resetPlotsBox_Callback(hObject, eventdata, handles)
% hObject    handle to resetPlotsBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of resetPlotsBox


% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in xDraggingButton.
function xDraggingButton_Callback(hObject, eventdata, handles)
% hObject    handle to xDraggingButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of xDraggingButton


% --- Executes on button press in yDraggingButton.
function yDraggingButton_Callback(hObject, eventdata, handles)
% hObject    handle to yDraggingButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of yDraggingButton


% --- Executes on selection change in animalMenu.
function animalMenu_Callback(hObject, eventdata, handles)
% hObject    handle to animalMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns animalMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from animalMenu


% --- Executes during object creation, after setting all properties.
function animalMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to animalMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in sessionMenu.
function sessionMenu_Callback(hObject, eventdata, handles)
% hObject    handle to sessionMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionMenu


% --- Executes during object creation, after setting all properties.
function sessionMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sessionMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in stimulusMenu.
function stimulusMenu_Callback(hObject, eventdata, handles)
% hObject    handle to stimulusMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns stimulusMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from stimulusMenu


% --- Executes during object creation, after setting all properties.
function stimulusMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stimulusMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --------------------------------------------------------------------
function exportMenu_Callback(hObject, eventdata, handles)
% hObject    handle to exportMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function exportToEPSMenu_Callback(hObject, eventdata, handles)
% hObject    handle to exportToEPSMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function dataToWorkspaceMenu_Callback(hObject, eventdata, handles)
% hObject    handle to dataToWorkspaceMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function xAxesMenu_Callback(hObject, eventdata, handles)
% hObject    handle to xAxesMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function yAxesMenu_Callback(hObject, eventdata, handles)
% hObject    handle to yAxesMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function lineWidthMenu_Callback(hObject, eventdata, handles)
% hObject    handle to lineWidthMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function yAxesAutoMenu_Callback(hObject, eventdata, handles)
% hObject    handle to yAxesAutoMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function yAxesSelectMenu_Callback(hObject, eventdata, handles)
% hObject    handle to yAxesSelectMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function xAxesAutoMenu_Callback(hObject, eventdata, handles)
% hObject    handle to xAxesAutoMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function xAxesSelectMenu_Callback(hObject, eventdata, handles)
% hObject    handle to xAxesSelectMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
