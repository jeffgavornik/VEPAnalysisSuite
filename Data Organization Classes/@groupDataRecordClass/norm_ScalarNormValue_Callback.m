function norm_ScalarNormValue_Callback(obj)

% Indicate manual selection in the source menu
handles = guidata(obj.fh_n);
set(handles.sourceMenu,'Value',1);
% Udate the normalization factors and update the decription string
normValue = str2double(get(handles.normValue,'String'));
setappdata(obj.fh_n,'normDescStr',...
    sprintf('Manual Selection\nValue = %1.2f',...
    normValue));
normFactors = getappdata(obj.fh_n,'normFactors');
normFactors('scalar') = normValue;
normFactors('dataSrc') = 'Manual';
normFactors('NormGrpKey') = '';
setappdata(obj.fh_n,'normFactors',normFactors);
set(handles.doneButton,'Enable','on');