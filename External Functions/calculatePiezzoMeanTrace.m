function meanTrace = calculatePiezzoMeanTrace(traces,t)
% This function is called by voltageTraceDataClass.calculateMeanTrace

% [rows,cols] = size(traces);
% meanTrace = zeros(rows,1);
% for iC = 1:cols
%     theTrace = traces(:,iC);
%     meanTrace = meanTrace + theTrace - mean(theTrace);
% end
% meanTrace = meanTrace / cols;
% %mt = mean(obj.traces,2); % ignore validity
% %mt = mt - mean(mt);
% meanTrace = meanTrace.^2;
% 
% % Normalize so that the AUC of the pre-stimulus period is equal to 1
% normRange = t < 0;
% dt = t(2)-t(1);
% normFactor = dt*sum(meanTrace(normRange));
% meanTrace = meanTrace/normFactor;
% % meanTrace = 100*meanTrace./max(meanTrace);

fprintf('piezzo mean trace calc: %f\n', min(t));

[rows,cols] = size(traces);
normRange = t < 0;
dt = t(2)-t(1);
meanTrace = zeros(rows,1);
for iC = 1:cols
    theTrace = abs(traces(:,iC));
    normFactor = dt*sum(theTrace(normRange));
    theTrace = theTrace/normFactor;
    meanTrace = meanTrace + theTrace; %- mean(theTrace);
end
meanTrace = meanTrace / cols;
%mt = mean(obj.traces,2); % ignore validity
%mt = mt - mean(mt);
%meanTrace = meanTrace.^2;

% Normalize so that the AUC of the pre-stimulus period is equal to 1


