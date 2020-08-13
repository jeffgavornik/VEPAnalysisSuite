function vdo_updateGUI_Callback(obj)

if obj.isHeadless
  return;
end

% Render the data extraction parameters
params = obj.getDataExtractParams;
handles = guidata(obj.fh);
set(handles.extractTimeWindowTxt,'String',sprintf(...
  'Extract Time Window = %i ms',1000*params.extractTimeWindow));
set(handles.negLatRangeText,'String',sprintf(...
  'Negative Latency Range = [%i %i] ms',...
  1000*params.negativeLatencyRange(1),...
  1000*params.negativeLatencyRange(2)));
set(handles.maxPosLatText,'String',sprintf(...
  'Max Positive Latency = %i ms',1000*params.maxPositiveLatency));
set(handles.smoothWidthText,'String',sprintf(...
  'Smoothing Kernel Width = %i',params.smoothWidth));
set(handles.scrubThresholdTxt,'String',sprintf(...
  'Trace Scrub Threshold = %i uV',params.scrubThreshold));
set(handles.tmdaTypeTxt,'String',sprintf(...
  'TMDA Analysis Type = %s',params.TMDAType));
set(handles.vdoInfoText,'String',...
  sprintf('%i Animals (%i Files)',obj.animalRecords.length,...
  numel(obj.includedFiles)));
set(handles.groupInfoText,'String',...
  sprintf('%i Groups',obj.groupRecords.length));
if isempty(obj.ID)
  set(handles.figure1,'Name',class(obj));
else
  set(handles.figure1,'Name',obj.ID);
end

% Disable analysis menu items if no data has been added
if isempty(obj.animalRecords.keys)
  set([handles.VEPMenu handles.groupMenu],'Enable','off');
else
  set([handles.VEPMenu handles.groupMenu],'Enable','on');
end

% Show indicator if object is dirty
if obj.dirtyBit
  set(handles.dirtyBitTag,'visible','on');
  set(handles.saveDataMenu,'Enable','on');
else
  set(handles.dirtyBitTag,'visible','off');
  set(handles.saveDataMenu,'Enable','off');
end

% Render stim definition indicator
if isempty(obj.stimDefs)
  set(handles.stimFncTxt,'String','No Stimuli Defined',...
    'ButtonDownFcn',[]);
else
  set(handles.stimFncTxt,'String',sprintf('Src: %s',obj.stimDefStr));
end

% Render stimulus definition table
oldTable = get(handles.stimTable,'Data');
oldRows = size(oldTable);
stimDefs = obj.stimDefs;
stimKeys = stimDefs.keys;
nKeys = length(stimKeys);
nRows = nKeys + 1;
dataCell = cell(nRows,3);
for iK = 1:nKeys
  theKey = stimKeys{iK};
  theValues = stimDefs(theKey);
  if iK <= oldRows
    dataCell{iK,1} = oldTable{iK,1};
  else
    dataCell{iK,1} = false;
  end
  dataCell{iK,2} = theKey;
  dataCell{iK,3} = num2str(theValues);
end
dataCell(nRows,:) = {false '' ''};

 % Indicate metadata override state
 set(handles.metaOverrideBox,'Value',obj.ignoreMetaData);

% Put the cell array into GUI table
set(handles.stimTable,'Data',dataCell);

drawnow(); % flush queue