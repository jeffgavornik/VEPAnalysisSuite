function grpMgmt_changeAll_Callback(obj)
% Change all members of a group to have the save key for the specified
% level
handles = guidata(obj.fh_grpMgmt);
level = get(handles.levelMenu,'Value') - 1;
newKey = get(handles.keyValueTxt,'String');
if level > 0 && ~isempty(newKey)
    % Change all group members based on user selection and reset the
    % GUI
    grpKey = get(handles.selectedGroupPanel,'Title');
    theGroup = obj.groupRecords(grpKey);
    theGroup.setAllSpecifiers(level,newKey);
    set(handles.levelMenu,'Value',1);
    set(handles.keyValueTxt,'String','');
    notify(obj,'GrpMgmtRefreshGUINeeded');
else
    warning('VEPDataClass:GUIUsage',...
        'VEPDataClass.grpMgmt_changeAll_Callback:\n%s',...
        'Must designate both level and key value');
end
