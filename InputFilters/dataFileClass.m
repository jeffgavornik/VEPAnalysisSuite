classdef (Abstract,ConstructOnLoad) dataFileClass < handle
  
  % Interface object used to create data InputFilters that know how to read
  % ePhys data from specific formats
  %
  % Create object using
  %    dfo = DFCsubclass(fileName,filePath,varargin);
  
  properties (Constant,Abstract)
    menuString
    fileExtensionString
    selectionPromptString
    dataDirSelections % Allow class to specify directory selection rather than file
  end
  
  properties
    % dataFileAttributesClass object
    attributes
    % Containers to hold extracted data
    adData % continuous data, by channel
    spikeData % unit data, by channel and unit
    eventData % stimulus events
    % VEPDataClass object that using this dataFileObject
    fileOwner 
    % Define optional mapping of channel number to name, used by
    % sessionRecordClass
    overrideChName
    % Provide for meta-data and stimulus definition storage
    metaData = containers.Map;
    rawDataExists % flag set when the object has data
  end
  
  properties (Transient=true,Access=protected)
    regIndici % stores indici of support registrations
    % autoDeleteTimer
    reloadListener = [];
    filterDataListener = [];
  end
  
  methods (Abstract=true)
    readData(obj,varargin) % subclass-specific method to read data from file
  end
  
  methods
    
    function obj = dataFileClass()
      fprintf('%s constructor',class(obj));
      % Construct the object
      obj.adData = containers.Map;
      obj.spikeData = containers.Map;
      obj.eventData = containers.Map;
      obj.rawDataExists = false;
      objectTrackerClass.startTracking(obj);
      % If the fileOwner is already defined (i.e. constructing a saved
      % object) then register for support
      if obj.fileOwner
        obj.registerForFileOwnerSupport(obj.fileOwner);
      end
      obj.overrideChName = containers.Map;
    end
    
    function setFileAttributes(obj,filename,filepath,varargin)
      % If path has not been defined, try to get it from the filename
      if ~exist('filepath','var') || isempty(filepath)
        [pathParts,ind] = regexp(filename,'/','split');
        if isempty(ind)
          filepath = [];
        else
          filepath = filename(1:ind(end));
          filename = pathParts{end};
        end
      end
      % Create an attributes object
      obj.attributes = dataFileAttributesClass(filename,filepath,varargin{:});
    end
    
    function registerForFileOwnerSupport(obj,fileOwner)
      % Provide for VDO support
      obj.fileOwner = fileOwner;
        obj.regIndici(1) = ...
          fileOwner.registerDeleteSupportFnc(@()delete(obj));
        obj.regIndici(2) = ...
          fileOwner.registerPrepForSaveSupportFnc(...
          @()clearRawData(obj));
      obj.reloadListener = addlistener(obj.fileOwner,'ReloadRawData',...
          @(src,evnt)readData(obj));
      obj.filterDataListener = addlistener(obj.fileOwner,'FilterData',...
          @(src,evnt)filterData(obj));
    end
    
    function delete(obj)
      fprintf('Deleting ''%s'' object, ID=''%s''\n',...
          class(obj),obj.attributes.fileName);
      objectTrackerClass.stopTracking(obj);
      if ~isempty(obj.reloadListener)
          delete(obj.reloadListener);
      end
      if ~isempty(obj.filterDataListener)
          delete(obj.filterDataListener);
      end
    end
    
    function deleteWithDeregistration(obj)
      % Remove top-of-hierarchy support
      if ~isempty(obj.fileOwner)
        obj.fileOwner.deregisterDeleteSupportFnc(obj.regIndici(1));
        obj.fileOwner.deregisterPrepForSaveSupportFnc(obj.regIndici(2));
      end
      delete(obj);
    end
    
    % Accessor functions - if the object has been cleared, regenerates
    % the raw data from the file then starts the autoDeleteTimer
    function eventValues = getEventValues(obj)
      if ~obj.rawDataExists
        obj.readData;
      end
      eventValues = obj.eventData('eventValues');
    end
    
    function timeStamps = getEventTimeStamps(obj)
      if ~obj.rawDataExists
        obj.readData;
      end
      timeStamps = obj.eventData('timeStamps');
    end
    
    function channelKeys = getChannelKeys(obj)
      if ~obj.rawDataExists
        obj.readData;
      end
      channelKeys = obj.adData('channelKeys');
    end
    
    function adData = getADData(obj,channelKey)
      if ~obj.rawDataExists
        obj.readData;
      end
      adData = obj.adData(channelKey);
    end
    
    function filterData(obj,digitalFilters)
        % Apply digital filters to all adData
        % Gets filters from the fileOwner unless passed as argument
        if nargin < 2
            digitalFilters = obj.fileOwner.digitalFilters;
        end
        channelKeys = obj.adData('channelKeys');
        for iF = 1:length(digitalFilters)
            theFilter = digitalFilters{iF};
            for iC = 1:length(channelKeys)
                channelKey = channelKeys{iC};
                obj.adData(channelKey) = ...
                filtfilt(theFilter,obj.adData(channelKey));
            end
        end
    end
    
    function timeStamps = getADTimeStamps(obj)
      if ~obj.rawDataExists
        obj.readData;
      end
      timeStamps = obj.adData('timeStamps');
    end
    
    function fileName = getFileName(obj)
      fileName = obj.attributes.fileName;
    end
    
    function filePath = getPath(obj)
        filePath = obj.attributes.path;
    end
    
    function fileName = fileName(obj)
      fileName = obj.attributes.fileName;
    end
    
    function fileName = fileNameWithPath(obj)
      fileName = obj.attributes.fileNameWithPath;
    end
    
    function attributes = getAttributes(obj)
      attributes = obj.attributes;
    end
    
    function setAttributes(obj,attributes)
      obj.attributes = attributes;
    end
    
    % Function that deletes all raw voltage data to mimize memory footprint
    % Should be called by before saving to .mat file or when all needed
    % info has been extracted
    function clearRawData(obj)
      if obj.rawDataExists
        delete(obj.adData);
        delete(obj.spikeData);
        delete(obj.eventData);
        obj.adData = containers.Map;
        obj.spikeData = containers.Map;
        obj.eventData = containers.Map;
        obj.rawDataExists = false;
      end
    end
    
  end
  
end