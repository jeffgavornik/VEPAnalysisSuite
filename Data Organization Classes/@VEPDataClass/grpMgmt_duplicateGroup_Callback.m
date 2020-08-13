function grpMgmt_duplicateGroup_Callback(obj)
% Duplicate an existing group
try
    % Get the selected group to duplicate
    handles = guidata(obj.fh_grpMgmt);
    oldGrpKey = get(handles.selectedGroupPanel,'Title');
    oldGrp = obj.groupRecords(oldGrpKey);
    % Select a name for the new group
    grpKey = inputdlg('Enter new group name','Duplicate Group');
    if isempty(grpKey)
        return;
    end
    % Create a new group and copy the data from the old group
    newGrp = obj.createNewGroup(grpKey{:},class(oldGrp));
    newGrp.copyExistingGroup(oldGrp);
    % Select the new group in the GUI
    setappdata(handles.groupBox,'overrideSelection',grpKey{:})
    % Update gui
    notify(obj,'RefreshGUINeeded')
    notify(obj,'GrpMgmtRefreshGUINeeded')
catch ME
    error('grpMgmt_duplicateGroup_Callback Failed:\nReport\n%s\n',...
        getReport(ME));
end