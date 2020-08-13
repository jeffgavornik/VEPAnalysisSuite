function removeButton_Callback(obj)

handles = guidata(obj.fh);
selectionKeys = get(handles.groupMembersBox,'String');
iSelection = get(handles.groupMembersBox,'Value');
if iSelection == numel(selectionKeys)
    set(handles.groupMembersBox,'Value',iSelection - 1);
end
selectionKey = selectionKeys{iSelection};
obj.removeFromGroup(selectionKey);
end