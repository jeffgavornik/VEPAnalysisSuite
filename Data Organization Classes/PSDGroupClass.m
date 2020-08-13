classdef PSDGroupClass < groupDataRecordClass
    
    methods
        
        function obj = PSDGroupClass(varargin)
            % Pass arguments to the superclass constructor
            obj = obj@groupDataRecordClass(varargin{:});
            % Create a template that defines the path to the PSD data
            obj.useDataSpecifierTemplate(...
                getDataSpecifierTemplate('PSD'));
        end
        
        function [muPxx freqs Pxx] = getGroupData(obj,varargin)
            specifierKeys = obj.getSpecifierKeys;
            nKeys = numel(specifierKeys);
            muPxx = cell(1,nKeys);
            Pxx = cell(1,nKeys);
            freqs = cell(1,nKeys);
            for iK = 1:nKeys
                try
                    theKey = specifierKeys{iK};
                    PSDResults = ...
                        obj.parent.getData(obj.dataSpecifiers(theKey));
                    Pxx{iK} = PSDResults('Pxx');
                    muPxx{iK} = PSDResults('muPxx');
                    freqs{iK} = PSDResults('freqs');
                    % muPxx{iK} = PSDResults('S');
                    % freqs{iK} = PSDResults('f');
                catch ME
                    fprintf('Group ''%s'' getData failure for %s\n',...
                        obj.ID,theKey);
                    fprintf('Failure Report:\n%s',getReport(ME));
                end
            end
            
            try
                % return as a matrix if all cell elements have the same 
                % number of elements
                % consoildate tTr - TBD
                Pxx = cell2mat(Pxx)';
                muPxx = cell2mat(muPxx)';

            catch ME %#ok<NASGU>
                fprintf('VEPTraceGroupClass: number of elements differs');
                fprintf(' across traces. Returning cell arrays\n');
            end
        end
            
        function exportDataToFile(obj,outputFileName)
            
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
                [Pxx,freqs] = obj.getGroupData;
                varNameBase = genvarname(obj.ID);
                varName1 = sprintf('grp_%s_Pxx',varNameBase);
                varName2 = sprintf('grp_%s_freqs',varNameBase);
                fprintf('Sending group ''%s'' data to variables ''%s'' and ''%s'' in base workspace\n',...
                    obj.ID,varName1,varName2);
                assignin('base',varName1,Pxx);
                assignin('base',varName2,freqs);
            catch ME
                fprintf('%s.exportDataToWorkspace: failed for %s\n',...
                    class(obj),obj.ID);
                fprintf('Report: %s\n',getReport(ME));
            end
        end
        
    end
    
end