function memSel_select_Callback(obj, eventdata)
% Respond to table selections

handles = guidata(obj.fh_memSel);

% Get the list of currently selected table cells
selection = eventdata.Indices; % Get selection indices (row, col)
if ~isempty(selection)
    % Check to make sure the selection is in a valid region of the tables
    performUpdate = true;
    col = selection(1,2);
    if col <= getappdata(handles.figure1,'validSelectionCols')
        row = selection(1,1);
        dsoTemplate = getappdata(handles.figure1,'dsoTemplate');
        switch col
            case {1,2} % Animal Selection
                % Mark the selection and get the selected key
                animalKeysCell = getappdata(handles.figure1,'animalKeys');
                nAnimals = size(animalKeysCell,1);
                animalKeysCell{row,1} = true;
                animalKeysCell(1:nAnimals ~= row,1) = {false};
                setappdata(handles.figure1,'animalKeys',animalKeysCell);
                animalKey = animalKeysCell{row,2};
                setappdata(handles.figure1,'animalKey',animalKey);
                % Get conditions for the selected animal
                dsoTemplate.resetDataPath();
                dsoTemplate.setHierarchyLevel(1,animalKey);
                sessionKeys = obj.getData(dsoTemplate);
                sessionKeysCell = cell(numel(sessionKeys),2);
                sessionKeysCell(:,1) = {false};
                sessionKeysCell(:,2) = sessionKeys';
                setappdata(handles.figure1,'sessionKeys',sessionKeysCell);
                % Deselect session, stim and channels
                setappdata(handles.figure1,'stimKeys',cell(0,2));
                setappdata(handles.figure1,'channelKeys',cell(0,2));
                setappdata(handles.figure1,'stimKey',[]);
                setappdata(handles.figure1,'sessionKey',[]);
            case {3,4} % Session Selection
                % Mark the selection and get the selected key
                sessionKeysCell = getappdata(handles.figure1,'sessionKeys');
                nSessions = size(sessionKeysCell,1);
                if row <= nSessions
                    sessionKeysCell{row,1} = true;
                    sessionKey = sessionKeysCell{row,2};
                    sessionKeysCell(1:nSessions ~= row,1) = {false};
                    setappdata(handles.figure1,'sessionKeys',sessionKeysCell);
                    setappdata(handles.figure1,'sessionKey',sessionKey);
                    % Get stims for the selected session
                    dsoTemplate.setHierarchyLevel(2,sessionKey,true);
                    stimKeys = obj.getData(dsoTemplate);
                    stimKeysCell = cell(numel(stimKeys),2);
                    stimKeysCell(:,1) = {false};
                    stimKeysCell(:,2) = stimKeys';
                    setappdata(handles.figure1,'stimKeys',stimKeysCell);
                    % Deselect stim and channels
                    setappdata(handles.figure1,'channelKeys',cell(0,2));
                    setappdata(handles.figure1,'stimKey',[]);
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
                    setappdata(handles.figure1,'stimKey',stimKey);
                    % Get channels for the selected stim
                    dsoTemplate.setHierarchyLevel(3,stimKey,true);
                    channelKeys = obj.getData(dsoTemplate);
                    channelKeysCell = cell(numel(channelKeys),2);
                    channelKeysCell(:,1) = {false};
                    channelKeysCell(:,2) = channelKeys';
                    setappdata(handles.figure1,'channelKeys',channelKeysCell);
                else
                    performUpdate = false;
                end
            case {7,8} % Channel Selection
                % Mark the selection
                channelKeysCell = getappdata(handles.figure1,'channelKeys');
                nChannels = size(channelKeysCell,1);
                if row <= nChannels
                    channelKeysCell{row,1} = ~channelKeysCell{row,1};
                    setappdata(handles.figure1,'channelKeys',channelKeysCell);
                else
                    performUpdate = false;
                end
        end
        if performUpdate
            obj.memSel_updateGUI_Callback();
        end
    end
end
end