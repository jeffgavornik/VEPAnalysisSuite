function norm_ScalarUpdateGUI_Callback(obj)
% Update the GUI - if a group has been selected, save its data to the
% appdata

handles = guidata(obj.fh_n);
if isappdata(obj.fh_n,'overrideGUISelection')
    selKey = getappdata(obj.fh_n,'overrideGUISelection');
    rmappdata(obj.fh_n,'overrideGUISelection');
else
    % Get the existing selection value from the GUI
    oldKeys = get(handles.sourceMenu,'String');
    oldVal = get(handles.sourceMenu,'Value');
    if ~iscell(oldKeys)
        oldKeys = {oldKeys};
    end
    selKey = oldKeys{oldVal};
end

% Populate the sourceMenu with the name of all valid groups (ie groups that
% have a method called returnGroupMean)
selectionValues{1} = 'Manual';
vdo = obj.parent;
groupKeys = vdo.groupRecords.keys;
for iG = 1:numel(groupKeys)
    theKey = groupKeys{iG};
    theGroup = vdo.groupRecords(theKey);
    if ismethod(theGroup,'returnGroupMean')
        selectionValues{end+1} = theGroup.ID; %#ok<AGROW>
    end
end
set(handles.sourceMenu,'string',selectionValues);

% If the selection is valid, use it
selVal = find(strcmp(selectionValues,selKey));
if isempty(selVal)
    % Manual selection by default if the old selected key is not valid
    set(handles.sourceMenu,'Value',1);
    set(handles.normValue,'String','');
    set(handles.doneButton,'Enable','off');
else
    set(handles.sourceMenu,'Value',selVal);
    normFactors = getappdata(obj.fh_n,'normFactors');
    switch selKey
        case 'Manual'
            % Indicate manual source 
            normValue = normFactors('scalar');
            normFactors('dataSrc') = 'Manual';
            setappdata(obj.fh_n,'normDescStr',...
                sprintf('Manual Selection\nValue = %1.2f',...
                normValue));
            obj.normFactors('NormGrpKey') = '';
        otherwise
            % Use the mean value from a selected group
            theGroup = vdo.groupRecords(selKey);
            obj.normFactors('NormGrpKey') = selKey;
            try
                if get(handles.avgByAnimalCheckBox,'Value')
                    normValue = theGroup.returnGroupMean('AverageByAnimal');
                    obj.normFactors('AverageByAnimals') = true;
                else
                    normValue = theGroup.returnGroupMean();
                    obj.normFactors('AverageByAnimals') = false;
                end
            catch ME
                fprintf(2,'%s.returnGroupMean failed for %s\nReport:%s',...
                    class(theGroup),theGroup.ID,ME.getReport);
                normValue = 1;
            end
            normFactors('dataSrc') = selKey;
            % Save to app data
            setappdata(obj.fh_n,'normDescStr',...
                sprintf('''%s'' Group Mean\nValue = %1.2f',...
                selKey,normValue));
    end
    normFactors('scalar') = normValue;
    setappdata(obj.fh_n,'normFactors',normFactors);
    set(handles.normValue,'String',sprintf('%1.2f',normValue));
    set(handles.doneButton,'Enable','on');
end