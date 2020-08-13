function memSel_openGUI(obj)

if isempty(obj.fh_memSel)
    
    % Choose the GUI file based on system
    guiFile = 'memSel.fig';
    %if ispc
    %    guiFile = sprintf('pc_%s',guiFile);
    %nd
    
    % Open the GUI and create object handles
    obj.fh_memSel = openfig(guiFile,'new','invisible');
    handles = guihandles(obj.fh_memSel);
    handles.closeListener = addlistener(obj,'CloseViewers',...
        @(src,event)closeGUI(obj,'fh_memSel'));
    handles.updateListener = addlistener(obj,'UpdateViewers',...
        @(src,event)memSel_updateData_Callback(obj));
    guidata(obj.fh_memSel,handles);
    
    % Set background to match the system default
    objects = findobj(obj.fh_memSel,'-property','BackgroundColor');
    bgColor = get(0,'defaultUicontrolBackgroundColor');
    set(objects,'BackgroundColor',bgColor);
    set(obj.fh_memSel,'Color',bgColor);
    
    % Create a template that will be used to get the keys
    setappdata(handles.figure1,'dsoTemplate',...
        getDataSpecifierTemplate('kidKeys'));
    
    % Setup GUI callbacks
    set(obj.fh_memSel,'CloseRequestFcn',...
      @(src,event)closeGUI(obj,'fh_memSel'));
    
    set(handles.selectionTable,'CellSelectionCallback',...
        @(src,event)memSel_select_Callback(obj,event));
    
    set(handles.addButton,'Callback',...
        @(src,event)memSel_addButton_Callback(obj));
    
    % Setup for auto selection
    setappdata(handles.figure1,'animalRow',[]);
    
    % Populate with the current animal data and draw the GUI
    obj.memSel_updateData_Callback();

    set(obj.fh_memSel,'Resize','on');
    
    % Make the GUI visible
    set(obj.fh_memSel,'Visible','on');
else
    figure(obj.fh_memSel); % raise the GUI
end

end