function executeButton_Callback(obj)
handles = guidata(obj.fh);
level = get(handles.levelTxt,'String');
newKey = get(handles.keyTxt,'String');
if ~isempty(level) && ~isempty(newKey)
    obj.setAllSpecifiers(str2double(level),newKey);
    set(handles.levelTxt,'String','');
    set(handles.keyTxt,'String','');
end
end