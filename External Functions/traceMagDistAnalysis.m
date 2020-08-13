function tmdaResults = traceMagDistAnalysis(traces,tTr,analysisType,...
    scoringParams,meanScoreResults)

switch analysisType
    case 'Tracewise'
        % smooth traces and use the autoscore function
        nTraces = size(traces,2);
        for iT = 1:nTraces
            traces(:,iT) = gauss_smooth(traces(:,iT),...
                scoringParams.smoothWidth,3);
        end
        scores = autoscoreVoltageTraces(traces,tTr,scoringParams);
    case 'ExactLatency'
        % Read the latency values from the mean score
        iMin = meanScoreResults.iNeg;
        iMax = meanScoreResults.iPos;
        % Create a structure to hold the score results
        nTraces = size(traces,2);
        scores = struct;
        scores.vMag = zeros(1,nTraces);
        scores.vNeg = zeros(1,nTraces);
        scores.iNeg = zeros(1,nTraces);
        scores.vPos = zeros(1,nTraces);
        scores.iPos = zeros(1,nTraces);
        scores.negLatency = zeros(1,nTraces);
        scores.posLatency = zeros(1,nTraces);
        % Iterate over events
        for iT = 1:nTraces
            theTrace = gauss_smooth(traces(:,iT),...
                scoringParams.smoothWidth);
            vMin = theTrace(iMin);
            vMax = theTrace(iMax);
            scores.vMag(iT) = vMax - vMin;
            scores.vNeg(iT) = vMin;
            scores.iNeg(iT) = iMin;
            scores.vPos(iT) = vMax;
            scores.iPos(iT) = iMax;
            scores.negLatency(iT) = tTr(iMin);
            scores.posLatency(iT) = tTr(iMax);
        end
end

% Estimate the distribution and statistics
tmdaResults = containers.Map;
[tmdaResults('ecdf_f') tmdaResults('ecdf_x')] = ecdf(scores.vMag);
[tmdaResults('epdf_f') tmdaResults('epdf_x')] = ksdensity(scores.vMag);
tmdaResults('meanKey') = mean(scores.vMag);
tmdaResults('stdKey') = std(scores.vMag);
tmdaResults('kKey') = kurtosis(scores.vMag);
tmdaResults('skewKey') = skewness(scores.vMag);
tmdaResults('analysisType') = analysisType;


