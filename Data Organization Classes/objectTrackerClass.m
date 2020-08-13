classdef objectTrackerClass < handle
    
    % This class is used to track the existence of objects to make for easy
    % orphan deletions.  Used for diagnostic memory leak checks in the  
    % VEPAnalysisSuite.
    % 
    % For diagnostics, comment out the dummy functions and uncomment the
    % real functions.  For normal use, do the opposite.  
    %
    % The methods dynamically resize cell arrays which is quite slow when a
    % lot of objects are being tracked.  The dummy functions exist so that
    % the function calls can be left in all of the analysis suite class
    % definitions (in the constructors and destructors) without hurting
    % performance.
    %
    % JG
    
    properties
        objects % managed cell array that holds all of the objects being tracked
    end
    
    methods (Static)
        
        % Dummy Functions -----------------------------------------------
        function startTracking(varargin)
        end
        
        function stopTracking(varargin)
        end
        
        function returnAllObjects
        end
        
        function returnValidObjects
        end
        
        function deleteAllObjects
        end
        
        function deleteTracker
        end
        
        function returnObject
        end
        % Dummy End -----------------------------------------------------
        
%         % Real Functions ------------------------------------------------
%         function startTracking(varargin)
%             oto = objectTrackerClass.returnObject;
%             oto.objects(length(oto.objects)+(1:nargin)) = varargin;
%         end
%         
%         function stopTracking(obj)
%             oto = objectTrackerClass.returnObject;
%             nO = length(oto.objects);
%             keepIndici = true(1,nO);
%             for iO = 1:nO
%                 if obj == oto.objects{iO}
%                     keepIndici(iO) = false;
%                 end
%             end
%             oto.objects = oto.objects(keepIndici);
%         end
%         
%         function objects = returnAllObjects
%            oto = objectTrackerClass.returnObject;
%            objects = oto.objects;
%         end
%         
%         function objects = returnValidObjects
%             oto = objectTrackerClass.returnObject;
%             nO = length(oto.objects);
%             keepIndici = false(1,nO);
%             for iO = 1:nO
%                 if isa(oto.objects{iO},'handle') && isvalid(oto.objects{iO})
%                     keepIndici(iO) = true;
%                 end
%             end
%             objects = oto.objects(keepIndici);
%         end
%         
%         function deleteAllObjects
%             objs = objectTrackerClass.returnValidObjects;
%             nO = length(objs);
%             for iO = 1:nO
%                 if isvalid(objs{iO})
%                     delete(objs{iO});
%                 end
%             end
%             oto = objectTrackerClass.returnObject;
%             oto.objects = {};
%         end
%         
%         function deleteTracker
%             userData = get(0,'UserData');
%             if isa(userData,'containers.Map')
%                 if userData.isKey('objTracker')
%                     delete(userData('objTracker'));
%                     remove(userData,'objTracker');
%                 end
%             end
%         end
%         
%         function oto = returnObject
%             userData = get(0,'UserData');
%             if isa(userData,'containers.Map')
%                 if userData.isKey('objTracker')
%                     oto = userData('objTracker');
%                 end                
%             else
%                 userData = containers.Map;
%                 oto = objectTrackerClass;
%                 userData('objTracker') = oto;
%                 set(0,'UserData',userData);
%             end
%         end
%         % Real End ------------------------------------------------------
        
    end
    
    methods (Access=private)
        function obj = objectTrackerClass
            obj.objects = {};
        end
    end
    
end