function tmdaResults = piezzoTraceMagDistAnalysis(traces,tTr,scoringParams)

% smooth traces and use the autoscore function
nTraces = size(traces,2);
for iT = 1:nTraces
    traces(:,iT) = gauss_smooth(traces(:,iT),...
        scoringParams.smoothWidth,3);
end
scores = autoscorePiezzoData(traces,tTr);

% Estimate the distribution and statistics
tmdaResults = containers.Map;
[tmdaResults('ecdf_f') tmdaResults('ecdf_x')] = ecdf(scores.vMag);
[tmdaResults('epdf_f') tmdaResults('epdf_x')] = ksdensity(scores.vMag);
tmdaResults('meanKey') = mean(scores.vMag);
tmdaResults('stdKey') = std(scores.vMag);
tmdaResults('kKey') = kurtosis(scores.vMag);
tmdaResults('skewKey') = skewness(scores.vMag);
tmdaResults('analysisType') = analysisType;


