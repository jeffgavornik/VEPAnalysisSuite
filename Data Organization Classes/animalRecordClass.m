classdef animalRecordClass < genericDataRecordClass
  
  properties
    sessionRecords
  end
  
  methods
    
    function obj = animalRecordClass(varargin)
      if nargin > 0
        obj.constructObj(varargin{:});
      end
    end
    
    function constructObj(obj,vdo,animalKey)
      obj.setParent(vdo);
      obj.setPatriarch(vdo);
      obj.setID(animalKey);
      obj.sessionRecords = containers.Map;
      obj.setKids(obj.sessionRecords);
    end
    
    function hObj = getParent(obj,targetClass)
      if nargin == 2
        if isa(obj,targetClass)
          hObj = obj;
        else
          hObj = obj.parent.getParent(targetClass);
        end
      else
        hObj = obj.parent;
      end
    end
    
    function reportContent(obj,offset,fid)
      if nargin <2
        offset = '';
      end
      if nargin < 3
        fid = 1;
      end
      fprintf(fid,'%sanimalRecordClass, ID = ''%s''\n',offset,obj.ID);
      condKeys = obj.sessionRecords.keys;
      for iCond = 1:numel(condKeys)
        theObj = obj.sessionRecords(condKeys{iCond});
        theObj.reportContent([offset char(9)],fid);
      end
    end
    
    function theRecord = newSessionRecord(obj,sessionKey)
      if obj.sessionRecords.isKey(sessionKey)
        error('animalRecordClass.createNewSession: sessionKey %s already exists',sessionKey);
      else
        % fprintf('animalRecordClass.createNewSession: ID ''%s'' sessionKey ''%s''\n',obj.ID,sessionKey);
        theRecord = sessionRecordClass(obj,obj.parent,sessionKey);
        obj.sessionRecords(sessionKey) = theRecord;
      end
    end
    
    function addData(obj,varargin)
      dataFileObj = varargin{1};
      vepDataFileAttObj = dataFileObj.attributes;
      %  vepDataFileAttObj = varargin{1};
      sessionKey = vepDataFileAttObj.sessionName;
      if obj.sessionRecords.isKey(sessionKey)
        theSessionRecord = obj.sessionRecords(sessionKey);
      else
        theSessionRecord = obj.newSessionRecord(sessionKey);
      end
      theSessionRecord.addData(varargin{:});
    end
    
  end
  
end