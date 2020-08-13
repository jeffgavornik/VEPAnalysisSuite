classdef VEPMagGroupClass < groupDataRecordClass
    
    properties
    end
    
    methods
        
        function obj = VEPMagGroupClass(VEPDataObject,IDStr,specifier)
            if nargin < 3
                specifier = 'VEPMag';
            end
            % Pass arguments to the superclass constructor
            obj = obj@groupDataRecordClass(VEPDataObject,IDStr);
            % Create a template that defines the path to the VEP magnitude
            obj.useDataSpecifierTemplate(...
                getDataSpecifierTemplate(specifier));
        end
        
        function varargout = getGroupData(obj,varargin)
            % convert cell array to matrix
            [varargout{1:nargout}] = ...
                getGroupData@groupDataRecordClass(obj,varargin);
            varargout{1} = cell2mat(varargout{1}); % Raw Data
            if nargout > 1
                varargout{2} = cell2mat(varargout{2}); % Normalized Data
            end
        end
        
        function meanValue = returnGroupMean(obj,varargin)           
           % meanValue = mean(obj.getGroupData('AverageByAnimal'));
           meanValue = mean(obj.getGroupData(varargin)); 
        end
        
    end
    
end