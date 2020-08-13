function rmData_updateData_Callback(obj)
if ~isempty(obj.fh_rmData)
    handles = guidata(obj.fh_rmData);    
    % Create cell arrays that will hold the keys for each layer of the
    % hiearchy and put in the animalKeys
    animalKeys = obj.getAnimalKeys;
    animalKeysCell = cell(numel(animalKeys),2);
    animalKeysCell(:,1) = {0};
    animalKeysCell(:,2) = animalKeys';
    setappdata(handles.figure1,'animalKeys',animalKeysCell);
    setappdata(handles.figure1,'sessionKeys',cell(0,2));
    setappdata(handles.figure1,'stimKeys',cell(0,2));
    setappdata(handles.figure1,'channelKeys',cell(0,2));
    % Call function to draw the GUI
    obj.rmData_updateGUI_Callback();
end