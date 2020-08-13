classdef VEPLatencyGroupClass < groupDataRecordClass
    
    properties
    end
    
    methods
        
        function obj = VEPLatencyGroupClass(varargin)
            % Pass arguments to the superclass constructor
            obj = obj@groupDataRecordClass(varargin{:});
            % Create a template that defines the path to the Score
            % Latencies
            obj.useDataSpecifierTemplate(...
                getDataSpecifierTemplate('ScoreLatencies'));
        end
        
        function [negLats posLats] = getGroupData(obj,varargin)
            
            specifierKeys = obj.getSpecifierKeys;
            nKeys = numel(specifierKeys);
            negLats = zeros(1,nKeys);
            posLats = zeros(1,nKeys);
            for iK = 1:nKeys
                try
                    theKey = specifierKeys{iK};
                    [negLats(iK) posLats(iK)] = ...
                        obj.parent.getData(obj.dataSpecifiers(theKey));
                catch ME
                    fprintf('Group ''%s'' getData failure for %s\n',...
                        obj.ID,theKey);
                    fprintf('Failure Report:\n%s',getReport(ME));
                end
            end
            
            
            % If the argument 'AverageByAnimal' is passed as an argument,
            % average the values by animal
            if nargin > 1 && checkArgsForValue('AverageByAnimal',varargin{:})
                animalIDs = obj.getGroupAnimalIDs(true);
                nA = length(animalIDs);
                avgNeg = zeros(1,nA);
                avgPos = zeros(1,nA);
                for iA = 1:nA
                    theID = animalIDs{iA};
                    negValue = 0;
                    posValue = 0;
                    count = 0;
                    for iK = 1:nKeys
                        theKey = specifierKeys{iK};
                        if strfind(theKey,theID) == 1
                            negValue = negValue + negLats(iK);
                            posValue = posValue + posLats(iK);
                            count = count + 1;
                        end
                    end
                    if count == 0
                        % if an animal key was not found for some reason
                        avgNeg(iA) = NAN;
                        avgPos(iA) = NAN;
                    else
                        avgNeg(iA)= negValue / count;
                        avgPos(iA)= posValue / count;
                    end
                end
                negLats = avgNeg;
                posLats = avgPos;
            end
            
        end
        
    end
    
end