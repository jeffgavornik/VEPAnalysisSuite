function grpMgmt_changeClass_Callback(obj)
% Change the group class of an existing group

% Get the selected group to duplicate
handles = guidata(obj.fh_grpMgmt);
grpKey = get(handles.selectedGroupPanel,'Title');

% Select the new class
groupTypes = {'VEPMagGroupClass' 'VEPTraceGroupClass' ''};
descriptions = {'VEP Magnitudes' 'VEP Traces' 'Cancel'};
iGrp = menu('Choose Group Type',descriptions);
grpClassStr = groupTypes{iGrp};
if isempty(grpClassStr)
    return
end

% Copy the data from the old group to a new group of the selected class
oldGrp = obj.groupRecords(grpKey);
newGrp = obj.createNewGroup(grpKey,grpClassStr);
newGrp.copyExistingGroup(oldGrp);
obj.groupRecords.remove(grpKey);
obj.groupRecords(grpKey) = newGrp;

notify(obj,'GrpMgmtRefreshGUINeeded')
