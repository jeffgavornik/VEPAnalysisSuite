classdef voltageTraceDataClass < genericDataRecordClass
    
    properties
        traces % event/strobe triggered raw voltage traces
        nTr % number of traces
        tTr % time vector into the traces
        evTs % event time stamps from data file
        validIndici % after applying threshold
        srcID % the name of the file the data came from
        uniqueID % optional string to describe the data
        meanTrace % average of valid traces
        scoringRecords % disctionary of scoring results
        activeScoringKey % key for selected score source
        smoothWidth % used to smooth data
        scrubThreshold % used to invalidate traces corrupted by movement artifacts        
    end
    
    properties (Hidden=true)
       % Parameters used to regenerate the data
        rawDataExists
        extractParams
        eventValues
        dataChannelKey
        regIndici % stores indici of support registrations
    end
    
    methods
        
        function obj = voltageTraceDataClass(varargin)
            if nargin > 0
                obj.constructObject(varargin{:});
            end
            % Setup for top-of-hierarchy support - select actions to
            % perform when the VDO prepares to save itself (i.e. get rid of
            % raw traces to save space) or when analysis parameters change
            % (i.e. traceOperations)
            obj.regIndici(1) = ...
                obj.patriarch.registerPrepForSaveSupportFnc(...
                @()clearRawData(obj));
            obj.regIndici(2) = ...
                obj.patriarch.registerTraceDataSupportFnc(...
                @(ctrlArg)performOperation(obj,ctrlArg));
        end
        
        function constructObject(obj,cdo,patriarch,dataSrcKey,uniqueIDKey,...
                traces,tTr,evTs,eventValues,extractParams,dataChannelKey)
            % Store voltage traces and basic information
            obj.setParent(cdo);
            obj.setPatriarch(patriarch);
            obj.setID([dataSrcKey ':' uniqueIDKey]);
            obj.traces = traces;
            obj.nTr = size(traces,2);
            obj.tTr = tTr;
            obj.evTs = evTs;
            obj.validIndici = true(1,obj.nTr);
            obj.nTr = sum(obj.validIndici);
            obj.srcID = dataSrcKey;
            obj.uniqueID = uniqueIDKey;
            obj.rawDataExists = true;
            % Create dictionary that will hold scoring data
            obj.scoringRecords = containers.Map;
            obj.activeScoringKey = '';
            % save information that will be necessary to regenerate the raw
            % data
            obj.extractParams = extractParams;
            obj.eventValues = eventValues;
            obj.dataChannelKey = dataChannelKey;
            % Call the scrubTraces method to start analysis
            obj.scrubTraces();
        end
        
        % Extend superclass method to deregister top level support
        function deleteWithKids(obj)
            % Remove top-of-hierarchy support and call superclass delete
            obj.patriarch.deregisterPrepForSaveSupportFnc(obj.regIndici(1));
            obj.patriarch.deregisterTraceDataSupportFnc(obj.regIndici(2));
            deleteWithKids@genericDataRecordClass(obj);
        end
        
        function performOperation(obj,ctrlArg)
            switch ctrlArg
                case 'Threshold'
                    obj.scrubTraces();
                case 'Smoothing'
                    obj.calculateMeanTrace();
                case 'ScoringParameters'
                    obj.autoScore();
                otherwise
                    % default behavior is to start from the top and
                    % recalculate everything
                    obj.scrubTraces();
            end
        end
        
        function scrubTraces(obj)
            % Invalidate traces with large voltage swings indicative of
            % movement artifacts
            if ~obj.rawDataExists
                obj.regenerateRawData;
            end
            obj.scrubThreshold = obj.patriarch.getScrubThreshold();
            obj.validIndici = true(1,obj.nTr);
            if obj.scrubThreshold ~= 0
                invalidIndici = range(obj.traces,1) > obj.scrubThreshold;
                obj.validIndici(invalidIndici) = false;
                % fprintf('\t%i traces rejected\n',sum(invalidIndici));
            end
            obj.calculateMeanTrace();
        end
        
        function calculateMeanTrace(obj)
            % Calculate the mean of valid traces, apply smoothing, call
            % autoScore
            if ~obj.rawDataExists
                obj.regenerateRawData;
            end
            switch obj.getParent('channelDataClass').getID();
                case 'piezzo'
                    obj.meanTrace = calculatePiezzoMeanTrace(obj.traces,obj.tTr);
                otherwise
                    obj.meanTrace = mean(obj.traces(:,obj.validIndici),2);
            end
            obj.smoothWidth = obj.patriarch.getSmoothWidth();
            if obj.smoothWidth ~= 0
                obj.meanTrace = ...
                    gauss_smooth(obj.meanTrace,obj.smoothWidth,3);
            end
            obj.autoScore();
        end
        
        function autoScore(obj)
            % Score the mean VEP
            switch obj.getParent('channelDataClass').getID();
                case 'piezzo'
                    theScore = autoscorePiezzoData(...
                        obj.meanTrace,obj.tTr,...
                        obj.patriarch.getDataExtractParams());
                otherwise
                    % case {'LH' 'RH'}
                    % If the trace is designated as being either LH or RH,
                    % use the VEP autoscore routine
                    theScore = autoscoreVoltageTraces(...
                        obj.meanTrace,obj.tTr,...
                        obj.patriarch.getDataExtractParams());
            end
            obj.scoringRecords('autoscore') = theScore;
            if isempty(obj.activeScoringKey)
                obj.activeScoringKey = 'autoscore';
            end
        end
        
        function addScoreFromSrc(obj,srcKey,scoreStruct)
            obj.scoringRecords(srcKey) = scoreStruct;
            obj.activeScoringKey = srcKey;
            obj.patriarch.occupado(true);
            obj.patriarch.occupado(false);
            notify(obj.patriarch,'DataAddedOrRemoved');
            notify(obj.patriarch,'UpdateViewers');
        end
        
        function srcKeys = getScoringSources(obj)
           srcKeys = obj.scoringRecords.keys;
        end
        
        function srcKey = getActiveScoringSource(obj)
            srcKey = obj.activeScoringKey;
        end
        
        function [meanTrace, tTr] = getMeanTrace(obj)
            meanTrace = obj.meanTrace;
            tTr = obj.tTr;
        end
        
        function traceScore = getMeanScore(obj)
            % Return the active mean trace score
            traceScore = obj.scoringRecords(obj.activeScoringKey);
        end
        
        function selectScoringSource(obj)
            % if source changes, need to re-analyze reliability unless
            % tracewise analysis is being used - setup a callback to handle
            % this situation
            scoringSources = obj.scoringRecords.keys;
            if numel(scoringSources) > 1
                choiceIndex = menu(...
                    sprintf('Choose scoring source for %s',obj.ID),...
                    scoringSources);
                obj.activeScoringKey = scoringSources{choiceIndex};
                notify(obj.patriarch,'UpdateViewers');
            end
        end
        
        function [traces, tTr] = getTraces(obj,includeInvalidTraces)
            % Return all traces - by default, only include valid traces
            if nargin < 2
                includeInvalidTraces = false;
            end
            if ~obj.rawDataExists
                obj.regenerateRawData;
            end
            if includeInvalidTraces
                traces = obj.traces;
            else
                traces = obj.traces(:,obj.validIndici);
            end
            tTr = obj.tTr;
        end
        
        % Delete AD data to save memory or in preparation for saving
        function clearRawData(obj)
            %fprintf('voltageTraceClass:clearRawData %s\n',obj.ID);
            obj.traces = [];
            obj.rawDataExists = false;
        end
        
        function regenerateRawData(obj)
            % request trace data from the parent
            pathKeys = {'na' 'na' 'na' 'na' 'na' 'na'};
            dataSpecifier = 'getTracesForChannel';
            args = {obj.srcID,obj.dataChannelKey,obj.extractParams,...
                obj.eventValues,obj.parent.ID};
            dso = dataSpecifierClass(pathKeys,dataSpecifier,args);
            dso.setDirectionUp;
            dso.setTargetLevel(3);
            [obj.traces,obj.tTr] = obj.returnData(dso);
            obj.rawDataExists = true;
        end
        
        % These function should really be external analyses
        function psdResults = getPSDResults(obj)
            scrubOnComplete = false;
                if ~obj.rawDataExists
                    obj.regenerateRawData;
                    scrubOnComplete = true;
                end
                adFreq = 1/(obj.tTr(2)-obj.tTr(1));
                psdResults = psdTracewiseAnalysis(...
                    obj.traces(:,obj.validIndici),adFreq);
            if scrubOnComplete
                obj.clearRawData;
            end
        end
        
    end
    
end