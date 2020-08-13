classdef (ConstructOnLoad) plxFileDataClass < dataFileClass
  
  % Class the reads A/D data from a plexon file
  %
  % JG
  
  properties (Constant)
      menuString = 'Add Plexon Data (.plx)';
      dataTypeString = 'Plexon';
      fileExtensionString = '.plx';
      selectionPromptString = 'Select Plexon Data Files';
      fileNameFormatString = 'FORMAT_ID_SESSION_EXTRA';
      dataDirSelections = false;
  end
  
  methods
    
    function obj = plxFileDataClass(varargin)
      % User can pass a dataFileAttributesClass object
      % or filename,filepath combination
      % Variables are filename,filepath,fileOwner,varargin
      obj = obj@dataFileClass();
      if nargin > 0
          obj.constructObject(varargin{:})
      end
    end
    
    function constructObject(obj,filename,filepath,fileOwner,varargin)
        disp('dataFileClass constructor');
        if isa(filename,'dataFileAttributesClass')
            obj.attributes = filename;
        else
            if ~exist('filepath','var')
                filepath = '';
            end
            obj.setFileAttributes(filename,filepath,...
                obj.fileNameFormatString,varargin{:});
        end
        obj.attributes.sessionName = regexprep(obj.attributes.sessionName,'.plx','');
        if exist('fileOwner','var') && isa(fileOwner,'VEPDataClass')
            registerForFileOwnerSupport(obj,fileOwner);
        end
    end
    
    function readData(obj,readType)
      try
        if nargin == 1
          readType = 'ad';
        end
        switch readType
          case 'ad'
            % Extract AD and event data from the plx file
            data = simplePlxReader(obj.fileNameWithPath);
            
            % Get rid of any spurious timestamps that occur beyond the
            % adTs range
            goodValIndici = data.eventTimestamps < max(data.adTimestamps);
            if sum(goodValIndici) ~= data.nEvents
              fprintf(2,'Warning: ignoring invalid event timestamps in %s\n',obj.filename);
              data.eventTimestamps = data.eventTimestamps(goodValIndici);
              data.eventValues = data.eventValues(goodValIndici);
              data.nEvents = numel(evTs);
            end
            
            % Store AD data by channel, converted to uV
            nCh = numel(data.adChannels);
            channelKeys = cell(1,nCh);
            for iCh = 1:nCh
              channelKey = sprintf('channel_%i',data.adChannels(iCh));
              % Apply any filters from the data owner
              if ~isempty(obj.fileOwner) && obj.fileOwner.filterData
                  disp('Filtering data...');
                  digitalFilters = obj.fileOwner.digitalFilters;
                  for iF = 1:length(digitalFilters)
                      theFilter = digitalFilters{iF};
                      data.adData(iCh,:) = filtfilt(theFilter,...
                          data.adData(iCh,:));
                  end
              end
              % Convert to uV and save data
              obj.adData(channelKey) = 1000*data.adData(iCh,:);
              channelKeys{iCh} = channelKey;
            end
            obj.adData('channelKeys') = channelKeys;
            obj.adData('nSamples') = data.nSamples;
            obj.adData('timeStamps') = data.adTimestamps;
            obj.adData('sampleFreq') = data.adFreq;
            % Store the event data
            obj.eventData('eventValues') = data.eventValues;
            obj.eventData('nEvents') = data.nEvents;
            obj.eventData('timeStamps') = data.eventTimestamps;
            % Save any meta data
            obj.metaData('asciiString') = data.asciiString;
            obj.metaData('stimDefs') = data.stimDefs;
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
        handleError(ME,useGUI,'plxFileDataClass.readData');
      end
    end
    
  end
  
end
