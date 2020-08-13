function stimDef_guiCallbacks(obj,src,eventdata)

%#ok<*NASGU,*ST2NM>

handles = guihandles(obj.fh);

switch src
    case handles.metaOverrideBox
        obj.ignoreMetaData = get(handles.metaOverrideBox,'Value');
    case handles.deleteButton
        % Respond to the delete button, remove selected stims from the stimDef
        dataCell = get(handles.stimTable,'Data');
        deleteRows = cell2mat(dataCell(:,1));
        stimDefs = obj.stimDefs;
        for iR = 1:size(dataCell)
            stimKey = dataCell{iR,2};
            if deleteRows(iR) && isKey(stimDefs,stimKey)
                remove(stimDefs,stimKey);
            end
        end
        % Write-back new table so that col-1 data won't be preserved
        set(handles.stimTable,'Data',dataCell(~deleteRows,:));
        obj.stimDefStr = 'Manual Stim Definition';
        notify(obj,'RefreshGUINeeded');
    otherwise
        % Respond to table selections and edits
        % In the event of a selection, eventdata will have one field called Indices
        % that specifys the row and col selected
        % In the event of an edit, the event will also have the fields
        % PreviousData, EditData, NewData, and Error
        
        % Identify the edited table element
        if numel(eventdata.Indices) == 0
            return;
        end
        row = eventdata.Indices(1);
        col = eventdata.Indices(2);
        
        % Get the existing table data from the GUI
        dataCell = get(handles.stimTable,'Data');
        
        switch class(eventdata)
            case 'matlab.ui.eventdata.CellSelectionChangeData'
                % If simply that the selection has changed, we don't need to do anything
                % unless the selection is in column 1.
                if col == 1
                    % Manually toggle column one selection events - note, it should be possible
                    % to just make this column editable and not watch for selection, but some
                    % strange bug prevents more than 2 selection in 7.14.0.739 (R2012a) so
                    % doing it this way instead
                    if row>0
                        % Hack into java to reset scroll-bar position
                        jObj = findjobj(handle(handles.stimTable));
                        vScrollBar = jObj.getVerticalScrollBar;
                        scrollValue = get(vScrollBar,'Value');
                        dataCell{row,1} = ~dataCell{row,1};
                        set(handles.stimTable,'Data',dataCell);
                        drawnow
                        set(vScrollBar,'Value',scrollValue);
                        % value = ~dataCell{row,1};
                        % jObj = findjobj(handle(handles.stimTable));
                        % jtable = jObj.getViewport.getComponent(0);
                        % jtable.setValueAt(value,row-1,0);
                    end
                end
            case 'matlab.ui.eventdata.CellEditData'
                % fprintf('table selection row=%i, col=%i\n',row,col);
                % fprintf('oldData = %s, newData = %s\n',eventdata.PreviousData,eventdata.NewData);
                [rows,~] = size(dataCell);
                oldKey = ''; % Will be assigned if a key changes
                switch col
                    case 2 % Stimulus name change or addition
                        % Make sure the edited name is not a duplicate
                        rowNumbers = 1:rows;
                        otherStims = dataCell(rowNumbers(rowNumbers ~= row),2);
                        if sum(strcmp(eventdata.NewData,otherStims)) ~= 0
                            dataCell{row,col} = eventdata.PreviousData;
                            warndlg('Duplicate stimulus names are not allowed');
                            set(handles.stimTable,'Data',dataCell);
                            return;
                        end
                        oldKey = eventdata.PreviousData;
                    case 3 % Stimulus defition change or addition
                        % Make sure the entry is valid
                        values = str2num(eventdata.NewData);
                        if isempty(values)
                            dataCell{row,col} = eventdata.PreviousData;
                            warndlg('Invalid conversion to numerical data');
                            set(handles.stimTable,'Data',dataCell);
                            return;
                        elseif sum(mod(values,1)~=0)
                            dataCell{row,col} = eventdata.PreviousData;
                            warndlg('Stim values must be integers');
                            set(handles.stimTable,'Data',dataCell);
                            return;
                        end
                end
                % Update the stimulus definitions if a valid edit has been made and redraw
                % the GUI
                stimName = dataCell{row,2};
                stimValues = dataCell{row,3};
                if ~isempty(stimName) && ~isempty(stimValues)
                    stimDefs = obj.stimDefs;
                    if isKey(stimDefs,oldKey)
                        remove(stimDefs,oldKey);
                    end
                    stimDefs(stimName) = str2num(stimValues);
                    obj.stimDefStr = 'Manual Stim Definition';
                    notify(obj,'RefreshGUINeeded');
                end
                % fprintf('table selection row=%i, col=%i\n',row,col);
                % fprintf('oldData = %s, newData = %s\n',eventdata.PreviousData,eventdata.NewData);
                % fprintf('dataCell = %s\n',dataCell{row,col});
        end
        
end