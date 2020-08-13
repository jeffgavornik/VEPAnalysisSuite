function grpMgmt_deleteMember_Callback(obj)
% Delete an existing group

handles = guidata(obj.fh_grpMgmt);

% Get the selection from the GUI
selectionKeys = get(handles.groupMembersBox,'String');
iSelection = get(handles.groupMembersBox,'Value');
if iSelection == numel(selectionKeys)
    set(handles.groupMembersBox,'Value',iSelection - 1);
end
selectionKey = selectionKeys{iSelection};

% Delete the selection from the group
grpKey = get(handles.selectedGroupPanel,'Title');
theGroup = obj.groupRecords(grpKey);
theGroup.removeFromGroup(selectionKey);

end