function rmData_deleteButton_Callback(obj)
% Tell the object to delete the selected data

obj.occupado(true);
try
    handles = guidata(obj.fh_rmData);
    % Build the data selection object that will be used to remove the data and
    % send it to the VDO
    dso = getappdata(handles.figure1,'dsoTemplate');
    dso.resetDataPath();
    targetLevel = getappdata(handles.figure1,'targetLevel');
    switch targetLevel
        case 1 % Delete an animal
            % Populate the dso to target the selected animal
            theAnimal = getappdata(handles.figure1,'theAnimal');
            dso.setFncArgs(theAnimal.ID);
            % Remove the selected animalKey from the GUI and issue the command
            % to delete the object
            animalKeys = getappdata(handles.figure1,'animalKeys');
            selectedRow = getappdata(handles.figure1,'animalRow');
            animalKeys(selectedRow,:) = [];
            setappdata(handles.figure1,'animalKeys',animalKeys);
            setappdata(handles.figure1,'theAnimal',[]);
            setappdata(handles.figure1,'sessionKeys',cell(0,2));
            obj.getData(dso);
        case 2 % Delete a session
            % Populate the dso to target the selected session
            theAnimal = getappdata(handles.figure1,'theAnimal');
            dso.setHierarchyLevel(1,theAnimal.ID);
            theSession = getappdata(handles.figure1,'theSession');
            dso.setFncArgs(theSession.ID);
            % Remove the selected sessionKey from the GUI and issue the command
            % to delete the object
            sessionKeys = getappdata(handles.figure1,'sessionKeys');
            selectedRow = getappdata(handles.figure1,'sessionRow');
            sessionKeys(selectedRow,:) = [];
            setappdata(handles.figure1,'sessionKeys',sessionKeys);
            setappdata(handles.figure1,'theSession',[]);
            setappdata(handles.figure1,'stimKeys',cell(0,2));
            obj.getData(dso);
        case 3 % Delete a stim
            % Populate the dso to target the selected stim
            theAnimal = getappdata(handles.figure1,'theAnimal');
            dso.setHierarchyLevel(1,theAnimal.ID);
            theSession = getappdata(handles.figure1,'theSession');
            dso.setHierarchyLevel(2,theSession.ID);
            theStim = getappdata(handles.figure1,'theStim');
            dso.setFncArgs(theStim.ID);
            % Remove the selected stimKey from the GUI and issue the command to
            % delete the object
            stimKeys = getappdata(handles.figure1,'stimKeys');
            selectedRow = getappdata(handles.figure1,'stimRow');
            stimKeys(selectedRow,:) = [];
            setappdata(handles.figure1,'stimKeys',stimKeys);
            setappdata(handles.figure1,'theStim',[]);
            setappdata(handles.figure1,'channelKeys',cell(0,2));
            obj.getData(dso);
        case 4 % Delete channels
            % Populate the dso to target up to the selected stim
            theAnimal = getappdata(handles.figure1,'theAnimal');
            dso.setHierarchyLevel(1,theAnimal.ID);
            theSession = getappdata(handles.figure1,'theSession');
            dso.setHierarchyLevel(2,theSession.ID);
            theStim = getappdata(handles.figure1,'theStim');
            dso.setHierarchyLevel(3,theStim.ID);
            % Populate the dso to target all selected channels and issue
            % commands to delete the objects
            tableData = get(handles.selectionTable,'data');
            channelKeys = getappdata(handles.figure1,'channelKeys');
            channels = tableData(:,8);
            channelSelections = tableData(:,7);
            decrement = 0; % update index as the array size contracts
            for iC = 1:numel(channelSelections)
                if channelSelections{iC} == true
                    theChannelKey = channels{iC};
                    dso.setFncArgs(theChannelKey);
                    channelKeys(iC-decrement,:) = [];
                    setappdata(handles.figure1,'channelKeys',channelKeys);
                    obj.getData(dso);
                    decrement = decrement + 1;
                end
            end
    end
    % Decrement the target level
    setappdata(handles.figure1,'targetLevel',targetLevel - 1);
    notify(obj,'UpdateViewers');
    notify(obj,'DataAddedOrRemoved');
catch ME
    warnstr = sprintf('rmData_deleteButton_Callback failed:\n%s\n',getReport(ME));
    warndlg(warnstr);
end
obj.occupado(false);
end