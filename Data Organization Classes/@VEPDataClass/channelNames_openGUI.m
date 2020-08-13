function channelNames_openGUI(obj)

if isempty(obj.fh_chanNames)
  
  % Choose the GUI file based on system
  guiFile = 'channelNamesTable.fig';
  
  % Open the GUI and create object handles
  obj.fh_chanNames = openfig(guiFile,'new','invisible');
  handles = guihandles(obj.fh_chanNames);
  handles.closeListener = addlistener(obj,'CloseViewers',...
    @(src,event)closeGUI(obj,'fh_chanNames'));
  handles.updateListener = addlistener(obj,'UpdateViewers',...
    @(src,event)stimDef_updateGUI_Callback(obj));
  guidata(obj.fh_chanNames,handles);
  
  % Set background to match the system default
  objects = findobj(obj.fh_chanNames,'-property','BackgroundColor');
  bgColor = get(0,'defaultUicontrolBackgroundColor');
  set(objects,'BackgroundColor',bgColor);
  set(obj.fh_chanNames,'Color',bgColor);
  
  % Setup GUI callbacks
  set(obj.fh_chanNames,'CloseRequestFcn',...
    @(src,event)closeGUI(obj,'fh_chanNames'));
  set(handles.stimTable,'CellSelectionCallback',...
    @(src,event)stimDef_select_Callback(obj,event));
  set(handles.stimTable,'CellEditCallback',...
    @(src,event)stimDef_select_Callback(obj,event));
  set(handles.deleteButton,'Callback',...
    @(src,event)stimDef_deleteButton_Callback(obj));
  
  % Populate with the current stimulus definitions and draw the GUI
  obj.stimDef_updateGUI_Callback();
  
  % set(obj.fh_chanNames,'Resize','on');
  
  % Make the GUI visible
  set(obj.fh_chanNames,'Visible','on');
else
  figure(obj.fh_chanNames); % raise the GUI
end

end