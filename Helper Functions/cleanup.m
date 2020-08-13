function cleanup
% Attempts to close all figures and clear everything

state = get(0,'ShowHiddenHandles');
set(0,'ShowHiddenHandles', 'on');
hFigs = get(0,'children');
for iF = 1:numel(hFigs)
    handles = guidata(hFigs(iF));
    if isfield(handles,'figure1')
        delete(handles.figure1);
    else
        delete(hFigs(iF));
    end
end
set(0,'ShowHiddenHandles',state);
delete(get(0,'UserData'))
set(0,'UserData',[]);

evalin('base','clear all');
delete(timerfindall)
evalin('base','clear classes');
evalin('base','clear mex');
evalin('base','clear functions');
evalin('base','clear java');

if exist('PsychJavaSwingCleanup','file') == 2
  evalin('base','PsychJavaSwingCleanup');
end