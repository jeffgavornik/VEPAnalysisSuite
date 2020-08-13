classdef LFPDataClass < voltageTraceDataClass
  
  properties
    tmdaResults % Trace Mag Distribution Analysis
    psdResults % Power Spectral Density results
  end
  
  methods
    
    function obj = LFPDataClass(varargin)
      obj = obj@voltageTraceDataClass(varargin{:});
    end
    
    function constructObject(obj,varargin)
      constructObject@voltageTraceDataClass(obj,varargin{:});
      % TMDA is only performed on request
      obj.tmdaResults = [];
    end
    
    function [negLat,posLat] = getScoreLatencies(obj)
      activeScore = obj.scoringRecords(obj.activeScoringKey);
      negLat = activeScore.negLatency;
      posLat = activeScore.posLatency;
    end
    
    function performOperation(obj,ctrlArg)
      switch ctrlArg
        case 'TMDA'
          obj.traceMagDistAnalysis();
        otherwise
          performOperation@voltageTraceDataClass(obj,ctrlArg);
      end
    end
    
    function traceMagDistAnalysis(obj,forceFlag)
            % Perform analysis if tmdaResults is empty, the analysisType
            % has changed or forceFlag is set
            if nargin < 2
                forceFlag = 0;
            end
            scrubOnComplete = false;
            analysisType = obj.patriarch.getTMDAType();
            if (isempty(obj.tmdaResults) || ...
                    ~strcmp(obj.tmdaResults('analysisType'),analysisType) ||...
                    forceFlag)
                if ~obj.rawDataExists
                    obj.regenerateRawData;
                    scrubOnComplete = true;
                end
                switch obj.getParent('channelDataClass').getID();
                    case 'piezzo'
                        obj.tmdaResults = piezzoTraceMagDistAnalysis(...
                            obj.traces(:,obj.validIndici),obj.tTr,...
                            getDataExtractParams(obj.patriarch));
                    otherwise
                        obj.tmdaResults = traceMagDistAnalysis(...
                            obj.traces(:,obj.validIndici),obj.tTr,...
                            analysisType,...
                            getDataExtractParams(obj.patriarch),...
                            getMeanScore(obj));
                end
            end
            if scrubOnComplete
                obj.clearRawData;
            end
        end
        
        function updateTMDAIfNeededForScoreChange(obj)
            % If the scoring has changed and ExactLatency TMDA type has
            % been used for the existing tmdaResults, rescore
            if ~isempty(obj.tmdaResults)
                if strcmp(obj.tmdaResults('analysisType'),'ExactLatency')
                    obj.traceMagDistAnalysis(true);
                end
            end
        end
        
        function tmdaResults = getTMDAResults(obj)
            if isempty(obj.tmdaResults)
                obj.traceMagDistAnalysis();
            end
            tmdaResults = obj.tmdaResults;
        end
        
        function psdResults = getPSDResults(obj)
            if isempty(obj.psdResults)
                obj.performPSDAnalysis();
            end
            psdResults = obj.psdResults;
        end
        
        function performPSDAnalysis(obj,forceFlag)
            % Perform analysis if psdResults is empty or forceFlag is set
            if nargin < 2
                forceFlag = 0;
            end
            scrubOnComplete = false;
            if (isempty(obj.psdResults) || forceFlag)
                if ~obj.rawDataExists
                    obj.regenerateRawData;
                    scrubOnComplete = true;
                end
                adFreq = 1/(obj.tTr(2)-obj.tTr(1));
                obj.psdResults = psdTracewiseAnalysis(...
                    obj.traces(:,obj.validIndici),adFreq);
            end
            if scrubOnComplete
                obj.clearRawData;
            end
        end
    
  end
  
end