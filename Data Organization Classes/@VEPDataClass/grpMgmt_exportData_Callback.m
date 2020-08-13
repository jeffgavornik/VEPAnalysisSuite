function grpMgmt_exportData_Callback(obj,exportTarget,allGroups)

if nargin == 2
    allGroups = false;
end

if allGroups 
    groups = obj.groupRecords.values;
    grpKeys = obj.groupRecords.keys;
else
    handles = guidata(obj.fh_grpMgmt);
    grpKey = get(handles.selectedGroupPanel,'Title');
    groups = {obj.groupRecords(grpKey)};
    grpKeys = {grpKey};
end

for iG = 1:length(groups)
    theGrp = groups{iG};
    switch exportTarget
        case 'csv'
            % Export selected group data to .csv file
            prompt = sprintf('Export data for group %s',grpKeys{iG});
            defaultName = sprintf('%s.csv',grpKeys{iG});
            [filename, pathname] = uiputfile('*.csv',prompt,defaultName);
            if isequal(filename,0) || isequal(pathname,0) % user selected cancel
                return;
            end
            theGrp.exportDataToFile(fullfile(pathname,filename));
        case 'workspace'
            % Send data to the workspace
            theGrp.exportDataToWorkspace();
        otherwise
            error('unknown export target %s',exportTarget);
    end
end