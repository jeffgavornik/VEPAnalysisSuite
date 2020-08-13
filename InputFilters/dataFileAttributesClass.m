classdef dataFileAttributesClass < handle
    % Holds recording sessions attributes about a data file
    % Parses the filename
    % Works with either .plx or Spike2.mat files
    
    properties
        fileName
        path
        fileNameWithPath
        fileType
        animalID
        sessionName
        otherAttributes
    end
    
    methods
        
        function obj = dataFileAttributesClass(filename,filepath,...
                formatStr,animalID,sessionName)
            try
                obj.fileName = filename;
                obj.path = filepath;
                obj.fileNameWithPath = fullfile(obj.path,obj.fileName);
                % Figure out ID and session
                askUser = false;
                if ~isempty(formatStr)
                  obj.readInfoFromFileNameFormat(formatStr);
                end
                if nargin > 3 && ~isempty(animalID)
                    obj.animalID = animalID;
                end
                if nargin > 4 && ~isempty(sessionName)
                    obj.sessionName = sessionName;
                end
                if isempty(obj.animalID) || isempty(obj.sessionName)
                    askUser = true;
                end
                if ~askUser
                    return
                else
                  [animalID,sessionName] = getFileAttributesFromUser(obj);
                end
                obj.animalID = animalID;
                obj.sessionName = sessionName;
            catch ME
              handleError(ME,true,'dataFileAttributesClass');
            end
        end
        
        function success = readInfoFromFileNameFormat(obj,formatStr)
          % Check to make sure the format string is valid, i.e. contains
          % FORMAT:, ID and SESSION
          success = false;
          try %#ok<TRYNC>
            FORMATLoc = regexp(formatStr,'FORMAT');
            IDLoc = regexp(formatStr,'ID','Once');
            SESSIONLoc = regexp(formatStr,'SESSION','Once');
            if isempty(FORMATLoc) || FORMATLoc~=1 || isempty(IDLoc) || isempty(SESSIONLoc)
              disp('dataFileAttributesClass.readInforFromFileFormat: invalid format string');
              return;
            end
            delimChar = formatStr(FORMATLoc+length('FORMAT'));
            formParts = regexp(formatStr,delimChar,'split');
            IDInd = find(strcmp(formParts,'ID'))-1;
            SESSIONInd = find(strcmp(formParts,'SESSION'))-1;
            parts = regexp(obj.fileName,delimChar,'split');
            nParts = numel(parts);
            if nParts < 2
              return;
            end
            obj.animalID = cell2mat(parts(IDInd));
            obj.sessionName = cell2mat(parts(SESSIONInd));
            EXTRAInd = true(1,nParts);
            EXTRAInd(IDInd) = false;
            EXTRAInd(SESSIONInd) = false;
            EXTRA = parts(EXTRAInd);
            str = '';
            for ii = 1:length(EXTRA)-1
              str = sprintf('%s%s_',str,EXTRA{ii});
            end
            obj.otherAttributes = sprintf('%s%s',str,EXTRA{end});
          end          
          success = true;
        end
    end
end


