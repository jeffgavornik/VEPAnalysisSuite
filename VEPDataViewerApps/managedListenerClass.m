classdef managedListenerClass < handle
    % Superclass that insures all listeners die with the class
    %
    % Use newListener and removeListener to create/delete listeners
    % When object is deleted, all listeners created via newListener are
    % automatically deleted
    
    properties (Hidden=true,Access=protected)
        listenerDict;
    end
    
    methods
        
        function obj = managedListenerClass(varargin)
            obj.listenerDict = containers.Map;
        end
        
        function delete(obj)
            keys = obj.listenerDict.keys;
            for key = keys
                obj.removeListener(key{:});
            end
        end
        
        function [el,key] = newListener(obj,varargin)
            % Arguments are the same as addlistener
            % If the first argument of varargin is not a handle class
            % object, uses obj as the hSource
            % i.e. myObj.newListener('EventName',...) will listen for
            %         'EventName' posted by myObj
            %      myObj.newListener(myObj,'EventName',...) will also work
            % key is the string used to index into the listener hash table
            el = [];
            try
                firstArg = varargin{1};
                if ~isa(firstArg,'handle')
                    varargin = [{obj} varargin];
                end
                el = addlistener(varargin{:});
                key = el.EventName;
                if obj.listenerDict.isKey(key)
                    key = [key '_'];
                end
                obj.listenerDict(key) = el;
            catch ME
                handleError(ME,true,'addlistener failure');
            end
        end
        
        function listenerRemoved = removeListener(obj,key)
            listenerRemoved = 0;
            if obj.listenerDict.isKey(key)
                delete(obj.listenerDict(key));
                obj.listenerDict.remove(key);
                listenerRemoved = 1;
            end
        end
        
        function listenerArray = getListeners(obj)
            listenerArray = obj.listenerDict.values;
        end
        
    end
    
end