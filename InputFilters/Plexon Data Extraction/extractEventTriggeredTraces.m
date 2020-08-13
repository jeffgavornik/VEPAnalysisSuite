function  extractEventTriggeredTraces

% Function to extract voltages for a fixed period of time arount events
% 
% [traces,tTr] = extractEventTriggeredTraces(evTs,...
%              ad,adTs,window);
%
%   traces are the extracted voltages
%   tTr is time index into the traces
%
%   evTs are timestamps of all events
%   ad is vector of LFP voltages
%   adTs are timestamps into ad
%   window defines the amount of data to extract, in ms.  If scalar,
%   extracts window ms starting at each timestamp.  If [pre post] also
%   extracts pre ms before each event stamp