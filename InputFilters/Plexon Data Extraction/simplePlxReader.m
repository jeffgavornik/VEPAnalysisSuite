function fileContents = simplePlxReader(filenames)
% Wrapper around extractPlxad that makes it easy to use without having to
% remember all the order of output variables

try
    
    if nargin == 0
        [filenames,dirPath] = uigetfile('*.plx','Select Plexon Data File',...
            'MultiSelect', 'on',pwd);
        if isequal(filenames,0)
            return;
        end
    else
        dirPath = '';
    end
    
    if isa(filenames,'char')
        filenames = {filenames};
    end
    
    for ii = 1:length(filenames)
        
        switch class(filenames)
            case 'struct'
                filename = fullfile(filenames(ii).folder,filenames(ii).name);
            case 'cell'
                filename = fullfile(dirPath,filenames{ii});
            otherwise
                error('unknown filenames type %s',class(filenames));
        end
        if exist(filename,'file') ~= 2
            error('Filename %s does not exist',filename);
        end
                
        [ad, ~, nSamples, ev, evTs, ~, adFreq, adTs, adCh] = ...
            extractPLXad(filename);
        
        % Look for metadata if it exists
        [eventValues,asciiString,eventInd] = ...
            readASCIIFromEventCodes(ev);
        ev = eventValues;
        nEv = length(eventValues);
        evTs = evTs(eventInd);
        
        % Convert meta data to stimulus definitions
        stimDefs = readStimDefsFromMetaData(asciiString);
        keys = stimDefs.keys;
        for iK = 1:length(keys)
            if sum(ev == stimDefs(keys{iK})) == 0
                stimDefs.remove(keys{iK});
            end
        end
        
        % Write everything to the return structure
        fileContents(ii).filename = filename;
        fileContents(ii).adData = ad; %#ok<*AGROW>
        fileContents(ii).adTimestamps = adTs;
        fileContents(ii).adFreq = adFreq;
        fileContents(ii).adChannels = adCh;
        fileContents(ii).nSamples = nSamples;
        fileContents(ii).eventValues = ev;
        fileContents(ii).eventTimestamps = evTs;
        fileContents(ii).nEvents = nEv;
        fileContents(ii).asciiString = asciiString;
        fileContents(ii).stimDefs = stimDefs;
    end
    
catch ME
    handleError(ME,true,'Plx File Read Error');
    fileContents = [];
end