function memSel_addButton_Callback(obj)
% Pass the selected data to the group
handles = guidata(obj.fh_memSel);
dsoTemplate = getappdata(handles.figure1,'dsoTemplate');
tableData = get(handles.selectionTable,'data');
channelKeys = tableData(:,8);
channelSelections = tableData(:,7);
for iC = 1:numel(channelSelections)
    if channelSelections{iC} == true
        dsoTemplate.setHierarchyLevel(4,channelKeys{iC});
        groupKey = get(handles.grpNameTxt,'String');
        theGroup = obj.groupRecords(groupKey);
        theGroup.addDataSpecifier(dsoTemplate);
    end
end
end