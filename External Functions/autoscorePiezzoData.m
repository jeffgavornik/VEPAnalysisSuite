function scores = autoscorePiezzoData(v,t,~)

% This is not well thought out yet - currently calculates the integral of v
% using dt calculated from t
% Need to modify for individual trace scoring ?

% Create a strcture to hold the score results
nTraces = size(v,2);

% if nTraces > 1
%     error('autoscorePiezzoData: does not work for individual traces')
% end

scores = struct;
scores.vMag = zeros(1,nTraces);
scores.vNeg = zeros(1,nTraces);
scores.iNeg = zeros(1,nTraces);
scores.vPos = zeros(1,nTraces);
scores.iPos = zeros(1,nTraces);
scores.negLatency = zeros(1,nTraces);
scores.posLatency = zeros(1,nTraces);

dt = t(2) - t(1);

iZero = find(t==0);

responseRange = t>=0;

for iT = 1:nTraces
    scores.vMag(iT) = sum(abs(v(responseRange))) * dt;
    scores.vNeg(iT) = 0;
    scores.iNeg(iT) = iZero;
    scores.vPos(iT) = 0;
    scores.iPos(iT) = iZero;
    scores.negLatency(iT) = 0;
    scores.posLatency(iT) = 0;
end
