classdef sessionRecordClass < genericDataRecordClass
    
    properties
        dataRecords % raw data, dataFileClass
        stimRecords % data by stim, stimulusRecordClass
        listener
    end
    
    methods
        
        function obj = sessionRecordClass(varargin)
            if nargin > 0
                obj.constructObj(varargin{:});
            end
        end
        
        function constructObj(obj,aro,patriarch,stimKey)
            obj.setParent(aro);
            obj.setPatriarch(patriarch);
            obj.setID(stimKey);
            obj.stimRecords = containers.Map;
            obj.dataRecords = containers.Map;
            obj.setKids(obj.stimRecords);
            
            obj.listener = addlistener(patriarch,'ExtractTraces',...
                @(src,evnt)defineStims(obj));
        end
        
        % Extend superclass method to delete associated dataRecord
        % objects
        function deleteWithKids(obj)
            % Tell the vdo that data files are being removed
            fileKeys = obj.dataRecords.keys;
            obj.patriarch.filesBeingDeleted(fileKeys);
            for iF = 1:numel(fileKeys)
                theObj = obj.dataRecords(fileKeys{iF});
                if isvalid(theObj)
                    theObj.deleteWithDeregistration;
                end
            end
            deleteWithKids@genericDataRecordClass(obj);
        end
        
        function reportContent(obj,offset,fid)
            if nargin <2
                offset = '';
            end
            if nargin < 3
                fid = 1;
            end
            fprintf(fid,'%ssessionRecordClass: ID = ''%s''\n',offset,obj.ID);
            dataKeys = obj.dataRecords.keys;
            fprintf(fid,'%sIncluded Data Files:\n',offset);
            for iData = 1:numel(dataKeys)
                fprintf(fid,'%s  %i. %s\n',offset,iData,dataKeys{iData});
            end
            stimKeys = obj.stimRecords.keys;
            for iStim = 1:numel(stimKeys)
                theObj = obj.stimRecords(stimKeys{iStim});
                theObj.reportContent([offset char(9)],fid);
            end
        end
        
        function sro = getStimRecord(obj,stimKey)
            % Return the stimRecordObject specified by stimKey, create a
            % new SRO if it does not already exist
            if obj.stimRecords.isKey(stimKey)
                sro = obj.stimRecords(stimKey);
            else
                sro = stimulusRecordClass(obj,obj.patriarch,stimKey);
                obj.stimRecords(stimKey) = sro;
            end
        end
        
        function addData(obj,varargin)
            % Create an object to read the raw data from a data file and
            % add it to the dataRecords dictionary with a key that is the
            % filename (with path)
            try
                dataFileObj = varargin{1};
                fileKey = dataFileObj.attributes.fileNameWithPath;
                % dataFileObj.setAttributes(vepDataFileAttObj);
                obj.dataRecords(fileKey) = dataFileObj;
                obj.defineStims(fileKey);
            catch ME
                handleError(ME,~obj.patriarch.isHeadless,...
                    'sessionRecordClass.addData');
            end
        end
        
        
        function defineStims(obj,fileKeys)
            % Extract and group traces based on event values and the
            % stimulus definitions
            if nargin < 2
                fileKeys = obj.dataRecords.keys;
            end
            if ~iscell(fileKeys)
                fileKeys = {fileKeys};
            end
            
            vdo = obj.patriarch;
            extractParams = vdo.getDataExtractParams;
            
            % Define stims for the selected fileKeys
            for iF = 1:numel(fileKeys)
                theFileKey = fileKeys{iF};
                dataFileObj = obj.dataRecords(theFileKey);
                eventValues = dataFileObj.getEventValues;
                evTs = dataFileObj.getEventTimeStamps;
                adTs = dataFileObj.getADTimeStamps;
                channelKeys = dataFileObj.getChannelKeys;
                dataSrc = dataFileObj.getFileName;
                
                % Get the stim definitions and data extraction parameters from
                % the VEPDataClass Object at the top of the hierarchy
                if vdo.ignoreMetaData
                    stimDefs = vdo.stimDefs;
                else
                    stimDefs = dataFileObj.metaData('stimDefs');
                    if isempty(stimDefs)
                        stimDefs = vdo.stimDefs;
                    end
                end
                
                % If no stimulus definition exists, create a new stimulus for
                % each unique event type
                if isempty(stimDefs)
                    uniqueEvents = unique(eventValues);
                    stimDefs = containers.Map;
                    for ii = 1:length(uniqueEvents)
                        stimDefs(sprintf('%02i',uniqueEvents(ii))) = ...
                            uniqueEvents(ii);
                    end
                end
                
                % Loop over channels and keys extracting the traces and
                % adding to the appropriate stimRecordObject
                stimKeys = stimDefs.keys;
                for iC = 1:numel(channelKeys)
                    % Figure out how to interpret the channelKey - call an
                    % external function that maps from channel number to
                    % descriptive keys or use override values from the dataFileObj
                    theChannelKey = channelKeys{iC};
                    parts = regexp(theChannelKey,'_','split');
                    theChannelNumber = str2double(parts{end});
                    if dataFileObj.overrideChName.isKey(theChannelKey)
                        theChannelID = dataFileObj.overrideChName(theChannelKey);
                    else
                        theChannelID = ...
                            obj.patriarch.getKeyForChannelNumber(theChannelNumber);
                    end
                    
                    % Get the channel specific data extraction time window
                    extractTimeWindow = extractParams.extractTimeWindow;
                    if isfield(extractParams,'extractTimeWindowOverride')
                        overrideDict = extractParams.extractTimeWindowOverride;
                        if overrideDict.isKey(theChannelID)
                            extractTimeWindow = overrideDict(theChannelID);
                        end
                    end
                    
                    % Extract all the traces for the channel
                    if numel(extractTimeWindow) == 1
                        [traces,tTr] = extractEventTriggeredTraces(evTs,...
                            dataFileObj.getADData(theChannelKey),...
                            adTs,extractTimeWindow);
                    else
                        negTime = extractTimeWindow(1);
                        posTime = extractTimeWindow(2);
                        % fprintf(2,'extractingTraces\n');%DEBUG CODE
                        drawnow;
                        [traces,tTr] = ...
                            extractEventTriggeredTraces(evTs,...
                            dataFileObj.getADData(theChannelKey),...,
                            adTs,negTime,posTime);
                        % fprintf(2,'done extractingTraces\n');%DEBUG CODE
                        drawnow;
                        % downsample
                        %fprintf(2,'%s - Downsample\n',class(obj));
                        indici = 1:10:numel(tTr);
                        tTr = tTr(indici);
                        traces = traces(indici,:);
                    end
                    
                    % Look for a channel specific event definition function
                    eventDefFnc = vdo.getEventDefOverrideFnc(theChannelID);
                    
                    % Add traces to the appropriate stimulusRecordObject
                    for iS = 1:numel(stimKeys)
                        theStimKey = stimKeys{iS};
                        theEventValues = stimDefs(theStimKey);
                        sro = obj.getStimRecord(theStimKey);
                        traceIndici = false(size(evTs));
                        % if a channel specific override exists for
                        % defining event values, use it - this might
                        % occur, for example, when looking at data
                        % recorded a piezzo channel
                        % the default behavior is to match against all
                        % instances of the event value
                        if isa(eventDefFnc,'function_handle')
                            traceIndici = eventDefFnc(...
                                theEventValues,eventValues,traceIndici);
                        else
                            for iE = 1:numel(theEventValues)
                                eV = theEventValues(iE);
                                traceIndici(eventValues==eV) = true;
                            end
                        end
                        if sum(traceIndici) > 0 % do not add if there are no instances of the stimulus event
                            % Note: modified to include evTs on 7/24/12
                            sro.addTracesForChannel(theChannelID,...
                                traces(:,traceIndici),tTr,dataSrc,...
                                evTs(traceIndici),theEventValues,extractParams,...
                                theChannelKey);
                            sro.setChannelNumber(theChannelID,...
                                theChannelNumber);
                        end
                    end
                end
                
                % Delete any stimulus records created above that are empty
                % (i.e. do not contain any traces)
                for iS = 1:numel(stimKeys)
                    theStimKey = stimKeys{iS};
                    sro = obj.getStimRecord(theStimKey);
                    sro.removeEmptyKids;
                    if sro.isEmpty
                        delete(sro);
                        obj.stimRecords.remove(theStimKey);
                    end
                end
                
                % Tell the plexonFileDataObject to free up memory
                dataFileObj.clearRawData;
            end
        end
        
        % The following method is used to regenerate and return raw trace
        % data
        function [traces,tTr] = getTracesForChannel(obj,fileKey,...
                channelKey,extractParams,eventValues,channelID)
            keys = obj.dataRecords.keys;
            theKey = keys{contains(keys,fileKey)};
            if isempty(theKey)
                error('fileKey not found');
            end
            dataFileObj = obj.dataRecords(theKey);
            evTs = dataFileObj.getEventTimeStamps;
            
            % Get the channel specific data extraction time window
            extractTimeWindow = extractParams.extractTimeWindow;
            if isfield(extractParams,'extractTimeWindowOverride')
                overrideDict = extractParams.extractTimeWindowOverride;
                if overrideDict.isKey(channelID)
                    extractTimeWindow = overrideDict(channelID);
                end
            end
            
            % Extract all the traces for the channel
            if numel(extractTimeWindow) == 1
                [allTraces,tTr] = extractEventTriggeredTraces(evTs,...
                    dataFileObj.getADData(channelKey),...
                    dataFileObj.getADTimeStamps,...
                    extractTimeWindow);
            else
                negTime = extractTimeWindow(1);
                posTime = extractTimeWindow(2);
                [allTraces,tTr] = extractEventTriggeredTraces(evTs,...
                    dataFileObj.getADData(channelKey),...,
                    dataFileObj.getADTimeStamps,...
                    negTime,posTime);
            end
            
            %[allTraces,tTr] = extractEventTriggeredTraces(evTs,...
            %    dataFileObj.getADData(channelKey),...
            %    dataFileObj.getADTimeStamps,...
            %    extractTimeWindow);
            
            %  % Look for a channel specific event definition function
            %  vdo = obj.patriarch;
            %  eventDefFnc = vdo.getEventDefOverrideFnc(channelID);
            
            traceIndici = false(size(evTs));
            allEventValues = dataFileObj.getEventValues;
            for iE = 1:numel(eventValues)
                traceIndici(allEventValues==eventValues(iE)) = true;
            end
            traces = allTraces(:,traceIndici);
            
            disp('channelID ''%s'' size(traces) = [%i,%i]\n',...
                channelID,size(traces,1),size(traces,2));
            
        end
        
    end % methods
    
end % classdef