function varargout = CIRatioAnalysisViewer(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CIRatioAnalysisViewer_OpeningFcn, ...
                   'gui_OutputFcn',  @CIRatioAnalysisViewer_OutputFcn, ...
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


% --- Executes just before CIRatioAnalysisViewer is made visible.
function CIRatioAnalysisViewer_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for CIRatioAnalysisViewer
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = CIRatioAnalysisViewer_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;
