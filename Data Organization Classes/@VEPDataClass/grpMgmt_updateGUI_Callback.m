function grpMgmt_updateGUI_Callback(obj)

if ~isempty(obj.fh_grpMgmt)    
    handles = guidata(obj.fh_grpMgmt);
    % Get the current group selection key
    selVal = get(handles.groupBox,'Value');
    existingKeys = get(handles.groupBox,'String');
    if iscell(existingKeys)
        if isempty(existingKeys)
            currentKey = '';
        else
            currentKey = existingKeys{selVal};
        end
    else
        currentKey = existingKeys;
    end
    % Populate the Groups Listbox with all group keys
    grpKeys = obj.groupRecords.keys;
    set(handles.groupBox,'String',grpKeys);
    
    % Look to see if anything has overridden the group selection
    if isappdata(handles.groupBox,'overrideSelection')
        currentKey = getappdata(handles.groupBox,'overrideSelection');
        rmappdata(handles.groupBox,'overrideSelection');
    end
    % Try to maintain the current selection or make a default selection
    selVal = find(strcmp(grpKeys,currentKey));
    if isempty(selVal)
        selVal = 1;
    end
    if iscell(grpKeys)
        if isempty(grpKeys)
            selKey = '';
        else
            selKey = grpKeys{selVal};
        end
    else
        selKey = '';
    end
    set(handles.groupBox,'Value',selVal);
    % Define the GUI controls used for group modification
    grpMonCntrls = [handles.deleteGroupButton handles.renameButton ...
        handles.duplicateButton handles.addMemberButton ...
        handles.deleteMemberButton handles.normMenu...
        handles.levelMenu handles.keyValueTxt handles.executeButton];
    
    if isempty(selKey)
        % Populate the selectedGroupPanel with no data
        set(handles.selectedGroupPanel,'Title','');
        set(handles.groupMembersBox,'String','');
        set(handles.normSelectorTxt,'String','');
        % normButtonPanel
        % Disable group modification contols
        set(grpMonCntrls,'Enable','off');
    else
        % Populate the selectedGroupPanel with data for the selected group
        set(handles.selectedGroupPanel,'Title',selKey);
        theGroup = obj.groupRecords(selKey);
        % Get the current member selection
        selVal = get(handles.groupMembersBox,'Value');
        if selVal < 1
            selVal = 1;
        end
        existingKeys = get(handles.groupMembersBox,'String');
        if iscell(existingKeys)
            if isempty(existingKeys)
                currentKey = '';
            else
                currentKey = existingKeys{selVal};
            end
        else
            currentKey = existingKeys;
        end
        % Populate the member selection box
        memberKeys = theGroup.getDataDescriptions;
        set(handles.groupMembersBox,'String',memberKeys);
        % If possible, maintain the current member selection
        selVal = find(strcmp(memberKeys,currentKey));
        if isempty(selVal)
            selVal = 1;
        end
        set(handles.groupMembersBox,'Value',selVal);
        % Setup the group normalization panel
        normTypes = ...
            eval(sprintf('%s.getSupportedNormTypes',class(theGroup)));
        set(handles.normMenu,'String',normTypes);
        normType = theGroup.getNormType;
        set(handles.normMenu,'Value',...
            find(strcmp(normTypes,normType)));
        set(handles.normSelectorTxt,'String',...
            theGroup.getNormDescription);
        if strcmp(normType,'None')
            set(handles.selectNormButton,'Enable','off');
        else
            set(handles.selectNormButton,'Enable','on');
        end
        % Enable group modification contols
        set(grpMonCntrls,'Enable','on');
    end
    
end