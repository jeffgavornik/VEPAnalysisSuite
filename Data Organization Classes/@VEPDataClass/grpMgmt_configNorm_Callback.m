function grpMgmt_configNorm_Callback(obj)
% Tell the selected group to open its normalization control panel

handles = guidata(obj.fh_grpMgmt);
grpKey = get(handles.selectedGroupPanel,'Title');
theGrp = obj.groupRecords(grpKey);
theGrp.norm_openGui;