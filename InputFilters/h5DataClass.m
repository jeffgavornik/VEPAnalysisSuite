classdef h5DataClass < dataFileClass
  
  % Class the reads A/D stored in openEphys format
  %
  % JG
  
  properties (Constant)
      menuString = 'Add H5 Data';
      dataTypeString = 'H5';
      fileExtensionString = '*.h5';
      selectionPromptString = 'Select h5 data file';
      fileNameFormatString = 'FORMAT_ID_SESSION_EXTRA';
      dataDirSelections = false;
  end
  
  methods
    
      function obj = h5DataClass(varargin)
          % User can pass a dataFileAttributesClass object
          % or filename,filepath combination
          % Variables are filename,filepath,fileOwner,varargin
          obj = obj@dataFileClass();
          if nargin > 0
              obj.constructObject(varargin{:})
          end
      end
    
    function constructObject(obj,filename,filepath,fileOwner,varargin)
        if isa(filename,'dataFileAttributesClass')
            obj.attributes = filename;
        else
            if ~exist('filepath','var')
                filepath = '';
            end
            obj.setFileAttributes(filename,filepath,...
                obj.fileNameFormatString,varargin{:});
        end
        obj.attributes.sessionName = regexprep(obj.attributes.sessionName,'.h5','');
        if exist('fileOwner','var') && isa(fileOwner,'VEPDataClass')
            registerForFileOwnerSupport(obj,fileOwner);
        end
    end

    function readData(obj,~)
      try
        if nargin == 1
          readType = 'ad';
        end
        switch readType
          case 'ad'
              
            fname = obj.fileNameWithPath;
            %fname = [filepath '.h5'];
            % Get the event data
            fprintf('\treading data from %s\n', fname);
            eventValues = h5read(fname, '/eventValues');
            eventTimestamps = h5read(fname, '/eventTimestamps');

            nEvents = length(eventValues);
            adData = 1000*h5read(fname, '/adData');
            adTimestamps = h5read(fname, '/adTimestamps');            
            adChannels = h5read(fname, '/adChannels');
            adFreq = h5readatt(fname, '/', 'adFreq');

            % Find all channel data
            nCh = numel(adChannels);
            channelKeys = cell(1,nCh);
            for iC = 1:nCh
                % Figure out channel number
                chNumber = adChannels(iC);
                channelKey = sprintf('channel_%i', chNumber);                

                % Save data
                obj.adData(channelKey) = adData(iC, :); % transpose?
                channelKeys{iC} = channelKey;
            end
            
            % Start time at 0
            eventTimestamps = eventTimestamps - adTimestamps(1);
            adTimestamps = adTimestamps - adTimestamps(1);
            
            % Get rid of any spurious timestamps that occur beyond the
            % adTs range            
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
            obj.adData('sampleFreq') = adFreq;
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
