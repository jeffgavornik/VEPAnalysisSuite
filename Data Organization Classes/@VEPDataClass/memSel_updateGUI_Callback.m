function memSel_updateGUI_Callback(obj)

if ~isempty(obj.fh_memSel)
    
    handles = guidata(obj.fh_memSel);
    
    % Get the selected group key
    grpMgmt_handles = guidata(obj.fh_grpMgmt);
    grpKey = get(grpMgmt_handles.selectedGroupPanel,'Title');
    set(handles.grpNameTxt,'String',grpKey);
    
    % Figure out how many rows of data are needed
    nAnimals = size(getappdata(handles.figure1,'animalKeys'),1);
    nSessions = size(getappdata(handles.figure1,'sessionKeys'),1);
    nStims = size(getappdata(handles.figure1,'stimKeys'),1);
    nChannels = size(getappdata(handles.figure1,'channelKeys'),1);
    nRows = max([nAnimals,nSessions,nStims,nChannels]);
    % Create an empty cell array to hold the data
    tableContents = cell(nRows,8);
    % Add the appropriate keys for the current selections
    tableContents(1:nAnimals,1:2) = getappdata(handles.figure1,'animalKeys');
    colFormats = get(handles.selectionTable,'ColumnFormat');
    validCols = 2;
    if nSessions > 0
        tableContents(1:nSessions,3:4) = ...
            getappdata(handles.figure1,'sessionKeys');
        colFormats{3} = 'logical';
        validCols = 4;
        if nSessions == 1 && ~tableContents{1,3}
            autoEventData.Indices = [1 4];
        end
    else
        tableContents(1:nRows,3:4) = {''};
        colFormats{4} = [];
    end
    if nStims > 0
        tableContents(1:nStims,5:6) = getappdata(handles.figure1,'stimKeys');
        colFormats{5} = 'logical';
        validCols = 6;
        if nStims == 1 && ~tableContents{1,5}
            autoEventData.Indices = [1 6];
        end
    else
        tableContents(1:nRows,5:6) = {''};
        colFormats{6} = [];
    end
    if nChannels > 0
        tableContents(1:nChannels,7:8) = getappdata(handles.figure1,'channelKeys');
        colFormats{7} = 'logical';
        validCols = 8;
    else
        tableContents(1:nRows,7:8) = {''};
        colFormats{8} = [];
    end
    set(handles.selectionTable,'Data',tableContents);
    set(handles.selectionTable,'ColumnFormat',colFormats);
    % Save the number of columns that are valid for selection
    setappdata(handles.figure1,'validSelectionCols',validCols);
    % Autoselect if there is a single choice
    if exist('autoEventData','var')
        obj.memSel_select_Callback(autoEventData);
    else
        checkValidSelection(handles);
    end
end

end

% Enable the addButton if any channels are selected
function checkValidSelection(handles)
tableData = get(handles.selectionTable,'data');
channelSelections = tableData(:,7);
enableFlag = 'off';
for iC = 1:numel(channelSelections)
    if channelSelections{iC} == true
        enableFlag = 'on';
    end
end
set(handles.addButton,'Enable',enableFlag);
end