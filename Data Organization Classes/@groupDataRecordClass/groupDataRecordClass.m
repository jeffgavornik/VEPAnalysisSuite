classdef groupDataRecordClass < handle
    
    % groupDataRecordClass holds information necessary to extract data from
    % a group of data records held by a single VEPDataClass object
    % The group object maintains a dataSpecifierObject for each group 
    % member that is passed to the VDO to extract the data
    %
    % JG
    
    properties
        parent
        ID
        listeners
        dataSpecifiers % Holds dataSpecifierObjects for each group member
        dataSpecifierTemplate
        fh % handle of the GUI interface
        % Provide support for data normalization
        normalizeData
        normType
        normFactors
        normDescStr
        fh_n % normalization GUI figure
        exportDataFnc % function handle to export - set based on Mac or PC
    end
    
    events
        ObjectClosing
        ContentsChanged
        NormTypeChanged
    end
    
    methods (Static)
        function normTypes = getSupportedNormTypes
            % Return a cell array that contains the valid normalization
            % types for the group
            normTypes = {...
                'None' ...
                'Scalar' ...
                'Element-wise'
                };
        end
    end
    
    methods
        
        function obj = groupDataRecordClass(VEPDataObject,IDStr)
            obj.parent = VEPDataObject;
            obj.ID = IDStr;
            obj.dataSpecifiers = containers.Map;
            obj.dataSpecifierTemplate = [];
            obj.normalizeData = false;
            obj.normType = 'None';
            obj.normFactors = containers.Map;
            obj.normFactors('dataSrc') = 'Not Set';
            obj.normFactors('NormGrpKey') = '';
            obj.normDescStr = 'NA';
            obj.fh = [];
            obj.fh_n = [];
            objectTrackerClass.startTracking(obj);
        end
        
        function delete(obj)
            % fprintf('%s deleting\n',class(obj));
            objectTrackerClass.stopTracking(obj);
        end
        
        function reportContent(obj,fid)
            if nargin == 1
                fid = 1;
            end
            offset = '';
            fprintf(fid,'%s%s: ID = ''%s''\n',offset,class(obj),obj.ID);
            specifierKeys = obj.dataSpecifiers.keys;
            for iK = 1:length(specifierKeys)
                theKey = specifierKeys{iK};
                theID = obj.dataSpecifiers(theKey).getIDString;
                fprintf(fid,'\t%s\n',theID);
            end
        end
        
        function useDataSpecifierTemplate(obj,dataSpecifierObject)
            obj.dataSpecifierTemplate = dataSpecifierObject;
        end
        
        function varargout = getGroupData(obj,varargin)
            % Return the group data
            % varargout{1} = rawData
            % varargout{2} = normData
            % varargout{3} = dataKeys
            nOut = nargout;
            varargout = cell(1,nOut);
            specifierKeys = obj.getSpecifierKeys;
            nKeys = numel(specifierKeys);
            rawData = cell(1,nKeys);
            dataKeys = cell(1,nKeys);
            if nOut > 1
                normFlag = true;
                normData = cell(1,nKeys);
                obj.updateNormalizationValues;
            else
                normFlag = false;
                normData = {};
            end
            for iK = 1:nKeys
                try
                    theKey = specifierKeys{iK};
                    dataKeys{iK} = theKey;
                    rawData{iK} = ...
                        obj.parent.getData(obj.dataSpecifiers(theKey));
                    if obj.normalizeData && normFlag
                       normData{iK} = rawData{iK}./...
                           obj.getNormFactorForKey(theKey); 
                    end
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
                averagedData = cell(1,nA);
                if normFlag
                    averagedNormData = cell(1,nA);
                end
                for iA = 1:nA
                    theID = animalIDs{iA};
                    rawValue = 0;
                    if normFlag
                        normValue = 0;
                    end
                    count = 0;
                    for iK = 1:nKeys
                        theKey = dataKeys{iK};
                        if strfind(theKey,theID) == 1
                            rawValue = rawValue + rawData{iK};
                            if normFlag
                                normValue = normValue + normData{iK};
                            end
                            count = count + 1;
                        end
                    end
                    if count == 0
                        % if an animal key was not found for some reason
                        averagedData{iA} = nan;
                        if normFlag
                            averagedNormData{iA} = nan;
                        end
                    else
                        averagedData{iA} = rawValue / count;
                        if normFlag
                            averagedNormData{iA} = normValue / count;
                        end
                    end
                end
                rawData = averagedData;
                if normFlag
                    normData = averagedNormData;
                end
                dataKeys = animalIDs;
            end
            
            % Return the data
            varargout{1} = rawData;
            %if normFlag
                varargout{2} = normData;
            %end
            if nOut > 2
                varargout{3} = dataKeys;
            end
        end
        
        % Return the raw data for a single specified key
        function data = getDataForKey(obj,specifierKey)
            try
                data = ...
                    obj.parent.getData(obj.dataSpecifiers(specifierKey));
                return
            catch ME
                error('%s.getDataForKey(%s) failed\n%s',...
                    class(obj),specifierKey,getReport(ME));
            end
            data = NAN;
        end
        
        function outputCSVFormatToFile(obj,fid)
            % Write group contents to fid in CSV format
            if nargin == 1
                fid = 1;
            end
            if obj.normalizeData
                [data,normData,keys] = obj.getGroupData;
            else
                [data,~,keys] = obj.getGroupData;
            end
            nD = length(data);
            if nD ~= length(keys)
                error('%s.outputToFile: sizes do not match');
            end
            fprintf(fid,'%s\n',obj.ID);
            % Output Data Keys
            fprintf(fid,'Data Keys,');
            for iD = 1:nD
                fprintf(fid,'%s',keys{iD});
                if iD == nD
                    fprintf(fid,'\n');
                else
                    fprintf(fid,',');
                end
            end
            % Output Data
            fprintf(fid,'Raw Data,');
            for iD = 1:nD
                fprintf(fid,'%f',data(iD));
                if iD == nD
                    fprintf(fid,'\n');
                else
                    fprintf(fid,',');
                end
            end
            % Output Normalized Data
            if exist('normData','var')
                fprintf(fid,'Norm Data,');
                for iD = 1:nD
                    fprintf(fid,'%f',normData(iD));
                    if iD == nD
                        fprintf(fid,'\n');
                    else
                        fprintf(fid,',');
                    end
                end
            end
        end
        
        function animalIDs = getGroupAnimalIDs(obj,removeDuplicates)
            % Return the IDs of all animals included in the group
            % If removeDuplicates is set, returns only unique IDs (i.e. if
            % an animal has multiple data in the group,as from multiple
            % recording sites, will return the ID only once)
            if nargin == 1
                removeDuplicates = false;
            end
            specifierKeys = obj.getSpecifierKeys;
            nS = length(specifierKeys);
            animalIDs = cell(1,nS);
            for iS = 1:nS
                parts = regexp(specifierKeys{iS},'_','split');
                animalIDs{iS} = parts{1};
            end
            if removeDuplicates
                animalIDs = unique(animalIDs);
            end 
        end
        
        function varargout = getDataForAnimalKey(obj,animalKey)
            % Return only the group data matching against the animalKey
            % This function is useful when building a stats table
            nOut = nargout;
            varargout = cell(1,nOut);
            specifierKeys = obj.getSpecifierKeys;
            nKeys = numel(specifierKeys);
            rawData = cell(1,nKeys);
            dataKeys = cell(1,nKeys);
            if nOut > 1
                normFlag = true;
                normData = cell(1,nKeys);
                obj.updateNormalizationValues;
            else
                normFlag = false;
            end
            count = 0;
            for iK = 1:nKeys
                try
                    % Check to see if the specifier matches the requested
                    % animal and, if so, save the data for return
                    theKey = specifierKeys{iK};
                    parts = regexp(theKey,'_','split');
                    animalID = parts{1};
                    if strcmpi(animalKey,animalID)
                        count = count + 1;
                        dataKeys{count} = theKey;
                        rawData{count} = ...
                            obj.parent.getData(obj.dataSpecifiers(theKey));
                        if obj.normalizeData && normFlag
                            normData{count} = rawData{count}./...
                                obj.getNormFactorForKey(theKey);
                        end
                    end
                catch ME
                    fprintf('Group ''%s'' getData failure for %s\n',...
                        obj.ID,theKey);
                    fprintf('Failure Report:\n%s',getReport(ME));
                end
            end
            varargout{1} = cell2mat(rawData);
            if normFlag
                varargout{2} = cell2mat(normData);
            end
            if nOut > 2
                varargout{3} = dataKeys;
            end
        end
        
        function copyExistingGroup(obj,hGrpRecDataObj,varargin)
            % copy all elements of an existing group
            specifierKeys = hGrpRecDataObj.getSpecifierKeys;
            for iK = 1:numel(specifierKeys)
                obj.addDataSpecifier(...
                    hGrpRecDataObj.getDataSpecifier(specifierKeys{iK}),...
                    varargin);
            end
            [obj.normalizeData,obj.normType,obj.normFactors, ...
                obj.normDescStr] = hGrpRecDataObj.getNormParams;
        end
        
        function addDataSpecifier(obj,dataSpecifierObject,varargin)
            % If a DSO teplate is defined, make a copy and fill in the
            % blanks from the passed DSO.  Otherwise, just use the DSO
            % If 'OrphanGroup' is passed as an input, will not notify the
            % VDO of updates - this is used by the group data viewers which
            % make temporary copies of existing groups
            if isempty(obj.dataSpecifierTemplate)
                obj.dataSpecifiers(dataSpecifierObject.getIDString) = ...
                    dataSpecifierObject;
            else
                % Duplicate the template object
                templateCopy = obj.dataSpecifierTemplate.copy;
                % Find the empty values in the template that need to be
                % filled
                iBlank = strcmp('',...
                    obj.dataSpecifierTemplate.requestedDataPath.values);
                % Get the keys for the blanks
                dataPathKeys = ...
                    obj.dataSpecifierTemplate.requestedDataPath.keys;
                templateKeys = dataPathKeys(iBlank);
                % Fill the blanks from the passed DSO
                for iK = 1:numel(templateKeys)
                    theKey = templateKeys{iK};
                    templateCopy.requestedDataPath(theKey) = ...
                        dataSpecifierObject.requestedDataPath(theKey);
                end
                % Generate the new ID string and add to the group
                templateCopy.makeIDString;
                obj.dataSpecifiers(templateCopy.getIDString) = ...
                    templateCopy;
            end
            obj.updateGUI();            
            if nargin > 2 && checkArgsForValue('OrphanGroup',varargin{:})
                return
            end
            notify(obj.parent,'DataAddedOrRemoved');
            notify(obj.parent,'UpdateViewers');
            notify(obj.parent,'GrpMgmtRefreshGUINeeded')
        end
        
        function manageGroup(obj)
            obj.openGUI();
        end
        
        function removeFromGroup(obj,specifierKey)
            % delete(obj.dataSpecifiers(specifierKey));
            obj.dataSpecifiers.remove(specifierKey);
            obj.updateGUI();
            notify(obj.parent,'DataAddedOrRemoved');
            notify(obj.parent,'UpdateViewers');
            notify(obj.parent,'GrpMgmtRefreshGUINeeded');
        end
        
        function removeSpecifiersWithElements(obj,...
                animalKey,sessionKey,stimKey,channelKey)
           keys = obj.getSpecifierKeys;
           for iK = 1:length(keys)
               theKey = keys{iK};
               dso = obj.dataSpecifiers(theKey);
               if dso.matches(animalKey,sessionKey,stimKey,channelKey)
                   obj.removeFromGroup(theKey);
               end
           end
        end
        
        function specifierKeys = getSpecifierKeys(obj)
            specifierKeys = obj.dataSpecifiers.keys;
        end
        
        function dataSpecifier = getDataSpecifier(obj,specifierKey)
            dataSpecifier = obj.dataSpecifiers(specifierKey);
        end
        
        function [normalizeData,normType,normFactors,normDescStr] = ...
                getNormParams(obj)
            normalizeData = obj.normalizeData;
            normType = obj.normType;
            normFactors = obj.normFactors;
            normDescStr = obj.normDescStr;
        end
        
        function setAllSpecifiers(obj,hierarchyLevel,key)
            specifierKeys = obj.dataSpecifiers.keys;
            for iK = 1:numel(specifierKeys)
                try
                    oldKey = specifierKeys{iK};
                    theSpecifier = obj.dataSpecifiers(oldKey);
                    theSpecifier.setHierarchyLevel(hierarchyLevel,key);
                    theSpecifier.makeIDString;
                    obj.dataSpecifiers.remove(oldKey);
                    obj.dataSpecifiers(theSpecifier.getIDString) = ...
                        theSpecifier;
                catch ME
                    fprintf('%s.setAllSpecifiers: failed for %s\n',...
                        class(obj),oldKey);
                    fprintf('Report: %s\n',getReport(ME));
                end
            end
            obj.updateGUI();
            notify(obj.parent,'DataAddedOrRemoved');
        end
        
        function dataSpecifierKeys = getDataDescriptions(obj)
            dataSpecifierKeys = obj.dataSpecifiers.keys;
        end
        
        % Export data methods ---------------------------------------------
        
        function exportDataToFile(obj,outputFileName)
            % Generic export function for a groups that store a single
            % variable (eg vep magnitude) - subclasses that include more
            % than one variable should replace this method
            
            
            % Open the file
            fid = fopen(outputFileName,'Wb');
            
            fprintf(fid,'%s,ID,%s\n',class(obj),obj.ID);
            grpData = obj.getGroupData;
            [cols,rows] = size(grpData);
            % Write data
            dataKeys = obj.getDataDescriptions;
            for iR = 1:rows
                for iC = 1:cols
                    fprintf(fid,'%s,%f',dataKeys{iR},grpData(iC,iR));
                    %if obj.normalizeData
                    %    fprintf(fid,',%f',rawData(iC,iR));
                    %end
                end
                fprintf(fid,'\n');
            end
            
            fclose(fid);
        end
        
        function exportDataToWorkspace(obj)
            try
                % Save group data in the base workspace
                [grpData,normData,grpKeys] = obj.getGroupData;
                outVar.rawData = grpData;
                outVar.keys = grpKeys;
                if obj.normalizeData
                    outVar.normData = normData;
                end
                varName = sprintf('grp_%s',genvarname(obj.ID));
                fprintf('Sending group ''%s'' data to variable ''%s'' in base workspace\n',...
                    obj.ID,varName);
                assignin('base',varName,outVar);
            catch ME
                fprintf('%s.exportDataToWorkspace: failed for %s\n',...
                    class(obj),obj.ID);
                fprintf('Report: %s\n',getReport(ME));
            end
        end
        
        % Data normalization methods --------------------------------------
        
        function updateNormalizationValues(obj) %#ok<MANU>
            % This function populates the normFactor dictionary based on
            % selected normalization parameters and the current content
            % of other groups - called at data return time to make sure
            % results reflect current VDO state
%             fprintf('%s.updateNormalizationValues TBD',class(obj));
            return;
            
% try
% 
%             dataSrc = obj.normFactors('dataSrc');
%             if strcmp(dataSrc,'Manual')
%                 return % no need to update manual designations
%             end
%             grpKey = obj.normFactors('NormGrpKey');
%             normGrp = obj.parent.groupRecords(grpKey);
% 
%            switch obj.normType
%                case 'Scalar'
%                    if obj.normFactors('AverageByAnimals')
%                        normValue = normGrp.returnGroupMean('AverageByAnimal');
%                    else
%                        normValue = normGrp.returnGroupMean();
%                    end
%                    obj.normFactors('scalar') = normValue;
%                case 'Element-wise'
%                    
%                    tableData = get(handles.normTable,'Data');
%                    for iC = 1:size(tableData,1)
%                        memberKey = tableData{iC,1};
%                        normValue = tableData{iC,2};
%                        if ~isempty(normValue)
%                            obj.normFactors(memberKey) = normValue;
%                        end
%                    end
%                    
%                    switch dataSrc
%                        case 'Group'
%                            if isappdata(handles.figure1,'normGrpKey')
%                                obj.normDescStr = sprintf('%s:''%s''',dataSrc,...
%                                    getappdata(handles.figure1,'normGrpKey'));
%                            else
%                                obj.normDescStr = 'Group:N/A';
%                            end
%                        case 'Manual'
%                            obj.normDescStr = sprintf('%s\nConfiguration',dataSrc);
%                    end
%                    
%            end
%            
% catch ME
%     errStr = sprintf('updateNormalizationValues failed\n%s',getReport(ME));
%     warndlg(errStr);
% end

        end
        
        function normFactor = getNormFactorForKey(obj,key)
            % Key is a group element - all keys return the same value if
            % the normType is 'Scalar' or 'None' (return 1).  If
            % elementwise, each key is associated with an individual value
            % and an error will be displayed for all ophaned keys
            switch obj.normType
                case 'None'
                    normFactor = 1;
                    return
                case 'Scalar'
                    key = 'scalar';
                    if obj.normFactors.isKey(key)
                        normFactor = obj.normFactors(key);
                    else
                        errStr = sprintf(...
                            '%s.getNormFactorForKey (%s) unknown key %s\n',...
                            class(obj),obj.ID,key);
                        warndlg({errStr 'Normalization Incorrect'});
                        %fprintf(2,...
                        %    'Warning: %s.getNormFactorForKey (%s) unknown key %s\n',...
                        %    class(obj),obj.ID,key);
                        normFactor = 1;
                    end
                case 'Element-wise'
                    try
                        % Make sure the key is in the normFactors
                        % dictionary
                        if obj.normFactors.isKey(key)
                            factorKey = obj.normFactors(key);
                        else
                            error('%s.getNormFactorForKey (%s) unknown key %s\n',...
                                class(obj),obj.ID,key);
                        end
                        % Get the Group
                        normGrpKey = obj.normFactors('NormGrpKey');
                        if obj.parent.groupRecords.isKey(normGrpKey)
                            normGrp = obj.parent.groupRecords(normGrpKey);
                        else
                            error('%s.getNormFactorForKey (%s) unknown group %s\n',...
                                class(obj),obj.ID,normGrpKey);
                        end
                        % Get the requested data from the group
                        normFactor = normGrp.getDataForKey(factorKey);
                    catch ME
                        errStr = ...
                            sprintf('Error in Element-wise normalization\n%s',...
                            ME.message);
                        warndlg(errStr);
                        normFactor = 1;
                    end
                    
            end
            
        end
        
        function descStr = getNormDescription(obj)
            descStr = obj.normDescStr;
        end
        
        function normType = getNormType(obj)
            normType = obj.normType;
        end
        
        function setNormType(obj,type)
            obj.normType = type;
            obj.normFactors = containers.Map;
            if strcmp(type,'None')
                obj.normalizeData = false;
                obj.normDescStr = 'NA';
            else
                obj.normDescStr = 'Unconfigured';
                obj.normalizeData = true;
                obj.normFactors('dataSrc') = 'Not Set';
            end
            obj.norm_closeGUI();
        end
        
        function normalizeByGroupMean(obj,normGrp,varargin)
            % Setup for scalar normalization using the mean value from a
            % selected group
            try
                normValue = normGrp.returnGroupMean();
            catch ME
                fprintf(2,'%s.normalizeByGroupMean failed for %s\nReport:%s',...
                    class(normGrp),normGrp.ID,ME.getReport);
                obj.setNormType('None');
                return
            end
            obj.normType = 'Scalar';
            obj.normalizeData = true;
            obj.normFactors('dataSrc') = normGrp.ID;
            obj.normFactors('scalar') = normValue;
            if nargin > 2 && ...
                    checkArgsForValue('AverageByAnimal',varargin{:})
                obj.normFactors('AverageByAnimals') = true;
            else
                obj.normFactors('AverageByAnimals') = false;
            end
            obj.normDescStr = ...
                sprintf('''%s'' Group Mean\nValue = %1.2f',...
                normGrp.ID,normValue);
        end
        
        % THIS STILL NEEDS WORK BOTH FOR ELEMENTWISE AND MANUAL SCALAR
        function refreshNormFactors(obj)
            if obj.normalizeData
                switch obj.normType
                    case 'Scalar'
                        if obj.normFactors.isKey('dataSrc')
                            grpName = obj.normFactors('dataSrc');
                            theGroup = obj.parent.getGroupObject(grpName);
                            obj.normalizeByGroupMean(theGroup);
                        end
                    otherwise
                        fprintf('%s.refreshNormFactors: can not refresh for ID %s\n',...
                            class(obj),obj.ID);
                end
            end
        end
        
    end
    
end
