classdef (ConstructOnLoad) VEPDataClass < handle
  
  properties
    % Organizational variables
    animalRecords
    groupRecords
    includedFiles
    ID
    
    % Data extraction, definition and analysis parameters
    stimDefStr
    stimDefs
    channelNames
    dataExtractParams
    
    % Optional filter to be applied to data
    digitalFilters = {};
    filterData % true when filters exist, false otherwise
    
    eventDefOverrideFncs
    analysisOptionsDict
    averageByAnimalOption
    
    % set true to override stim defs stored in meta data
    ignoreMetaData = false
    
  end
  
  properties (Transient=true,Hidden=true)
    
    % Handles to various GUI elements controlled by the VDO
    fh % gui figure handle
    fh_grpMgmt % group management figure window
    fh_memSel % member selection figure window
    fh_rmData % data removal figure window
    fh_stimDef % stimulus definition management window
    fh_chanNames % channel name management window
    
    % Object management overhead variables
    dirtyBit
    listeners
    nameChannels % attempt to name the channels
    
    % Organize direct support for listener callback-type activity
    prepForSaveSupportHandles % objects with raw data to be cleared before save
    traceDataSupportHandles % voltageTraceDataObjects
    deleteSupportHandles % objects that need to be explicitly deleted
    FID % control fprintf targets
    isHeadless % GUI-less scripting support
    
    rootDataDirectory
    
  end
  
  events
    DataAddedOrRemoved % set the dirty bit
    UpdateViewers % tell any open viewers to refresh their content
    CloseViewers % tell any open viewers to close
    RefreshGUINeeded % tell the object to refresh its content
    GrpMgmtRefreshGUINeeded % tell the group manager to refresh itself
    ExtractTraces % tell everything to extract the traces again
    ReloadRawData % tell everything to reload the data
    FilterData % tell data sources to apply filters
  end
  
  methods (Static = true)
    %function str = loadobj(str)
    %    % Provide access to the obj contents the load process, before it
    %    % is instantiated as a VDO
    %end
    
    function obj = open(filename,filepath)
      if nargin == 0
        [filename,filepath] = uigetfile(...
          '*.vdo','Select a VEP Data Object file',...
          'MultiSelect', 'off');
      end
      if isequal(filename,0) || isequal(filepath,0) % user select cancel
        obj = [];
        return;
      end
      try
        h = waitbar(0,regexprep(...
          sprintf('Opening file ''%s''\nPlease Wait',filename),...
          '_','\\_'));
        rtrnStrct = load(fullfile(filepath,filename),'-mat');
        obj = rtrnStrct.obj;
        notify(obj,'RefreshGUINeeded')
      catch ME
        fprintf(2,'VEPDataClass.open failed\n%s\n',ME.getReport);
      end
      close(h);
    end
    
    function obj = new
      obj = VEPDataClass;
      obj.isHeadless = false;
    end
    
    function obj = headless
      obj = VEPDataClass(true);
      obj.isHeadless = true;
    end
    
    function obj = deployed
      obj = VEPDataClass;
      obj.isHeadless = false;
    end
    
    function cleanup
      % Deletes all existing VEPDataObjects saved under user data
      userData = get(0,'UserData');
      if isa(userData,'containers.Map')
        if userData.isKey('VEPDataObjects')
          vdos = userData('VEPDataObjects');
          for iV = 1:length(vdos)
            vdo = vdos(iV);
            if isvalid(vdo)
              vdo_closeGUI(vdo); % will closeout and delete
            end
          end
          userData.remove('VEPDataObjects');
        end
      end
    end
    
  end
  
  methods
    
    % Note: GUI callback methods are defined external to this .m file
    
    % Constructors/destructors ----------------------------------------
    function obj = VEPDataClass(headless)
      if nargin == 0
        obj.isHeadless = false;
      else
        obj.isHeadless = headless;
      end
      obj.animalRecords = containers.Map;
      obj.groupRecords = containers.Map;
      obj.ID = '';
      obj.setDefaultImportParams;
      obj.setDefaultStimDefs;
      obj.setDefaultEventDefOverrideFncs;
      obj.setDefaultchannelNames;
      obj.nameChannels = true;
      obj.includedFiles = {};
      % Setup structures that will be used to track supported objects
      obj.prepForSaveSupportHandles = managedCellClass(1000);
      obj.traceDataSupportHandles = managedCellClass(1000);
      obj.deleteSupportHandles = managedCellClass(100);
      obj.dirtyBit = false;
      % Setup listener callbacks
      obj.listeners{1} = addlistener(obj,'DataAddedOrRemoved',...
        @(src,event)objectChanged_Callback(obj));
      obj.listeners{2} = addlistener(obj,'RefreshGUINeeded',...
        @(src,event)vdo_updateGUI_Callback(obj));
      % Send fprintf to standard out
      obj.FID = 1;
      if ~obj.isHeadless
        % Open the GUI
        obj.vdo_openGUI;
      end
      objectTrackerClass.startTracking(obj);
      trackObject(obj);
    end
    
    % Setup defaults
    function setDefaultImportParams(obj)
      obj.dataExtractParams = default_vep_parameters;
    end
    
    function setDefaultStimDefs(obj)
      obj.stimDefStr = '';
      obj.stimDefs = containers.Map;
    end
    
    function setDefaultchannelNames(obj)
      % Look for a textfile called ChannelMappings.txt and use it's
      % contents to set the default mapping between channel number and
      % description
      obj.channelNames = ...
        containers.Map('KeyType','double','ValueType','char');
      if exist('ChannelMappings.txt','file') == 2
        try
          %[keys,vals] = textread('ChannelMappings.txt',...
          %  '%d:%s','commentstyle','shell');
          fid = fopen('ChannelMappings.txt');
          dataCell = textscan(fid,'%d:%s','CommentStyle','#');
          fclose(fid);
          keys = dataCell{1};
          vals = dataCell{2};
          for iK = 1:length(keys)
            obj.channelNames(keys(iK)) = vals{iK};
          end
        catch ME
          handleError(ME,~obj.isHeadless,'Default Channel Naming Failure');
        end
      end
    end
    
    function setDefaultEventDefOverrideFncs(obj)
      obj.eventDefOverrideFncs = containers.Map;
      obj.setEventDefOverrideFnc(@definePiezzoChannelEvents,'piezzo');
    end
    
    function trackObject(obj)
      % Add the VDO to user data
      userData = get(0,'UserData');
      if isa(userData,'containers.Map')
        if userData.isKey('VEPDataObjects')
          vdos = userData('VEPDataObjects');
          vdos(end+1) = obj;
          userData('VEPDataObjects') = vdos; %#ok<NASGU>
        else
          userData('VEPDataObjects') = obj; %#ok<NASGU>
        end
      else
        userData = containers.Map;
        userData('VEPDataObjects') = obj;
        set(0,'UserData',userData);
      end
    end
    
    function delete(obj)
      % Dispatch supported deletion functions
      theHandles = getContents(obj.deleteSupportHandles);
      nH = numel(theHandles);
      fprintf(obj.FID,'Dispatching %i delete support functions...\n',nH);
      for iH = 1:nH
        theFnc = theHandles{iH};
        theFnc();
      end
      delete(obj.deleteSupportHandles);
      
      % Delete all of the groups
      groupKeys = obj.getGroupKeys;
      for iGrp = 1:numel(groupKeys)
        delete(obj.groupRecords(groupKeys{iGrp}));
      end
      
      % Tell all of the kids to delete themselves
      animalKeys = obj.animalRecords.keys;
      try
        for iA = 1:length(animalKeys)
          deleteWithKids(obj.animalRecords(animalKeys{iA}));
        end
      catch ME
        fprintf(2,getReport(ME));
      end
      
      % Delete the managedCellClass objects
      delete(obj.prepForSaveSupportHandles);
      delete(obj.traceDataSupportHandles);
      
      fprintf(obj.FID,'Deleting %s object\n',class(obj));
      objectTrackerClass.stopTracking(obj);
    end
    
    function reportContent(obj,fid)
      if nargin == 1
        fid = obj.FID;
      end
      if ~isempty(obj.ID)
        nameStr = sprintf('''%s''',obj.ID);
      else
        nameStr = '';
      end
      fprintf(fid,'VEPDataClass: %s\n',nameStr);
      fprintf(fid,'\n------Groups------\n\n');
      groupKeys = obj.getGroupKeys;
      for iGrp = 1:numel(groupKeys)
        theGrp = obj.groupRecords(groupKeys{iGrp});
        reportContent(theGrp,fid);
      end
      fprintf(fid,'\n------Data------\n\n');
      animalKeys = obj.animalRecords.keys;
      for iAnimal = 1:numel(animalKeys)
        theObj = obj.animalRecords(animalKeys{iAnimal});
        reportContent(theObj,'',fid);
      end
      fprintf(fid,'\n------Stimulus Definitions------\n\n');
      stimKeys = obj.stimDefs.keys;
      nKeys = length(stimKeys);
      for iK = 1:nKeys
        theKey = stimKeys{iK};
        theValues = obj.stimDefs(theKey);
        if length(theValues) == 1
          fprintf(fid,'''%s'' Event Value = %s\n',...
            theKey,num2str(theValues));
        else
          fprintf(fid,'''%s'' Event Values = [%s]\n',...
            theKey,num2str(theValues));
        end
      end
    end
    
    % Listener callbacks ----------------------------------------------
    function objectChanged_Callback(obj)
      % Responds to DataAddedOrRemoved events
      obj.dirtyBit = true;
      notify(obj,'RefreshGUINeeded');
    end
    
    % Group support methods -------------------------------------------
    
    % Create a new group of a specified type
    function newGroup = createNewGroup(obj,grpKey,grpClassStr)
      switch grpClassStr
        case 'VEPMagGroupClass'
          newGroup = VEPMagGroupClass(obj,grpKey);
        case 'VEPTraceGroupClass'
          newGroup = VEPTraceGroupClass(obj,grpKey);
        otherwise
          error('%s.createNewGroup: unknown group class %s',...
            class(obj),grpClassStr);
      end
      obj.groupRecords(grpKey) = newGroup;
      notify(obj,'UpdateViewers');
      notify(obj,'DataAddedOrRemoved');
    end
    
    % Call the selection application to add data to a group
    function addDataToGroup(obj,grpKey)
      if obj.groupRecords.isKey(grpKey)
        memberSelectionApp(obj.groupRecords(grpKey));
      else
        error('%s.addDataToGroup: unknown groupKey %s',...
          class(obj),grpKey);
      end
    end
    
    % Return the data from a particular group
    function varargout = getDataForGroup(obj,grpKey,varargin)
      try
        if obj.groupRecords.isKey(grpKey)
          theGroup = obj.groupRecords(grpKey);
        else
          error('%s.getDataForGroup: unknown grpKey %s',...
            class(obj),grpKey);
        end
        [varargout{1:nargout}] = ...
          theGroup.getGroupData(varargin{:});
      catch ME
        handleError(ME,~obj.isHeadless,'VEPDataClass Error');
      end
    end
    
    % Return a specified group object
    function theGroup = getGroupObject(obj,grpKey)
      theGroup = [];
      if obj.groupRecords.isKey(grpKey)
        theGroup = obj.groupRecords(grpKey);
      end
    end
    
    % Return the group keys - can specify a specific targetGroupClass
    function requestedKeys = getGroupKeys(obj,targetGroupClass)
      if nargin < 2
        targetGroupClass = 'all';
      end
      requestedKeys = {};
      groupKeys = obj.groupRecords.keys;
      for iG = 1:numel(groupKeys)
        thisKey = groupKeys{iG};
        if isa(obj.groupRecords(thisKey),targetGroupClass) || ...
            strcmp(targetGroupClass,'all')
          requestedKeys{end+1} = thisKey; %#ok<AGROW>
        end
      end
    end
    
    % Create a new group using multiple animal, session, stim, and
    % channel keys
    function newGroup = createGroupForMultipleKeys(obj,grpKey,...
        animalKeys,sessionKeys,stimKeys,channelKeys)
      newGroup = VEPMagGroupClass(obj,grpKey);
      obj.groupRecords(grpKey) = newGroup;
      obj.addMultipleKeysToGroup(grpKey,animalKeys,sessionKeys,...
        stimKeys,channelKeys);
    end
    
    % Add multiple animal, session, stim, and channels to an existing
    % group
    function theGrp = addMultipleKeysToGroup(obj,grpKey,animalKeys,...
        sessionKeys,stimKeys,channelKeys)
      theGrp = [];
      try
        if ~isa(animalKeys,'cell')
          animalKeys = {animalKeys};
        end
        if ~isa(sessionKeys,'cell')
          sessionKeys = {sessionKeys};
        end
        if ~isa(stimKeys,'cell')
          stimKeys = {stimKeys};
        end
        if ~isa(channelKeys,'cell')
          channelKeys = {channelKeys};
        end
        theGrp = obj.groupRecords(grpKey);
        dsoTemplate = getDataSpecifierTemplate('kidKeys');
        for iA = 1:numel(animalKeys)
          animalKey = animalKeys{iA};
          for iS = 1:numel(sessionKeys)
            sessionKey = sessionKeys{iS};
            for iSt = 1:numel(stimKeys)
              stimKey = stimKeys{iSt};
              for iC = 1:numel(channelKeys)
                channelKey = channelKeys{iC};
                dsoTemplate.resetDataPath();
                dsoTemplate.setHierarchyLevel(1,animalKey);
                dsoTemplate.setHierarchyLevel(2,sessionKey);
                dsoTemplate.setHierarchyLevel(3,stimKey);
                dsoTemplate.setHierarchyLevel(4,channelKey);
                theGrp.addDataSpecifier(dsoTemplate);
              end
            end
          end
        end
      catch ME
        handleError(ME,~obj.isHeadless,'VEPDataClass Error');
      end
      notify(obj,'UpdateViewers');
      notify(obj,'DataAddedOrRemoved');
    end
    
    % Normalize one group by another
    function normalizeByGroupMean(obj,targetGrpKey,normGrpKey,varargin)
      try
        %  Normalize targetGrp by normGrp
        if ~obj.groupRecords.isKey(normGrpKey)
          error('''%s'' is not a groupRecord key',normGrpKey);
        end
        if ~obj.groupRecords.isKey(targetGrpKey)
          error('''%s'' is not a groupRecord key',targetGrpKey);
        end
        normGrp = obj.groupRecords(normGrpKey);
        targetGrp = obj.groupRecords(targetGrpKey);
        normalizeByGroupMean(targetGrp,normGrp,varargin{:});
      catch ME
        handleError(ME,~obj.isHeadless,'VEPDataClass Error');
      end
    end
    
    function removeSpecifiersFromAllGroups(obj,varargin)
      % Tell all of the groups to remove the specified values
      try
        groupKeys = obj.getGroupKeys;
        for iGrp = 1:numel(groupKeys)
          theGrp = obj.groupRecords(groupKeys{iGrp});
          theGrp.removeSpecifiersWithElements(varargin{:});
        end
        % Tell all of the groups to update their normalization values
        for iGrp = 1:numel(groupKeys)
          theGrp = obj.groupRecords(groupKeys{iGrp});
          theGrp.refreshNormFactors;
        end
      catch ME
        handleError(ME,~obj.isHeadless,'VEPDataClass Error');
      end
    end
    
    function outputCSVGroupData(obj,outFileName,groupKeys)
      % Tell the selected (or, by default all) groups to write their
      % contents in CSV format
      try
        if ~exist('outFileName','var') || isempty(outFileName)
          fid = 1;
        else
          fid = fopen(outFileName,'w');
        end
        if ~exist('groupKeys','var') || isempty(groupKeys)
          groupKeys = obj.getGroupKeys;
        end
        for iGrp = 1:numel(groupKeys)
          theGrp = obj.groupRecords(groupKeys{iGrp});
          theGrp.outputCSVFormatToFile(fid);
        end
      catch ME
        handleError(ME,~obj.isHeadless,'VEPDataClass Error');
      end
    end
    
    function deleteAllGroups(obj)
      % Delete all of the groups
      try
        groupKeys = obj.getGroupKeys;
        for iGrp = 1:numel(groupKeys)
          delete(obj.groupRecords(groupKeys{iGrp}));
          obj.groupRecords.remove(groupKeys{iGrp});
        end
      catch ME
        handleError(ME,~obj.isHeadless,'VEPDataClass Error');
      end
      notify(obj,'RefreshGUINeeded')
      notify(obj,'GrpMgmtRefreshGUINeeded')
    end
    
    function deleteGroup(obj,grpKey)
        % Delete all of the groups
        try
            delete(obj.groupRecords(grpKey));
            obj.groupRecords.remove(grpKey);
        catch ME
            handleError(ME,~obj.isHeadless,'VEPDataClass Error');
        end
        notify(obj,'RefreshGUINeeded')
        notify(obj,'GrpMgmtRefreshGUINeeded')
    end
    
    % Data export methods ---------------------------------------------
    
    function exportDataToCSV(obj,exportDirectory) % pathname,filename)
      % Export data from the VDO to a CSV file
      try
        % Get the name of the VDO
        if ~isempty(obj.ID)
          nameStr = sprintf('''%s''',obj.ID);
        else
          nameStr = '';
        end
        outputStr = 'Exported Data:\n';
        % Output group data
        if ~isempty(obj.groupRecords)
          [grpFileName, exportDirectory] = ...
            uniqueFileName('GroupData.csv',exportDirectory);
          fid = fopen(fullfile(exportDirectory,grpFileName),'Wb');
          fprintf(fid,'VEPDataClass,%s\n',nameStr);
          fprintf(fid,'\n------Group Data------\n');
          groupKeys = obj.getGroupKeys;
          for iGrp = 1:numel(groupKeys)
            theGrp = obj.groupRecords(groupKeys{iGrp});
            exportCSVData(theGrp,fid);
          end
          fclose(fid);
          outputStr = sprintf('%sGroupData:''%s''\n',...
            outputStr,grpFileName);
        end
        % Output the VDO contents
        fid = fopen(fullfile(pathname,filename),'Wb');
        fprintf(fid,'VEPDataClass,%s\n',nameStr);
        % Pass the command down the hierarchy
        fprintf(fid,'\n------ Data ------\n\n');
        animalKeys = obj.animalRecords.keys;
        for iAnimal = 1:numel(animalKeys)
          theAnimal = obj.animalRecords(animalKeys{iAnimal});
          exportContentToCSV(theAnimal,fid);
        end
        fclose(fid);
        outputStr = sprintf('%sVDO Data:''%s''',...
          outputStr,filename);
        msgbox(outputStr,'VDO Data Export');
      catch ME
        handleError(ME,~obj.isHeadless,'VEPDataClass Error');
      end
    end
    
    % Methods to add/remove data to/from the object -------------------
    
    function theRecord = newAnimalRecord(obj,animalID)
      theRecord = animalRecordClass(obj,animalID);
      obj.animalRecords(animalID) = theRecord;
    end
    
    function addData(obj,varargin)
      % Add data indicated by the VEPDataFileAttributesObject passed
      % as the first argument to add the object
      set(obj.fh,'Pointer','watch');
      try
        dataFileObj = varargin{1};
        vdFileAttObj = dataFileObj.attributes;
        % Check for file existence
        if exist(vdFileAttObj.fileNameWithPath,'file') == 0
          fprintf('VEPDataClass.addData: ''%s'' does not exist\n',...
            vdFileAttObj.fileNameWithPath);
          return
        end
        % Check to see if the file has already been added
        if strcmp(vdFileAttObj.fileNameWithPath,...
            obj.includedFiles)
          prompt = sprintf('File ''%s'' added previously.\n',...
            vdFileAttObj.fileName);
          selection = questdlg(prompt,...
            'Re-add file',...
            'Reimport','Cancel',...
            'Cancel');
          if strcmp(selection,'Cancel')
            return;
          end
        end
        % Tell the appropriate animal record to add the file
        if obj.animalRecords.isKey(vdFileAttObj.animalID)
          theAnimalRecord = ...
            obj.animalRecords(vdFileAttObj.animalID);
        else
          theAnimalRecord = ...
            obj.newAnimalRecord(vdFileAttObj.animalID);
        end
        theAnimalRecord.addData(varargin{:});
        obj.includedFiles{end+1} = vdFileAttObj.fileNameWithPath;
        notify(obj,'UpdateViewers');
        notify(obj,'DataAddedOrRemoved');
      catch ME
        errClass = sprintf('VEPDataClass.addData failed');
        if exist('vdFileAttObj','var')
          errClass = sprintf('%s for file %s',...
            errClass,vdFileAttObj.fileNameWithPath);
        end
        handleError(ME,~obj.isHeadless,errClass,obj.FID);
      end
      set(obj.fh,'Pointer','arrow');
    end
    
    
    function addDataFromPlxFile(obj,fileName,filePath,varargin)
      % Add data from a specified plx file.  Note that varargin can
      % be used to pass explicit animalID and sessionName variables
      % to the VEPDataFileAttributesClass object that is instantiated
      % to handle file specificiations
      try
        if nargin < 3
          filePath = [pwd '/'];
        end
        dataFileObj = plxFileDataClass(fileName,filePath,[],varargin{:});
        dataFileObj.registerForFileOwnerSupport(obj);
        obj.addData(dataFileObj);
      catch ME
        handleError(ME,~obj.isHeadless,'VEPDataClass Error',obj.FID);
      end
    end
    
    function varargout = deleteKid(obj,kidKey) %#ok<STOUT>
      obj.deleteAnimal(kidKey);
    end
    
    function deleteAnimal(obj,animalKey)
      if obj.animalRecords.isKey(animalKey)
        try
          theAnimal = obj.animalRecords(animalKey);
          obj.animalRecords.remove(animalKey);
          deleteWithKids(theAnimal);
        catch ME
          handleError(ME,~obj.isHeadless,...
            'VEPDataClass Error',obj.FID);
        end
        notify(obj,'UpdateViewers');
        notify(obj,'DataAddedOrRemoved');
      end
    end
    
    function filesBeingDeleted(obj,fileKeys)
      % Allow data file objects to remove references to themselves
      % from the vdo
      if ~iscell(fileKeys)
        fileKeys = {fileKeys};
      end
      % Look for the fileKeys in the included files array and remove
      % them
      for iK = 1:numel(fileKeys)
        try
          ind = find(strcmp(fileKeys{iK},obj.includedFiles));
          keepers = 1:numel(obj.includedFiles) ~= ind;
          obj.includedFiles = obj.includedFiles(keepers);
        catch ME
          fprintf(2,'\nError Report:\n%s',getReport(ME));
        end
      end
    end
    
    % Indicate that the Object is busy/available
    function occupado(obj,flag)
      if obj.isHeadless
        return;
      end
      handles = guidata(obj.fh);
      if flag
        set(handles.busyIndicator,'Visible','on');
        set(obj.fh,'Pointer','watch');
      else
        set(handles.busyIndicator,'Visible','off');
        set(obj.fh,'Pointer','arrow');
      end
      drawnow;
    end
    
    % -----------------------------------------------------------------
    % Since listener callback overhead is monsterously slow, provide
    % direct support for various notification-flavored callback
    % operations
    % Registration should occur within object constructor methods,
    % deregistration within destructor methods
    
    function index = registerPrepForSaveSupportFnc(obj,hFnc)
      index = obj.prepForSaveSupportHandles.addData(hFnc);
    end
    
    function deregisterPrepForSaveSupportFnc(obj,indicator)
      if isa(indicator,'function_handle')
        obj.prepForSaveSupportHandles.removeData(indicator);
      else
        obj.prepForSaveSupportHandles.removeDataAtIndex(indicator);
      end
    end
    
    function prepForSave(obj)
      theHandles = obj.prepForSaveSupportHandles.getContents;
      nH = numel(theHandles);
      fprintf(obj.FID,'Dispatching %i prepForSaveSupport functions...\n',nH);
      for iH = 1:nH
        theFnc = theHandles{iH};
        theFnc();
      end
    end
    
    function save(obj,filename,pathname)
        if nargin == 1
            [filename, pathname] = uiputfile('*.vdo',...
                'Enter name for VEPData Object',sprintf('%s.vdo',obj.ID));
        end
        if ~(isequal(filename,0) || isequal(pathname,0)) % not cancel
            outputFile = fullfile(pathname,filename);
            obj.ID = filename(1:end-4); % remove .vdo from the filename
            obj.prepForSave();
            fprintf('Saving VDO as ''%s''\n',outputFile);
            save('-v7.3',outputFile,'obj');
            obj.dirtyBit = false;
            notify(obj,'RefreshGUINeeded');
        end
    end
    
    function index = registerTraceDataSupportFnc(obj,hFnc)
      index = obj.traceDataSupportHandles.addData(hFnc);
    end
    
    function deregisterTraceDataSupportFnc(obj,indicator)
      if isa(indicator,'function_handle')
        obj.traceDataSupportHandles.removeData(indicator);
      else
        obj.traceDataSupportHandles.removeDataAtIndex(indicator);
      end
    end
    
    function performTraceOperations(obj,ctrlArg)
      obj.occupado(true);
      theHandles = obj.traceDataSupportHandles.getContents;
      for iH = 1:numel(theHandles)
        theFnc = theHandles{iH};
        try
          theFnc(ctrlArg);
        catch ME
          fnc = functions(theFnc);
          sprintf('%s:%s failed\n%s',fnc.function,ctrlArg,...
            getReport(ME,'basic'));
        end
      end
      obj.occupado(false);
    end
    
    function index = registerDeleteSupportFnc(obj,supportObj)
      index = obj.deleteSupportHandles.addData(supportObj);
    end
    
    function deregisterDeleteSupportFnc(obj,indicator)
      if isa(indicator,'function_handle')
        obj.deleteSupportHandles.removeData(indicator);
      else
        obj.deleteSupportHandles.removeDataAtIndex(indicator);
      end
    end
    
    % Class setter/accessor methods -----------------------------------
    
    % Use a dataSpecifierObject to extract data from the hierarchy
    function varargout = getData(obj,dso)
      animalKey = dso.getPathKey(obj);
      if ~isempty(animalKey)
        if strcmp(animalKey,'*')
          % Pass the DSO to all animals and compile the results
          % This has not been tested for return with nargout > 1
          outCell = cell(1,nargout);
          animalKeys = obj.animalRecords.keys;
          for iK = 1:length(animalKeys)
            animalKey = animalKeys{iK};
            temp = obj.animalRecords(animalKey).returnData(dso);
            for iO = 1:nargout
              outCell{iO} = {outCell{iO} temp{iO}};
            end
          end
          [varargout{1:nargout}] = outCell{:};
        else
          % Pass the DSO to the specified animal
          [varargout{1:nargout}] = ...
            obj.animalRecords(animalKey).returnData(dso);
        end
      else
        try
          % If there is no animal key the DSO is trying to get data
          % from the VDO or call a method - handle that case
          dataSpecifier = dso.getDataSpecifier;
          % Check to see if the dso specifies a property
          objProps = properties(obj);
          iProp = strcmp(dataSpecifier,objProps);
          if sum(iProp)
            varargout = {obj.(objProps{iProp})};
          else % Check to see if the dso specifies a method
            objMethods = methods(obj);
            iMeth = strcmp(dataSpecifier,objMethods);
            if sum(iMeth)
              fncStr = sprintf('@(varargin)%s(varargin{:})',...
                objMethods{iMeth});
              hFnc = str2func(fncStr);
              args = dso.getFncArgs;
              if isempty(args) % call method with no arguments
                [varargout{1:nargout}] = hFnc(obj);
              else
                if ~iscell(args)
                  args = {args};
                end
                [varargout{1:nargout}] = hFnc(obj,args{:});
              end
            end
          end
        catch ME
          handleError(ME,~obj.isHeadless,...
            'VEPDataClass Error',obj.FID);
          [varargout{1:nargout}] = cell(1,nargout);
        end
      end
    end
    
    %function varargout = returnDataForRecord(obj,specifier_string,dataType)
    %    % string should be ANIMAL_SESSION_STIM_CHANNEL
    %    % dataType is a parameter of the voltageTraceDataClass
    %    parts = regexp(specifier_string,'_','split');
    %    % Ani
    %end
    
    function set.stimDefs(obj,defs)
        if ~isa(defs,'containers.Map')
            ME = MException('VEPDataClass:BadStimDefs',...
                'Incorrectly formatted stimulus definitions');
            handleError(ME,true,...
                'Stimulus Definitions must be in a containers.Map object');
        end
        obj.stimDefs = defs;
        notify(obj,'RefreshGUINeeded');
    end
    
    function set.digitalFilters(obj,newFilters)
        %  Add digital filters to the object that will be used to filter
        %  LFP data
        if ~isa(newFilters,'cell')
            newFilters = {newFilters};
        end
        for iC = 1:length(newFilters)
            newFilter = newFilters{iC};
            if isa(newFilter,'digitalFilter')
                obj.digitalFilters{end+1} = newFilter;
            else
                error('newFilter must be a digitalfilter');
            end
        end
        notify(obj,'FilterData');
        notify(obj,'UpdateViewers');
    end
    
    function useFilter = get.filterData(obj)
        useFilter = ~isempty(obj.digitalFilters);
    end
    
    function animalKeys = getAnimalKeys(obj)
      animalKeys = obj.animalRecords.keys;
    end
    
    function stimDefs = getStimDefs(obj)
      stimDefs = obj.stimDefs;
    end
    
    function stimDefStr = getstimDefStr(obj)
      stimDefStr = obj.stimDefStr;
    end
    
    function params = getDataExtractParams(obj)
      params = obj.dataExtractParams;
    end
    
    function setEventDefOverrideFnc(obj,fnc,channelKey)
      if isa(fnc,'function_handle')
        obj.eventDefOverrideFncs(channelKey) = fnc;
      else
        error('Invalid function handle for channelKey %s',channelKey);
      end
    end
    
    function eventDefOverrideFncs = getEventDefOverrideFnc(obj,channelKey)
      if obj.eventDefOverrideFncs.isKey(channelKey)
        eventDefOverrideFncs = obj.eventDefOverrideFncs(channelKey);
      else
        eventDefOverrideFncs = [];
      end
    end
    
    function extractTimeWindow = getExtractTimeWindow(obj)
      extractTimeWindow = obj.dataExtractParams.extractTimeWindow;
    end
    
    function setExtractTimeWindow(obj,extractTimeWindow)
      obj.dataExtractParams.extractTimeWindow = extractTimeWindow;
      notify(obj,'RefreshGUINeeded');
    end
    
    function scrubThreshold = getScrubThreshold(obj)
      scrubThreshold = obj.dataExtractParams.scrubThreshold;
    end
    
    function setScrubThreshold(obj,scrubThreshold)
      obj.dataExtractParams.scrubThreshold = scrubThreshold;
      notify(obj,'RefreshGUINeeded');
      obj.performTraceOperations('Threshold');
      notify(obj,'UpdateViewers');
    end
    
    function smoothWidth = getSmoothWidth(obj)
      smoothWidth = obj.dataExtractParams.smoothWidth;
    end
    
    function setSmoothWidth(obj,smoothWidth)
      obj.dataExtractParams.smoothWidth = smoothWidth;
      notify(obj,'RefreshGUINeeded');
      obj.performTraceOperations('Threshold');
      notify(obj,'UpdateViewers');
    end
    
    function negativeLatencyRange = getNegativeLatencyRange(obj)
      negativeLatencyRange = obj.dataExtractParams.negativeLatencyRange;
    end
    
    function setNegativeLatencyRange(obj,negativeLatencyRange)
      obj.dataExtractParams.negativeLatencyRange = negativeLatencyRange;
      notify(obj,'RefreshGUINeeded');
      obj.performTraceOperations('ScoringParameters');
      notify(obj,'UpdateViewers');
    end
    
    function maxPositiveLatency = getMaxPositiveLatency(obj)
      maxPositiveLatency = obj.dataExtractParams.maxPositiveLatency;
    end
    
    function setMaxPositiveLatency(obj,maxPositiveLatency)
      obj.dataExtractParams.maxPositiveLatency = maxPositiveLatency;
      notify(obj,'RefreshGUINeeded');
      obj.performTraceOperations('ScoringParameters');
      notify(obj,'UpdateViewers');
    end
    
    function TMDAType = getTMDAType(obj)
      TMDAType = obj.dataExtractParams.TMDAType;
    end
    
    function setTMDAType(obj,TMDAType)
      obj.dataExtractParams.TMDAType = TMDAType;
    end
    
    function setAutoChannelNaming(obj,boolValue)
      obj.nameChannels = boolValue;
      if ~obj.isHeadless
        handles = guidata(obj.fh);
        if boolValue
          onOrOff = 'on';
        else
          onOrOff = 'off';
        end
        set(handles.autoChNameMenu,'Checked',onOrOff);
      end
    end
    
    function resp = autoChannelNaming(obj)
      resp = obj.nameChannels;
      %handles = guidata(obj.fh);
      %resp = strcmp('on',get(handles.autoChNameMenu,'Checked'));
    end
    
    function key = getKeyForChannelNumber(obj,chNum)
      if obj.nameChannels && obj.channelNames.isKey(chNum)
        key = obj.channelNames(chNum);
      else
        key = num2str(chNum);
      end
    end
    
  end
  
end