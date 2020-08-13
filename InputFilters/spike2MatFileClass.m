classdef spike2MatFileClass < dataFileClass
  
  % Input filter fro spike2 data files (.mat), written for Sidirov
  % Assumes events are on ch32
  %
  % JG
  
  properties (Constant)
    menuString = 'Add Spike2 Data (.mat)';
    fileExtensionString = '.mat';
    selectionPromptString = 'Select Spike2 Data Files';
    dataDirSelections = false;    
  end
  
  methods
    
    function obj = spike2MatFileClass(varargin)
      obj = obj@dataFileClass(varargin{:});
    end
    
    function readData(obj)
      switch obj.readType
        case 'ad'
          % Load the data from the matlab file, with assumptions above, and
          % store in the dataFileObject
          data = load(obj.filename);
          channels = fieldnames(data);
          nCh = length(channels);
          chKeys = cell(1,nCh-1);
          counter = 0;
          sampleCounts = zeros(1,nCh-1);
          for iCh = 1:nCh
            theCh = channels{iCh};
            chData = data.(theCh);
            parts = regexp(theCh,'_','split');
            chName = parts{end};
            try
              switch chName
                case 'Ch32'
                  obj.eventData('timeStamps') = chData.times';
                  obj.eventData('eventValues') = bi2de(chData.codes)';
                  obj.eventData('nEvents') = chData.length;
                otherwise
                  counter = counter + 1;
                  sampleCounts(counter) = chData.length;
                  chKey = ['ch_' chName(3:end)];
                  chKeys{counter} = chKey;
                  obj.adData(chKey) = chData.values';
                  sampleInt = chData.interval;
                  obj.overrideChName(chKey) = chData.title;
              end
            catch ME
              % Show a warning if any channel fails, remove any stored data
              if exist('chKey','var') == 1
                counter = counter - 1;
                chKeys = chKeys(1:counter);
                if obj.adData.isKey(chKey)
                  obj.adData.remove(chKey);
                end
              end
              handleError(ME,false,...
                sprintf('Add Data Error for %s Ch %s',obj.filename,chName),2);
            end
          end
          
          % Make sure that all stored data has the same number of samples
          % and generate time stamps, zero pad if needed
          maxSamples = max(sampleCounts);
          if maxSamples ~= min(sampleCounts)
            keys = obj.adData.keys;
            for iK = 1:length(keys)
              theKey = keys{iK};
              data = obj.adData(theKey);
              data(length(data)+1:maxSamples) = 0;
              obj.adData(theKey) = data;
            end
          end
          obj.adData('timeStamps') = (0:maxSamples-1) * sampleInt;
          obj.adData('sampleFreq') = 1/sampleInt;
          obj.adData('nSamples') = maxSamples;
          obj.adData('channelKeys') = chKeys;
          % Update the existence flag
          obj.rawDataExists = true;
        otherwise
          error('Unknown read type %s',obj.readType);
      end
    end
    
  end
end