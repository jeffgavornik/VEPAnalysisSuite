classdef dataSpecifierClass < handle
    % Class that is used to extract data from within the VEPDataClass 
    % heiarchy
    
    properties
        % Define the name and relation of the classes that
        % make up the VEPDataClass hierarchy
        hierarchyKeys = {...
            'VEPDataClass',...
            'animalRecordClass' ...
            'sessionRecordClass',...
            'stimulusRecordClass',...
            'channelDataClass' ...
            'voltageTraceDataClass'...
            };
        requestedDataPath % specific heiarchy keys to find the data
        % the data specifier for the target class, a string that can be
        % either the name of a class parameter or method
        dataSpecifier 
        % optional variables to be passed if dataSpecified references a
        % function
        fncArgs
        % By defualt, direction is down meaning that parents should pass
        % requests to their kids.  If set to 'up' kids should pass requests
        % to their parent
        direction
        IDString
    end
    
    methods (Static = true)
        function obj = loadobj(obj)
            if isempty(obj.direction) % for backward compatibility
                obj.direction = 'down';
            end
        end
    end
    
    methods
        function obj = dataSpecifierClass(varargin)
            obj.requestedDataPath = containers.Map;
            obj.dataSpecifier = '';
            obj.fncArgs = {};
            obj.IDString = '';
            obj.direction = 'down';
            obj.configureObject(varargin{:});
        end
        
        function configureObject(obj,pathKeys,dataSpecifier,varargin)
            if nargin > 1
                nKeys = numel(pathKeys);
                for iK = 1:nKeys
                    %obj.requestedDataPath(obj.hierarchyKeys{iK}) = ...
                    %    pathKeys{iK};
                    obj.setHierarchyLevel(iK,pathKeys{iK});
                end
                if nargin > 3
                    obj.fncArgs = varargin{:};
                    if ~iscell(obj.fncArgs)
                        obj.fncArgs = {obj.fncArgs};
                    end
                end
                obj.dataSpecifier = dataSpecifier;
                obj.makeIDString();
            end
        end
        
        function setDirectionUp(obj)
            obj.direction = 'up';
        end
        
        function setDataPathElement(obj,dataDescription,varargin)
            % Convert between the description and hierarachy level
            % Valid values of dataDescription are 'animal', 'session',...
            % 'stimulus' and 'channel'
            switch lower(dataDescription)
                case 'animal'
                    level = 1;
                case 'session'
                    level = 2;
                case 'stimulus'
                    level = 3;
                case 'channel'
                    level = 4;
                otherwise
                    error('%s.setDataPathElement: Unknown dataDescription %s',...
                        class(obj),dataDescription);
            end
            obj.setHierarchyLevel(level,varargin{:});
        end
    
        function setHierarchyLevel(obj,level,key,endFlag)
            % set end flag to indicate that this level is the last valid
            % hiearchy level of the - clear all levels below it.  Used by
            % the memberSelectionApp
            if nargin < 4
                endFlag = false;
            end
            % Set the key for the specified level number
            obj.requestedDataPath(obj.hierarchyKeys{level}) = key;   
            if endFlag
                obj.setEndLevel(level);
            end
        end
        
        function setEndLevel(obj,level)
            for iL = level+1:numel(obj.hierarchyKeys)
                theLevelKey = obj.hierarchyKeys{iL};
                if obj.requestedDataPath.isKey(theLevelKey)
                    obj.requestedDataPath.remove(theLevelKey);
                end
            end
        end
        
        function key = getHierarchyLevel(obj,level)
            key = obj.requestedDataPath(obj.hierarchyKeys{level});
        end
        
        
        function setTargetLevel(obj,level)
            % Removes the datapath keys at the target hiearchy return level
            % so that the request will not propogate any further
            % Example in voltageTraceDataClass.regenerateRawData
            theLevelKey = obj.hierarchyKeys{level};
            if obj.requestedDataPath.isKey(theLevelKey)
                obj.requestedDataPath.remove(theLevelKey);
            end
        end
        
        function resetDataPath(obj)
            obj.requestedDataPath = containers.Map;
        end
            
        
        function makeIDString(obj)
            theStr = '';
            for iK = 1:obj.requestedDataPath.length
                theStr = sprintf('%s%s_',theStr,...
                    obj.requestedDataPath(obj.hierarchyKeys{iK}));
            end
            theStr = theStr(1:end-1);
%             theStr = sprintf('%s%s',theStr,obj.dataSpecifier);
            obj.IDString = theStr;
        end
        
        function pathKey = getPathKey(obj,callingObj)
            callingClass = class(callingObj);
            if obj.requestedDataPath.isKey(callingClass)
                pathKey = obj.requestedDataPath(callingClass);
            else
                pathKey = [];
            end
        end
        
        % Return a new dataSpecifierObject that is a duplicate of the
        % calling object
        function newDSO = copy(obj)
            newDSO = dataSpecifierClass();
            pathKeys = obj.requestedDataPath.keys;
            for iK = 1:numel(pathKeys)
                theKey = pathKeys{iK};
                newDSO.requestedDataPath(theKey) = ...
                    obj.requestedDataPath(theKey);
            end
            newDSO.dataSpecifier = obj.dataSpecifier;
            newDSO.fncArgs = obj.fncArgs;
        end
        
        function requestedDataPath = getRequestedDataPath(obj)
            requestedDataPath = obj.requestedDataPath;
        end
        
        function dataSpecifier = getDataSpecifier(obj)
            dataSpecifier = obj.dataSpecifier;
        end
        
        function  setDataSpecifier(obj,dataSpecifier)
            obj.dataSpecifier = dataSpecifier;
        end
        
        function fncArgs = getFncArgs(obj)
            fncArgs = obj.fncArgs;
        end
        
        function setFncArgs(obj,args)
            obj.fncArgs = args;
        end
        
        function IDString = getIDString(obj)
            IDString = obj.IDString;
        end
        
        function reportDataSpecifier(obj)
            fprintf('%s:''%s'' (%s)\n',class(obj),obj.IDString,obj.direction);
            
            for iL = 1:numel(obj.hierarchyKeys)
                theHierarchyKey = obj.hierarchyKeys{iL};
                if obj.requestedDataPath.isKey(theHierarchyKey)
                    fprintf('\t%s:''%s''\n',theHierarchyKey,...
                        obj.requestedDataPath(theHierarchyKey));
                else
                    fprintf('\t%s:<NotDefined>\n',theHierarchyKey);
                end
            end
            fprintf('\tdataSpecifier:%s\n',obj.dataSpecifier);
            if ~isempty(obj.fncArgs)
                args = obj.fncArgs;
                if ~iscell(args)
                    args = {args};
                end
                fprintf('\tfncArgs:{');
                for iA = 1:numel(args)
                    fprintf(' ''%s''',args{iA});
                end
                fprintf(' }');
            end
            fprintf('\n');
        end
        
        function result =  matches(obj,animalKey,sessKey,stimKey,chKey)
           % Returns true if the dso matches all of the keys passed
           % Ignores empty sets (so, will match against designated
           % animalKey and stimKey regardless of the session designator if
           % sessKey = []
           % Note: keys can be cell arrays
           if isempty(animalKey)
               animalMatch = true;
           else
               if sum(strcmp(animalKey,getHierarchyLevel(obj,1)))
                   animalMatch = true;
               else
                   animalMatch = false;
               end
           end
           if isempty(sessKey)
               sessionMatch = true;
           else
               if sum(strcmp(sessKey,getHierarchyLevel(obj,2)))
                   sessionMatch = true;
               else
                   sessionMatch = false;
               end
           end
           if isempty(stimKey)
               stimMatch = true;
           else
               if sum(strcmp(stimKey,getHierarchyLevel(obj,3)))
                   stimMatch = true;
               else
                   stimMatch = false;
               end
           end
           if isempty(chKey)
               channelMatch = true;
           else
               if sum(strcmp(chKey,getHierarchyLevel(obj,4)))
                   channelMatch = true;
               else
                   channelMatch = false;
               end
           end
           result = animalMatch & sessionMatch & stimMatch & channelMatch;
        end
        
    end
    
end