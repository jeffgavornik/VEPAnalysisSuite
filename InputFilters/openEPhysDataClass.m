classdef openEPhysDataClass < dataFileClass
  
  % Class the reads A/D stored in openEphys format
  %
  % JG
  
  properties (Constant)
      menuString = 'Add Open Ephys Data';
      dataTypeString = 'OpenEPhys';
      fileExtensionString = '*continuous';
      selectionPromptString = 'Select OpenEphys data directory';
      fileNameFormatString = 'FORMAT_ID_SESSION_EXTRA';
      dataDirSelections = true;
      evntFileName = 'all_channels.events';
  end
  
      
  
  methods
    
    function obj = openEPhysDataClass(filepath,fileOwner,varargin)
      % User can pass a dataFileAttributesClass object
      % or filename,filepath combination
      obj = obj@dataFileClass();
      fprintf('%s: reading data from %s:\n',class(obj),filepath);
      if isa(filepath,'dataFileAttributesClass')
        obj.attributes = filepath;
      else
        if ~exist('filepath','var')
          error('%s: must have filepath to datafiles',class(obj));
        end
        [path,folder] = fileparts(filepath);
        obj.setFileAttributes(folder,path,...
          obj.fileNameFormatString,varargin{:});
      end
      if exist('fileOwner','var') && isa(fileOwner,'VEPDataClass')
          registerForFileOwnerSupport(obj,fileOwner);
      end
      obj.attributes.sessionName = regexprep(obj.attributes.sessionName,'.plx','');
    end
    
    function readData(obj,~)
      try
        if nargin == 1
          readType = 'ad';
        end
        switch readType
          case 'ad'
              
            filepath = obj.fileNameWithPath;
            
            % Get the event data
            fprintf('\treading data from %s\n',obj.evntFileName);
            [eventValues,eventTimestamps] = ...
                getOpenEphysEvnts(fullfile(filepath,obj.evntFileName));
            nEvents = length(eventValues);
            
            % Find all channel data
            chFiles = dir(sprintf('%s/*_CH*.continuous',...
                obj.fileNameWithPath));
            nCh = length(chFiles);
            channelKeys = cell(1,nCh);
            for iC = 1:nCh
                % Figure out channel number
                chFile = chFiles(iC).name;
                iCh = regexp(chFile,'CH') +2;
                chNumber = sscanf(chFile(iCh:end),'%i');
                % Read the data
                fprintf('\treading data from %s\n',chFile);
                [adData,adTimestamps,info] = loadAndCorrectPhase(...
                    fullfile(chFiles(iC).folder,chFile),1);
                % Downsample to 1 Khz
                dsRate = info.header.sampleRate/1e3;
                adData = downsample(adData,dsRate);
                % Save data
                channelKey = sprintf('channel_%i',chNumber);
                obj.adData(channelKey) = adData';
                channelKeys{iC} = channelKey;
            end
            
            % Start time at 0
            eventTimestamps = eventTimestamps - adTimestamps(1);
            adTimestamps = adTimestamps - adTimestamps(1);
            
            % Get rid of any spurious timestamps that occur beyond the
            % adTs range
            adTimestamps = downsample(adTimestamps,dsRate)';
            goodValIndici = eventTimestamps < max(adTimestamps);
            if sum(goodValIndici) ~= nEvents
              fprintf(2,'Warning: ignoring invalid event timestamps in %s\n',obj.filename);
              eventTimestamps = eventTimestamps(goodValIndici);
              eventValues = eventValues(goodValIndici);
              nEvents = numel(eventTimestamps);
            end
            
            obj.adData('channelKeys') = channelKeys;
            obj.adData('nSamples') = length(adTimestamps);
            obj.adData('timeStamps') = adTimestamps;
            obj.adData('sampleFreq') = 1e3;
            % Store the event data
            obj.eventData('eventValues') = eventValues;
            obj.eventData('nEvents') = nEvents;
            obj.eventData('timeStamps') = eventTimestamps;
            % Save any meta data
            obj.metaData('asciiString') = '';
            obj.metaData('stimDefs') = [];
            
            % Update the existence flag
            obj.rawDataExists = true;
            
          case 'units'
            
          otherwise
            error('Unknown read type: %s',obj.readType);
        end
      catch ME
        if isempty(obj.fileOwner)
          useGUI = true;
        else
          useGUI = ~obj.fileOwner.isHeadless;
        end
        handleError(ME,useGUI,sprintf('%s.readData',class(obj)));
      end
    end
    
  end
  
end
