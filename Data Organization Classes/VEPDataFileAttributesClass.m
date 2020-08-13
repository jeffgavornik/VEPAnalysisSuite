classdef VEPDataFileAttributesClass < handle
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
    viewingEye
    otherAttributes
  end
  
  methods
    
    function obj = VEPDataFileAttributesClass(filename,filepath,...
        animalID,sessionName)
      try
        [pathParts,ind] = regexp(filename,'/','split');
        obj.fileName = pathParts{end};
        if nargin < 2
          if ~isempty(ind)
            obj.path = filename(1:ind(end));
          else
            obj.path = [];
          end
        else
          obj.path = filepath;
        end
        obj.fileNameWithPath = [obj.path obj.fileName];
        if ~isempty(regexp(filename,'.plx','once'))
          % Handle case of .plx file
          % Assumes animalID_sessionName_ViewingEye_...
          obj.fileType = 'plx'; % only type for now
          if nargin > 2 % User specified animal, session, viewing eye
            % Should be error checking code here (is char, all
            % specified, etc.)
            obj.animalID = animalID;
            obj.sessionName = sessionName;
          else % Auto-specify
            % Split filename based on underscore
            parts = regexp(regexprep(filename,'.plx',''),'_','split');
            nParts = numel(parts);
            % minimium of 4 parts for valid naming convention - if does not
            % match, query user for attributes
            if nParts < 2
              try
                [obj.animalID,obj.sessionName,obj.viewingEye] = ...
                  getFileAttributesFromUser(obj);
              catch ME
                fprintf('VEPDataFileAttributesClass.assignError:\n%s\n',...
                  getReport(ME));
              end
            else
              % Interpret the parts and assign
              obj.animalID = parts{1};
              obj.sessionName = parts{2};
              % obj.viewingEye = parts{3};
              % if nParts > 5
              if nParts > 4
                obj.otherAttributes = parts(4:end-2);
              end
            end
          end
        elseif ~isempty(regexp(filename,'.mat','once'))
          % Handle case of Spike2 .mat file
          obj.fileType = 'spike2mat';
          dataStrct = load(fullfile(filepath,filename));
          channels = fieldnames(dataStrct);
          aChannel = channels{1};
          parts = regexp(aChannel,'_','split');
          obj.animalID = parts{1};
          obj.sessionName = parts{2};
        else
          error('VEPDataFileAttributesClass:Uknown File Type');
        end
      catch ME
        handleError(ME,'VEPDataFileAttributesClass');
      end
    end
    
%     function obj = VEPDataFileAttributesClass(filename,filepath,...
%         animalID,sessionName)
%       try
%         [pathParts,ind] = regexp(filename,'/','split');
%         obj.fileName = pathParts{end};
%         if nargin < 2
%           if ~isempty(ind)
%             obj.path = filename(1:ind(end));
%           else
%             obj.path = [];
%           end
%         else
%           obj.path = filepath;
%         end
%         obj.fileNameWithPath = [obj.path obj.fileName];
%         if ~isempty(regexp(filename,'.plx','once'))
%           % Handle case of .plx file
%           % Assumes animalID_sessionName_ViewingEye_...
%           obj.fileType = 'plx'; % only type for now
%           if nargin > 2 % User specified animal, session, viewing eye
%             % Should be error checking code here (is char, all
%             % specified, etc.)
%             obj.animalID = animalID;
%             obj.sessionName = sessionName;
%           else % Auto-specify
%             % Split filename based on underscore
%             parts = regexp(regexprep(filename,'.plx',''),'_','split');
%             nParts = numel(parts);
%             % minimium of 4 parts for valid naming convention - if does not
%             % match, query user for attributes
%             if nParts < 2
%               try
%                 [obj.animalID,obj.sessionName,obj.viewingEye] = ...
%                   getFileAttributesFromUser(obj);
%               catch ME
%                 fprintf('VEPDataFileAttributesClass.assignError:\n%s\n',...
%                   getReport(ME));
%               end
%             else
%               % Interpret the parts and assign
%               obj.animalID = parts{1};
%               obj.sessionName = parts{2};
%               % obj.viewingEye = parts{3};
%               % if nParts > 5
%               if nParts > 4
%                 obj.otherAttributes = parts(4:end-2);
%               end
%             end
%           end
%         elseif ~isempty(regexp(filename,'.mat','once'))
%           % Handle case of Spike2 .mat file
%           obj.fileType = 'spike2mat';
%           dataStrct = load(fullfile(filepath,filename));
%           channels = fieldnames(dataStrct);
%           aChannel = channels{1};
%           parts = regexp(aChannel,'_','split');
%           obj.animalID = parts{1};
%           obj.sessionName = parts{2};
%         else
%           error('VEPDataFileAttributesClass:Uknown File Type');
%         end
%       catch ME
%         handleError(ME,'VEPDataFileAttributesClass');
%       end
%     end
    
  end
  
end


