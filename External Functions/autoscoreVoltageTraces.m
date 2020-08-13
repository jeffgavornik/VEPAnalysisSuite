function scores = autoscoreVoltageTraces(v,t,scoringParams)

% Can either pass a structure with min and max latency designations
% (original method) or a 2 element array indicating minimum and maximum t
% values

if isstruct(scoringParams)
    % Original scoring algorithm based on specific designations of min and
    % max value locations
    % Extract scoring parameters
    minRange = scoringParams.negativeLatencyRange;
    maxPosLat = scoringParams.maxPositiveLatency;
    
    % Calculate the indici based on the range
    range = t < maxPosLat;
    neg_range = t > minRange(1) & t < minRange(2);
    neg_offset = find(neg_range == true,1,'first') - 1;
    
    % Create a strcture to hold the score results
    nTraces = size(v,2);
    scores = struct;
    scores.vMag = zeros(1,nTraces);
    scores.vNeg = zeros(1,nTraces);
    scores.iNeg = zeros(1,nTraces);
    scores.vPos = zeros(1,nTraces);
    scores.iPos = zeros(1,nTraces);
    scores.negLatency = zeros(1,nTraces);
    scores.posLatency = zeros(1,nTraces);
    
    % Iterate over all voltage traces scoring each individually
    for iT = 1:nTraces
        [vMin,iMin] = min(v(neg_range));
        iMin = iMin + neg_offset;
        pos_range = range & t > t(iMin);
        [vMax,iMax] = max(v(pos_range));
        iMax = iMax + iMin;
        scores.vMag(iT) = vMax - vMin;
        scores.vNeg(iT) = vMin;
        scores.iNeg(iT) = iMin;
        scores.vPos(iT) = vMax;
        scores.iPos(iT) = iMax;
        scores.negLatency(iT) = t(iMin);
        scores.posLatency(iT) = t(iMax);
    end
    
else
    
    scores = struct;
    [rows,cols] = size(v);
    
    % Find the max value in the scoring range
    scoringRange = scoringParams;
    indici = t >= scoringRange(1) & t <= scoringRange(2);
    nCols = sum(indici);
    offset = find(indici,1,'first')-1;
    indMat = repmat(indici,rows,1);
    [pos,iPos] = max(reshape(v(indMat),rows,nCols),[],2);
    iPos = iPos + offset;
    % Find minimum values in the range occuring before the max value
    iNeg = zeros(size(iPos));
    neg = zeros(size(pos));
    for row = 1:rows
        [neg(row),iNeg(row)] = min(v(row,indici & t <= t(iPos(row))));
        iNeg(row) = iNeg(row) + offset;
    end
    
    %     % Find the max value in the scoring range
    %     scoringRange = scoringParams;
    %     indici = t >= scoringRange(1) & t <= scoringRange(2);
    %     offset = find(indici,1,'first')-1;
    %     iPos = zeros(1,rows);
    %     pos = zeros(1,rows);
    %     iNeg = zeros(size(iPos));
    %     neg = zeros(size(pos));
    %     for row = 1:rows
    %         [pos(row),iPos(row)] = max(v(row,indici));
    %         iPos(row) = iPos(row) + offset;
    %         [neg(row),iNeg(row)] = min(v(row,indici & t <= t(iPos(row))));
    %         iNeg(row) = iNeg(row) + offset;
    %     end
    
    scores.vMag = pos - neg;
    scores.vNeg = neg;
    scores.iNeg = iNeg;
    scores.vPos = pos;
    scores.iPos = iPos;
    t = repmat(t,1,cols);
    scores.negLatency = t(iNeg);
    scores.posLatency = t(iPos);
    
    
    
end
