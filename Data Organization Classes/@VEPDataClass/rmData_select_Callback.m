function rmData_select_Callback(obj, eventdata)
% Respond to table selections

% Note: interface with the DSO is off by one level because we're telling
% parent objects to delete children rather than target level objects to
% return data

handles = guidata(obj.fh_rmData);

% Get the list of currently selected table cells
selection = eventdata.Indices; % Get selection indices (row, col)
if ~isempty(selection)
    % Check to make sure the selection is in a valid region of the tables
    performUpdate = true;
    col = selection(1,2);
    if col <= getappdata(handles.figure1,'validSelectionCols')
        setappdata(handles.figure1,'lastEventData',eventdata);
        set(handles.deleteButton,'Enable','on'); % Enable the delete button at any valid table selection
        row = selection(1,1);
        switch col
            case {1,2} % Animal Selection
                % Mark the selection and get the selected key
                animalKeysCell = getappdata(handles.figure1,'animalKeys');
                nAnimals = size(animalKeysCell,1);
                animalKeysCell{row,1} = true;
                animalKeysCell(1:nAnimals ~= row,1) = {false};
                setappdata(handles.figure1,'animalKeys',animalKeysCell);
                setappdata(handles.figure1,'animalRow',row);
                animalKey = animalKeysCell{row,2};
                theAnimal = obj.animalRecords(animalKey);
                % Get the session values to populate the table
                sessionKeys = theAnimal.getKidKeys;
                sessionKeysCell = cell(numel(sessionKeys),2);
                sessionKeysCell(:,1) = {false};
                sessionKeysCell(:,2) = sessionKeys';
                setappdata(handles.figure1,'sessionKeys',sessionKeysCell);
                % Zero out past session and stims
                setappdata(handles.figure1,'stimKeys',cell(0,2));
                setappdata(handles.figure1,'channelKeys',cell(0,2));
                % Save the current selection state
                setappdata(handles.figure1,'theAnimal',theAnimal);
                setappdata(handles.figure1,'targetLevel',1);
                setappdata(handles.figure1,'theSession',[]);
                setappdata(handles.figure1,'theStim',[]);
            case {3,4} % Session Selection
                % Mark the selection and get the selected key
                sessionKeysCell = getappdata(handles.figure1,'sessionKeys');
                nSessions = size(sessionKeysCell,1);
                if row <= nSessions
                    sessionKeysCell{row,1} = true;
                    sessionKey = sessionKeysCell{row,2};
                    sessionKeysCell(1:nSessions ~= row,1) = {false};
                    setappdata(handles.figure1,'sessionKeys',sessionKeysCell);
                    setappdata(handles.figure1,'sessionRow',row);
                    theAnimal = getappdata(handles.figure1,'theAnimal');
                    theSession = theAnimal.kids(sessionKey);
                    % Get stim values to populate the table
                    stimKeys = theSession.getKidKeys;
                    stimKeysCell = cell(numel(stimKeys),2);
                    stimKeysCell(:,1) = {false};
                    stimKeysCell(:,2) = stimKeys';
                    setappdata(handles.figure1,'stimKeys',stimKeysCell);
                    % Zero out past stims
                    setappdata(handles.figure1,'channelKeys',cell(0,2));
                    % Save the current selection state
                    setappdata(handles.figure1,'theSession',theSession);
                    setappdata(handles.figure1,'targetLevel',2);
                    setappdata(handles.figure1,'theStim',[]);
                else
                    performUpdate = false;
                end
            case {5,6} % Stim Selection
                % Mark the selection and get the selected key
                stimKeysCell = getappdata(handles.figure1,'stimKeys');
                nStims = size(stimKeysCell,1);
                if row <= nStims
                    stimKeysCell{row,1} = true;
                    stimKey = stimKeysCell{row,2};
                    stimKeysCell(1:nStims ~= row,1) = {false};
                    setappdata(handles.figure1,'stimKeys',stimKeysCell);
                    setappdata(handles.figure1,'stimRow',row);
                    theSession = getappdata(handles.figure1,'theSession');
                    theStim = theSession.kids(stimKey);
                    % Get channel values to populate the table
                    channelKeys = theStim.getKidKeys;
                    channelKeysCell = cell(numel(channelKeys),2);
                    channelKeysCell(:,1) = {false};
                    channelKeysCell(:,2) = channelKeys';
                    setappdata(handles.figure1,'channelKeys',channelKeysCell);
                    % Save the current selection state
                    setappdata(handles.figure1,'theStim',theStim);
                    setappdata(handles.figure1,'targetLevel',3);
                else
                    performUpdate = false;
                end
            case {7,8} % Channel Selection
                % Mark channel selections
                channelKeysCell = getappdata(handles.figure1,'channelKeys');
                nChannels = size(channelKeysCell,1);
                if row <= nChannels
                    channelKeysCell{row,1} = ~channelKeysCell{row,1};
                    setappdata(handles.figure1,'channelKeys',channelKeysCell);
                    setappdata(handles.figure1,'targetLevel',4);
                else
                    performUpdate = false;
                end
        end
        if performUpdate
            obj.rmData_updateGUI_Callback();
        end
    end
end


end