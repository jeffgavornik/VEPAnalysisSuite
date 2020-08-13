function grpMgmt_deleteGroup_Callback(obj)
% Delete an existing group

handles = guidata(obj.fh_grpMgmt);
grpKey = get(handles.selectedGroupPanel,'Title');
selection = questdlg(sprintf('Really delete group ''%s''?',grpKey),...
    'Delete Group','Delete','Cancel','Cancel');
switch selection
    case 'Cancel'
        return;
    otherwise
        obj.groupRecords.remove(grpKey);
        notify(obj,'RefreshGUINeeded')
        notify(obj,'GrpMgmtRefreshGUINeeded')
end