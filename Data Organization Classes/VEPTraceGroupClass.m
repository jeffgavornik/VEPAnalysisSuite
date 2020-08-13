classdef VEPTraceGroupClass < groupDataRecordClass
    
    methods
        
        function obj = VEPTraceGroupClass(varargin)
            % Pass arguments to the superclass constructor
            obj = obj@groupDataRecordClass(varargin{:});
            % Create a template that defines the path to the VEP magnitude
            obj.useDataSpecifierTemplate(...
                getDataSpecifierTemplate('VEPTrace'));
        end
        
        function [grpTraces,tTr,dataKeys] = getGroupData(obj,varargin)
            try
                % Get the data for each key
                specifierKeys = obj.getSpecifierKeys;
                nKeys = numel(specifierKeys);
                grpTraces = cell(1,nKeys);
                tTr = cell(1,nKeys);
                dataKeys = cell(1,nKeys);
                for iK = 1:nKeys
                    try
                        theKey = specifierKeys{iK};
                        [grpTraces{iK},tTr{iK}] = ...
                            obj.parent.getData(obj.dataSpecifiers(theKey));
                        dataKeys{iK} = theKey;
                    catch ME
                        errStr = sprintf('Group ''%s'' getData failure for %s\n%s',...
                            obj.ID,theKey,getReport(ME));
                        warndlg(errStr);
                    end
                end
                tTr = tTr{1};
                nTr = length(tTr);
                % Average responses by animal if requested
                if nargin > 1 && ...
                        checkArgsForValue('AverageByAnimal',varargin{:})
                    animalIDs = obj.getGroupAnimalIDs(true);
                    nA = length(animalIDs);
                    averagedTraces = cell(1,nA);
                    for iA = 1:nA
                        theID = animalIDs{iA};
                        summedTrace = zeros(nTr,1);
                        count = 0;
                        for iK = 1:nKeys
                            theKey = dataKeys{iK};
                            if min(strfind(theKey,theID)) == 1
                                loc = strfind(theKey,theID);
                                fprintf('%s %s %i\n',theKey,theID,loc);
                                summedTrace = summedTrace + grpTraces{iK};
                                count = count + 1;
                            end
                        end
                        if count == 0
                            % if an animal key was not found for some reason
                            averagedTraces{iA} = nan*ones(1,nTr);
                        else
                            averagedTraces{iA} = summedTrace / count;
                        end
                    end
                    grpTraces = averagedTraces;
                    dataKeys = animalIDs;
                end
            catch ME
                errStr = sprintf(...
                    'VEPTraceGroupClass.getGroupData failed:\n%s',...
                    getReport(ME));
                warndlg(errStr);
                grpTraces = {};
                tTr = {};
                dataKeys = {};
                return;
            end
            
            try
                % return as a matrix if all cell elements have the same 
                % number of elements
                % consoildate tTr - TBD
                grpTraces = cell2mat(grpTraces)';
            catch ME %#ok<NASGU>
                errStr = fprintf('VEPTraceGroupClass: number of elements differs across traces. Returning cell arrays\n');
                warndlg(errStr);
            end
        end
        
        function [meanTrace,tTr,dataKeys] = getMeanTrace(obj,varargin)
            [grpTraces,tTr,dataKeys] = getGroupData(obj,varargin);
            try
                meanTrace = mean(grpTraces,1);
            catch ME
                handleError(ME,true,sprintf('TraceReturnFailure:%s',obj.ID));
            end
        end
            
        function exportDataFnc(obj,outputFileName)
            
            [grpTraces,tTr] = obj.getGroupData;
            dataKeys = obj.getDataDescriptions;
            [cols,rows] = size(grpTraces);
            if numel(tTr) ~= rows
                error('%s.exportData: data sizes do not match');
            end
            
            % Open the file
            fid = fopen(outputFileName,'Wb');
                        
            % Write column headers
            fprintf(fid,'t');
            for iC = 1:cols
                fprintf(fid,',%s',dataKeys{iC}); % should be an identifier
            end
            fprintf(fid,'\n');
            
            % Write data
            for iR = 1:rows
                fprintf(fid,'%f',tTr(iR));
                for iC = 1:cols
                    fprintf(fid,',%f',grpTraces(iC,iR));
                end
                fprintf(fid,'\n');
            end
            
            fclose(fid);
            
        end
        
        function exportDataToWorkspace(obj)
            try
                % Save group data in the base workspace
                [grpTraces,tTr] = obj.getGroupData;
                varNameBase = matlab.lang.makeValidName(obj.ID);
                varName1 = sprintf('grp_%s_traces',varNameBase);
                varName2 = sprintf('grp_%s_t',varNameBase);
                fprintf('Sending group ''%s'' data to variables ''%s'' and ''%s'' in base workspace\n',...
                    obj.ID,varName1,varName2);
                assignin('base',varName1,grpTraces);
                assignin('base',varName2,tTr);
            catch ME
                fprintf('%s.exportDataToWorkspace: failed for %s\n',...
                    class(obj),obj.ID);
                fprintf('Report: %s\n',getReport(ME));
            end
        end
        
    end
    
end