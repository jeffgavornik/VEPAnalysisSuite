classdef genericDataRecordClass < handle
    % Generic class definition that works like a template for the data
    % analysis suite.  Maintains heirarchal relationships, data return
    % behavior, and various overhead
    %
    % JG
    
    properties
        patriarch % object at the top of the hierarchy
        parent % object directly above in the hierarchy
        ID % a string describing the object
        kids % dictionary of objects
    end
    
    properties (Transient=true)
        listeners
        timers
    end
    
    methods
        
        function obj = genericDataRecordClass
            obj.parent = [];
            obj.ID = '';
            objectTrackerClass.startTracking(obj);
        end
        
        % Default delete clears any existing timers
        function delete(obj)
            % fprintf('Delete %s ID=''%s''\n',class(obj),obj.ID);
            delete(obj.timers);
            objectTrackerClass.stopTracking(obj);
        end
        
        % Delete the object after telling all kids to delete
        function deleteWithKids(obj)
            if isa(obj.kids,'containers.Map')
                kidKeys = obj.kids.keys;
                for iK = 1:numel(kidKeys)
                    theKid = obj.kids(kidKeys{iK});
                    % fprintf('sending delete cmd to %s (class %s)\n',theKid.ID,class(theKid));
                    deleteWithKids(theKid);
                end
            end
            delete(obj);
        end
        
        % Create empty cell array to hold any listeners and provide methods
        % to add listener handles to it
        function setupListenerCallbacks(obj)
            obj.listeners = {};
        end
        
        function saveListener(obj,lh)
            obj.listeners{end+1} = lh;
        end
        
        % Create an empty cell array that can hold timers and provide
        % method to add timer handles to it
        function setupTimers(obj)
            obj.timers = [];
        end
        
        function obj.saveTimer(obj,th)
            obj.timers(end+1) = th;
        end
        
        % Get and set the object ID
        function ID = getID(obj)
            ID = obj.ID;
        end
        
        function setID(obj,ID)
            obj.ID = ID;
        end
        
        % Get and set the parents
        function setPatriarch(obj,patriarch)
            obj.patriarch = patriarch;
        end
        
        function setParent(obj,parent)
            obj.parent = parent;
        end
        
        function hObj = getParent(obj,targetClass)
            % If the obj is a member of the targetClass, return the object.
            % Otherwise pass the request to the parent
            if nargin == 2
                if isa(obj,targetClass)
                    hObj = obj;
                else
                    hObj = getParent(obj.parent,targetClass);
                end
            else
                hObj = obj.parent.getParent;
            end
        end
        
        % Get and set the kids
        function setKids(obj,hDict)
            % select the dictionary that holds objects below the current
            % record on the heirarchy - just a pointer used by the
            % returnData method
           obj.kids = hDict; 
        end
        
        function kidKeys = getKidKeys(obj)
            % Return the keys for all kids
            kidKeys = obj.kids.keys;
        end
        
        % Process data requests passing up and down the hierarchy
        function varargout = returnData(obj,dso)
            % Query the object for a specific type of data - if it is not a
            % part of the object, pass the request to the appropriate kid.
            % If there are no kids or an error return null.  If direction
            % is set to up, requests are passed to the parent rather than
            % the kids.  If the data is not found or the specified kid does
            % not exist, return empty data.
            
            try
                % Get the pathKey from the dso; if it exists and the
                % direction is down, pass the request to the specified
                % kid. If the direction is up and it exists, ignore the 
                % value and pass the request to the parent. In both cases 
                % if the getKeyPath return value is empty that means the
                % calling object is at the the target hierarchy level and
                % should process the data request within itself
                pathKey = dso.getPathKey(obj);
                %fprintf('%s : nargout = %i pathkey=%s (isEmpty=%i)\n',...
                %    class(obj),nargout,pathKey,isempty(pathKey));
                %[varargout{1:nargout}] = []; % default empty return
                varargout = cell(1,nargout);
                if ~isempty(pathKey) % pass along request
                    switch dso.direction
                        case 'down'
                            if obj.kids.isKey(pathKey)
                                nextObject = obj.kids(pathKey);
                            else
                                return;
                                % [varargout{1:nargout}] = [];
                            end
                        case 'up'
                            nextObject = obj.parent;
                    end
                    [varargout{1:nargout}] = returnData(nextObject,dso);
                        
                else % process the request
                    dataSpecifier = getDataSpecifier(dso);
                    % Check to see if the dso specifies a property
                    objProps = properties(obj);
                    iProp = strcmp(dataSpecifier,objProps);
                    if sum(iProp)
                        %fprintf('%s is a property\n',dataSpecifier);
                        %getStr = sprintf('obj.%s',objProps{iProp});
                        %theData = eval(getStr);
                        varargout = {obj.(objProps{iProp})};
                    else % Check to see if the dso specifies a method
                        objMethods = methods(obj);
                        iMeth = strcmp(dataSpecifier,objMethods);
                        if sum(iMeth)
                            % Call method using function (rather than dot)
                            % convention (i.e. fnc(obj) rather than obj.fnc())
                            %fprintf('%s is a method\n',dataSpecifier);
                            fncStr = sprintf('@(varargin)%s(varargin{:})',...
                                objMethods{iMeth});
                            hFnc = str2func(fncStr);
                            args =getFncArgs(dso);
                            if isempty(args) % call method with no arguments
                                [varargout{1:nargout}] = hFnc(obj);
                            else
                                if ~iscell(args)
                                    args = {args};
                                end
                                [varargout{1:nargout}] = hFnc(obj,args{:});
                            end
                        end
                    end
                end
            catch ME
                % This method should fail if the specifierKey describes
                % neither a property nor method (varargout will not be set)
                fprintf('returnData failed at %s:''%s''\nReport:\n%s',...
                    class(obj),obj.ID,getReport(ME));
                [varargout{1:nargout}] = cell(1,nargout);
            end
        end
        
        function reportContent(obj,offset,fid)
            if nargin <2
                offset = '';
            end
            if nargin < 3
                fid = 1;
            end
            fprintf(fid,'%s%s: ID = ''%s''',offset,class(obj),obj.ID);
        end
        
        function exportContentToCSV(obj,fid,offset)
            % Default behavior is to write the name and pass the command to
            % all of the kids
            % If an offset is passed, increase it by one space before
            % passing command
            if nargin == 2
                offset = '';                
            end
            for ii = 1:length(offset)
                fprintf(fid,',');
            end
            fprintf(fid,'%s:ID,%s\n',class(obj),obj.ID);
            if isa(obj.kids,'containers.Map')
                kidKeys = obj.kids.keys;
                for iK = 1:numel(kidKeys)
                    theKid = obj.kids(kidKeys{iK});
                    if nargin == 2
                        exportContentToCSV(theKid,fid);
                    else
                        exportContentToCSV(theKid,fid,[offset ' ']);
                    end
                end
            end
        end
        
        % Function called after load is complete and all objects in the
        % hiearchy exist to setup listeners and timers
        function setupAfterLoad(obj)
            % fprintf('%s.setupAfterLoad (%s)\n',class(obj),obj.ID);
            obj.setupListenerCallbacks;
            obj.setupTimers;
            if isa(obj.kids,'containers.Map')
                kidKeys = obj.kids.keys;
                for iK = 1:numel(kidKeys)
                    ko = obj.kids(kidKeys{iK});
                    setupAfterLoad(ko);
                end
            end
        end
        
        % Default behavior is to consider the object empty if it has no
        % dependent objects
        function emptyFlag = isEmpty(obj)
            if obj.kids.length == 0
                emptyFlag = true;
            else
                emptyFlag = false;
            end
        end
        
        % Remove any children objects that report themselves as being empty
        function removeEmptyKids(obj)
            kidKeys = obj.kids.keys;
            for iK = 1:numel(kidKeys)
                theKidKey = kidKeys{iK};
                theKid = obj.kids(theKidKey);
                if theKid.isEmpty
                    deleteKid(obj,theKidKey);
                    %delete(theKid)
                    %obj.kids.remove(theKidKey);
                end
            end
        end
        
        % Delete a specific child of the object - called by returnData when
        % using the deleteKid template specifier
        function varargout = deleteKid(obj,kidKey)
            if obj.kids.isKey(kidKey)
                theKid = obj.kids(kidKey);
                remove(obj.kids,kidKey);
                deleteWithKids(theKid);
            end
            notify(obj.patriarch,'UpdateViewers');
            notify(obj.patriarch,'DataAddedOrRemoved');
            [varargout{1:nargout}] = cell(1,nargout);
        end
        
        function theObject = returnTheObject(obj)
            theObject = obj;
        end
        
    end
    
end