function grpMgmt_renameGroup_Callback(obj)
% Rename an existing group

handles = guidata(obj.fh_grpMgmt);
grpKey = get(handles.selectedGroupPanel,'Title');
userResponse = inputdlg(sprintf('Enter new name for group ''%s''',grpKey),...
    'Group Rename',1);
if isempty(userResponse)
    return;
end
newKey = userResponse{:};
theGroup = obj.groupRecords(grpKey);
theGroup.ID = newKey;
obj.groupRecords.remove(grpKey);
obj.groupRecords(newKey) = theGroup;
notify(obj,'GrpMgmtRefreshGUINeeded');