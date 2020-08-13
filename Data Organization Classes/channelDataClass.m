classdef channelDataClass < genericDataRecordClass
    % Notes: data can be added from different sources
    
    properties
        traceRecords % keyed voltageTraceDataClass objects
        channelNumber
        userDataSelection % allow the user to choose which data srcs to use
    end
    
    methods
        
        function obj = channelDataClass(varargin)
            if nargin > 0
                obj.constructObj(varargin{:});
            end
        end
        
        function constructObj(obj,sro,patriarch,channelKey)
            obj.setParent(sro);
            obj.setPatriarch(patriarch);
            obj.setID(channelKey);
            obj.traceRecords = containers.Map;
            obj.setKids(obj.traceRecords);
            obj.userDataSelection = false;
        end
        
        function setChannelNumber(obj,channelNumber)
            obj.channelNumber = channelNumber;
        end
        
        function channelNumber = getChannelNumber(obj)
            channelNumber = obj.channelNumber;
        end
        
        function addTracesFromSrc(obj,traces,tTr,dataSrcKey,...
                evTs,eventValues,extractParams,dataChannelKey)
            % if the dataSrcKey is already in use, prompt for a unique key
            % and use that as well - TBD
            % Note: modified to include evTs on 7/24/12
            uniqueIDKey = '';
            if obj.traceRecords.isKey(dataSrcKey)                
                symbols = ['a':'z' 'A':'Z' '0':'9'];
                MAX_ST_LENGTH = 10;
                stLength = randi(MAX_ST_LENGTH);
                nums = randi(numel(symbols),[1 stLength]);
                uniqueIDKey = symbols (nums);
                fprintf('%s.addTracesFromSrc: Using random unique key %s\n',...
                    class(obj),uniqueIDKey);
                % uniqueIDKey = userSelectUniqueKey(); %  ---TBD---
                dataSrcKey = sprintf('%s:%s',dataSrcKey,uniqueIDKey);
            end
            vtdo = voltageTraceDataClass(obj,obj.patriarch,dataSrcKey,...
                uniqueIDKey,traces,tTr,evTs,eventValues,extractParams,...
                dataChannelKey);
            obj.traceRecords(dataSrcKey) = vtdo;
            obj.makeCombinedTraceRecord;
        end
        
        function makeCombinedTraceRecord(obj)
            % If more than one source has been added, generate a single
            % record that combines the data from all sources - the default
            % behavior is to return this data to all queries
            if numel(obj.traceRecords.keys) > 1
                %-TBD-
            end
        end
        
        function activeVTDO = getActiveTraceObject(obj)
            % Return the active traceDataObject - should handle the case
            % whe
            if obj.userDataSelection
                theRecordKey = userSelectRecordKey(); %  ---TBD---
            else
                trKeys = obj.traceRecords.keys;
                if numel(trKeys) > 1
                    theRecordKey = 'combinedData';
                else
                    theRecordKey = trKeys{1};
                end
            end
            activeVTDO = obj.traceRecords(theRecordKey);
        end
        
        function [meanTrace,tTr] = getMeanTrace(obj)
            % If the caller has requested a specified source be used prompt
            % the user to select it, the default behavior is to use the
            % combined data (if it exists)
            vtdo = obj.getActiveTraceObject;
            [meanTrace,tTr] = vtdo.getMeanTrace;
        end
        
        function [traces,tTr] = getTraces(obj,varargin)
            vtdo = obj.getActiveTraceObject;
            [traces,tTr] = vtdo.getTraces(varargin{:});
        end
        
        function scoreData = getMeanScoreData(obj,dataSelector)
            % If the caller has requested a specified source be used prompt
            % the user to select it, the default behavior is to use the
            % combined data (if it exists)
            vtdo = obj.getActiveTraceObject;
            scoreData = vtdo.getMeanScore;
            if nargin > 1
                scoreData = scoreData.(dataSelector);
            end
        end
        
        function [neg,pos] = getScoreLatencies(obj)
            % If the caller has requested a specified source be used prompt
            % the user to select it, the default behavior is to use the
            % combined data (if it exists)
            [neg,pos] = getScoreLatencies(obj.getActiveTraceObject);
        end
        
        function tmdaResults = getTMDA(obj,dataKey)
            vtdo = obj.getActiveTraceObject;
            tmdaResults = vtdo.getTMDAResults;
            if nargin > 1
                tmdaResults = tmdaResults(dataKey);
            end
        end
        
        function psdResults = getPSD(obj,dataKey)
            vtdo = obj.getActiveTraceObject;
            psdResults = vtdo.getPSDResults;
            if nargin > 1
                psdResults = psdResults(dataKey);
            end
        end
        
        function addScoreFromSrc(obj,srcKey,scoreStruct)
            vtdo = obj.getActiveTraceObject;
            vtdo.addScoreFromSrc(srcKey,scoreStruct);
        end
        
    end
    
end