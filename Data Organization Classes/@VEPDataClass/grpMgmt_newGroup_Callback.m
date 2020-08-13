function grpMgmt_newGroup_Callback(obj)
try
    grpKey = inputdlg('Enter new group name','Create new group');
    if isempty(grpKey)
        return
    end
    obj.createNewGroup(grpKey{:},'VEPMagGroupClass');
    % Select the new group in the GUI
    handles = guidata(obj.fh_grpMgmt);
    setappdata(handles.groupBox,'overrideSelection',grpKey{:})
    % Update gui
    notify(obj,'RefreshGUINeeded')
    notify(obj,'GrpMgmtRefreshGUINeeded')
catch ME
    fprintf('grpMgmt_newGroup_Callback Failed:\nReport\n%s\n',...
        getReport(ME));
end