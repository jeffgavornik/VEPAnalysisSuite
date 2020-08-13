function rmData_openGUI(obj)

if isempty(obj.fh_rmData)
    
    % Choose the GUI file based on system
    guiFile = 'rmData.fig';
    %if ispc
    %    guiFile = sprintf('pc_%s',guiFile);
    %nd
    
    % Open the GUI and get object handles
    obj.fh_rmData = openfig(guiFile,'new','invisible');
    handles = guihandles(obj.fh_rmData);
    
    % Set background to match the system default
    objects = findobj(obj.fh_rmData,'-property','BackgroundColor');
    bgColor = get(0,'defaultUicontrolBackgroundColor');
    set(objects,'BackgroundColor',bgColor);
    set(obj.fh_rmData,'Color',bgColor);
        
    % Create a template that will be used to get the keys
    setappdata(handles.figure1,'dsoTemplate',...
        getDataSpecifierTemplate('deleteKid'));
    
    % Initialize state variable to an empty array
    setappdata(handles.figure1,'theAnimal',[]);
    
    % Setup GUI callbacks
    set(obj.fh_rmData,'CloseRequestFcn',...
      @(src,event)closeGUI(obj,'fh_rmData'));
    
    set(handles.selectionTable,'CellSelectionCallback',...
        @(src,event)rmData_select_Callback(obj,event));
    
    set(handles.deleteButton,'Callback',...
        @(src,event)rmData_deleteButton_Callback(obj));
    
    % Add listeners for update and close events
    handles.updateListener = addlistener(obj,'UpdateViewers',...
        @(src,event)rmData_updateGUI_Callback(obj));
    handles.closeListener = addlistener(obj,'CloseViewers',...
        @(src,eventdata)closeGUI(obj,'fh_rmData'));
    
    % Save the updated handles
    guidata(obj.fh_rmData,handles);
    
    % Populate with the current animal data and draw the GUI
    obj.rmData_updateData_Callback();
    
    % Make the GUI visible
    set(obj.fh_rmData,'Visible','on');
    
else
    figure(obj.fh_rmData); % raise the GUI
end

end