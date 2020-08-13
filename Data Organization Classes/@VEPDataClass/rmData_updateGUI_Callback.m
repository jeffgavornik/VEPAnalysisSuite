function rmData_updateGUI_Callback(obj)
if ~isempty(obj.fh_rmData)
    handles = guidata(obj.fh_rmData);
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
    else
        tableContents(1:nRows,3:4) = {''};
        colFormats{4} = [];
    end
    if nStims > 0
        tableContents(1:nStims,5:6) = getappdata(handles.figure1,'stimKeys');
        colFormats{5} = 'logical';
        validCols = 6;
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
    % If there is a selection, enable the delete button
    if isempty(getappdata(handles.figure1,'theAnimal'))
        set(handles.deleteButton,'Enable','off');
    else
        set(handles.deleteButton,'Enable','on');
    end    
end
end