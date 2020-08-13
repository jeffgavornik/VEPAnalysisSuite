function [ev,evTs] = getOpenEphysEvnts(evntFile)
% Convert open ephys binary representation to decimal event codes

[events,eventTimes,~] = ...
    load_open_ephys_data_faster(evntFile);
% Byron's janky algorithm
diffs = [5;diff(eventTimes)];
inds = find(~(diffs<=0.005));
% 
nInd = length(inds);
evTs = zeros(1,nInd);
ev = zeros(1,nInd);
for ii=1:length(inds)
    evTs(ii) = eventTimes(inds(ii));
    if ii==nInd
        currentEvents = inds(ii):length(eventTimes);
        currentEvents = unique(events(currentEvents));
    else
        currentEvents = inds(ii):inds(ii+1)-1;
        currentEvents = unique(events(currentEvents));
    end
    binrep = zeros(1,7);
    if sum(currentEvents)==0
    
    else
        binrep(currentEvents) = 1;
    end
    ev(ii) = bi2de(binrep);
end