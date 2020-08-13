function openGUI(obj)
if isempty(obj.fh)
    % Open the GUI and create handles
    obj.fh = openfig('groupDataRecord.fig','new','visible');
    handles = guihandles(obj.fh);
    guidata(obj.fh,handles);
    
    % Setup GUI callbacks
    set(obj.fh,'CloseRequestFcn',@(src,event)closeGUI(obj,src,event));
    set(handles.removeButton,'Callback',...
        @(src,event)removeButton_Callback(obj));
    set(handles.executeButton,'Callback',...
        @(src,event)executeButton_Callback(obj));
    set(handles.viewerMenu,'Callback',...
        @(src,event)viewerMenu_Callback(obj));
    set(handles.exportMenu,'Callback',...
        @(src,event)exportMenu_Callback(obj));
    
    % Configure the listbox color scheme
    if ispc && isequal(get(handles.groupMembersBox,'BackgroundColor'), ...
            get(0,'defaultUicontrolBackgroundColor'))
        set(handles.groupMembersBox,'BackgroundColor','white');
    end
    obj.updateGUI();
end
end