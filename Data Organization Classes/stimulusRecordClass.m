classdef stimulusRecordClass < genericDataRecordClass
    
    properties
       channelData
       eventValues
    end
    
    methods
        
        function obj = stimulusRecordClass(varargin)
            if nargin > 0
                obj.constructObj(varargin{:});
            end
        end
        
        function constructObj(obj,sro,patriarch,stimKey)
            obj.setParent(sro);
            obj.setPatriarch(patriarch);
            obj.setID(stimKey);
            obj.channelData = containers.Map;
            obj.setKids(obj.channelData);
        end
        
        function reportContent(obj,offset,fid)
            if nargin <2
                offset = '';
            end
            if nargin < 3
                fid = 1;
            end
            fprintf(fid,'%sstimulusRecordClass: ID = ''%s'' [',offset,obj.ID);
            for iE = 1:length(obj.eventValues) -1
              fprintf(fid,'%i ',obj.eventValues(iE));
            end
            fprintf(fid,'%i] Channels: ',obj.eventValues(end));
            channelKeys = obj.channelData.keys;
            for iC = 1:numel(channelKeys)
                fprintf(fid,'''%s'' ',channelKeys{iC});
            end
            fprintf(fid,'\n');
        end 
        
        
        function cdo = getChannelDataObject(obj,channelKey)
            if obj.channelData.isKey(channelKey)
                cdo = obj.channelData(channelKey);
            else
                cdo = channelDataClass(obj,obj.patriarch,channelKey);
                obj.channelData(channelKey) = cdo;
            end
        end
        
        function addTracesForChannel(obj,channelKey,traces,tTr,dataSrc,...
                evTs,eventValues,extractParams,dataChannelKey)
            % Note: modified to include evTs on 7/24/12
            obj.eventValues = eventValues;
            cdo = obj.getChannelDataObject(channelKey);
            cdo.addTracesFromSrc(traces,tTr,dataSrc,...
                evTs,eventValues,extractParams,dataChannelKey);
        end
        
        function setChannelNumber(obj,channelKey,channelNumber)
            obj.getChannelDataObject(channelKey).setChannelNumber(channelNumber);
        end
        
        function channelKeys = getChannelKeys(obj)
            channelKeys = obj.channelData.keys;
        end
        
    end
    
end