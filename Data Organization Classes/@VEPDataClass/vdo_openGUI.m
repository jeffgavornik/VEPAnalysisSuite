function vdo_openGUI(obj)
if isempty(obj.fh)
  
  % Open the GUI and create handles
  guiFile = 'VEPDataClass2.fig';
  obj.fh = openfig(guiFile,'new','invisible');
  handles = guihandles(obj.fh);
  guidata(obj.fh,handles);
  
  % Redirect default GUI close function
  set(obj.fh,'CloseRequestFcn',@(src,event)vdo_closeGUI(obj));
  
  % Configure GUI elements if running on a PC
  if ispc
    configureGUIForPC(handles);
  end
  
  % Set background to match the system default
  objects = findobj(obj.fh,'-property','BackgroundColor');
  objects = objects(objects ~= handles.busyIndicator);
  bgColor = get(0,'defaultUicontrolBackgroundColor');
  set(objects,'BackgroundColor',bgColor);
  set(obj.fh,'Color',bgColor);
  
  % Setup man GUI callback function
  guiControls = [ ...
      handles.saveDataMenu,...
      handles.saveDataAsMenu,...
      handles.archiveMenu,...
      handles.openMenu,...
      handles.sendToCmdWndMenu,...
      handles.rmDataMenu,...
      handles.autoChNameMenu,...
      handles.manageChannelNamesMenu,...
      handles.exportDataToWksp,...
      handles.exportDataToXL,...
      handles.viewerMenu,...
      handles.tmdaMenu,...
      handles.traceViewerMenu,...
      handles.psdMenu,...
      handles.manageGrpMenu,...
      handles.groupTraceViewerMenu,...
      handles.groupPSDViewerMenu,...
      handles.grpBarPlotMenu,...
      ];
  set(guiControls,'Callback',@(src,event)vdo_guiCallbacks(obj,src,event));
  vdo_populateInputFilterMenu(obj);
  
  % Data Import Setting ------------------
  set([handles.LFPCheckbox,handles.unitsCheckbox],'Callback',...
    @(src,event)vdo_importDataSelection_Callback(obj));

  set([handles.extractTimeWindowTxt,...
    handles.negLatRangeText,...
    handles.maxPosLatText,...
    handles.smoothWidthText,...
    handles.scrubThresholdTxt,...
    handles.tmdaTypeTxt],'ButtonDownFcn',...
    @(src,event)vdo_updateExtractionParameters_Callback(obj,src),...
    'Enable','inactive','TooltipString','Click to change value');
  % note: set to inactive as workaround for a bug that prevents left-click
  % from activating the ButtonDownFcn
  set(handles.stimDefButton,'Callback',...
    @(src,event)vdo_selectStimDefMenu_Callback(obj,src));
  set(handles.stimTxtButton,'Callback',...
    @(src,event)vdo_selectStimTxtMenu_Callback(obj,src));
  set(handles.prGratingStimsButton,'Callback',...
    @(src,event)vdo_selectPRGratingStimsMenu_Callback(obj,src));
  
  % Disable functions that are not available in the deployed version
  if isdeployed
    matlabOnly = [ ...
      handles.sendToCmdWndMenu, ...
      handles.stimDefMenu,...
      handles.exportDataToWksp,...
      handles.exportDataToXL,...
      handles.tmdaMenu,...
      handles.psdMenu,...
      handles.groupPSDViewerMenu,...
      handles.tmdaTypeTxt,...
      ];
  set(matlabOnly,'visible','off');
  end
  
  % Setup stim definition GUI callbacks
  %   set(handles.stimTable,'CellSelectionCallback',...
  %     @(src,event)stimDef_select_Callback(obj,event));
  %   set(handles.stimTable,'CellEditCallback',...
  %     @(src,event)stimDef_select_Callback(obj,event));
  %   set(handles.deleteButton,'Callback',...
  %     @(src,event)stimDef_deleteButton_Callback(obj));
  %   set(handles.stimTable,'data',{});
  set(handles.stimTable,'CellSelectionCallback',...
      @(src,event)stimDef_guiCallbacks(obj,src,event));
  set(handles.stimTable,'CellEditCallback',...
      @(src,event)stimDef_guiCallbacks(obj,src,event));
  set(handles.deleteButton,'Callback',...
      @(src,event)stimDef_guiCallbacks(obj,src,[]));
  set(handles.stimTable,'data',{});
    set(handles.metaOverrideBox,'Callback',...
        @(src,event)stimDef_guiCallbacks(obj,src,[]));
  
  % Call function to update the GUI
  obj.vdo_updateGUI_Callback();
  
  % Make the GUI visible
  set(obj.fh,'Visible','on');
  
end
end
