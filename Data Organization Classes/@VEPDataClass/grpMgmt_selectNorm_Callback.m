function grpMgmt_selectNorm_Callback(obj)
% Tell the group object to normalize the data based on user selection

handles = guidata(obj.fh_grpMgmt);
normTypes = get(handles.normMenu,'String');
normType = normTypes{get(handles.normMenu,'Value')};
grpKey = get(handles.selectedGroupPanel,'Title');
theGrp = obj.groupRecords(grpKey);
theGrp.setNormType(normType);
notify(obj,'RefreshGUINeeded')
notify(obj,'GrpMgmtRefreshGUINeeded')