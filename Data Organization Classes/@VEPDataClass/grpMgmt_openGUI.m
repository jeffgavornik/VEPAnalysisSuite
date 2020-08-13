function grpMgmt_openGUI(obj)
if isempty(obj.fh_grpMgmt)
    
    % Choose the GUI file based on system
    guiFile = 'grpMgmt.fig';
    %if ispc
    %    guiFile = sprintf('pc_%s',guiFile);
    %end
    
    % Open the GUI and create handles
    obj.fh_grpMgmt = openfig(guiFile,'new','invisible');
    handles = guihandles(obj.fh_grpMgmt);
    handles.closeListener = addlistener(obj,'CloseViewers',...
        @(src,event)grpMgmt_closeGUI(obj));
    handles.updateListener = addlistener(obj,'GrpMgmtRefreshGUINeeded',...
        @(src,event)grpMgmt_updateGUI_Callback(obj));
    guidata(obj.fh_grpMgmt,handles);
    
     % Set background to match the system default
    objects = findobj(obj.fh_grpMgmt,'-property','BackgroundColor');
    bgColor = get(0,'defaultUicontrolBackgroundColor');
    set(objects,'BackgroundColor',bgColor);
    set(obj.fh_grpMgmt,'Color',bgColor);
    
    % Setup GUI callbacks
    set(obj.fh_grpMgmt,'CloseRequestFcn',@(src,event)grpMgmt_closeGUI(obj));
    
    set(handles.groupBox,'Callback',...
        @(src,event)grpMgmt_updateGUI_Callback(obj));
    
    set(handles.newGroupButton,'Callback',...
        @(src,event)grpMgmt_newGroup_Callback(obj));
    
    set(handles.deleteGroupButton,'Callback',...
        @(src,event)grpMgmt_deleteGroup_Callback(obj));
    
    set(handles.renameButton,'Callback',...
        @(src,event)grpMgmt_renameGroup_Callback(obj));
    
    set(handles.duplicateButton,'Callback',...
        @(src,event)grpMgmt_duplicateGroup_Callback(obj));
    
    %set(handles.changeClassButton,'Callback',...
    %    @(src,event)grpMgmt_changeClass_Callback(obj));
    
    set(handles.addMemberButton,'Callback',...
        @(src,event)memSel_openGUI(obj));
    
    set(handles.deleteMemberButton,'Callback',...
        @(src,event)grpMgmt_deleteMember_Callback(obj));
    
    set(handles.selectNormButton,'Callback',...
        @(src,event)grpMgmt_configNorm_Callback(obj));
    
    set(handles.normMenu,'Callback',...
        @(src,event)grpMgmt_selectNorm_Callback(obj));
    
    set(handles.executeButton,'Callback',...
        @(src,event)grpMgmt_changeAll_Callback(obj));
    
    set(handles.exportToCSVMenu,'Callback',...
        @(src,event)grpMgmt_exportData_Callback(obj,'csv'));
    
    set(handles.exportToWorkspaceMenu,'Callback',...
        @(src,event)grpMgmt_exportData_Callback(obj,'workspace'));
    
    set(handles.exportAllToCSVMenu,'Callback',...
        @(src,event)grpMgmt_exportData_Callback(obj,'csv',true));
    
    set(handles.exportAllToWorkspaceMenu,'Callback',...
        @(src,event)grpMgmt_exportData_Callback(obj,'workspace',true));
    
    
    % Disable functions that are not available in the deployed version
    if isdeployed
        matlabOnly = [ ...
            handles.exportToCSVMenu, ...
            handles.exportToWorkspaceMenu,...
            handles.exportAllToCSVMenu,...
            handles.exportAllToWorkspaceMenu,...
            ];
        set(matlabOnly,'enable','off');
    end    
    
    
    % Call function to update the GUI
    obj.grpMgmt_updateGUI_Callback();
    
    % Make the GUI visible
    set(obj.fh_grpMgmt,'Visible','on');
else
    figure(obj.fh_grpMgmt); % raise the GUI
end

end