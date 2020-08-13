function [eventValues,asciiString,eventInd,nRemoved] = readASCIIFromEventCodes(eventValues,delimVec)
% This function takes in a vector of event codes and looks for
% code-deliminated meta-data.  The default code is based on the definition
% used in ttlHardwareAbstractClass, but this can be overridden.  The
% function assumes that the metadata will have the delim code before and
% after the ascii sequence.  If the delim vector is not found, returns. If
% the delim vector occurs more or less than 2 times, the function throws an
% error

if nargin < 2 || isempty(delimVec)
    delimVec = [51   153   102   204   255];
end
eventInd = 1:length(eventValues);
asciiString = '';
iDelim = strfind(eventValues,delimVec);
nDelim = length(iDelim);
if nDelim == 0
    return;
end
if nDelim ~= 2
    error('readASCIIFromEventCodes assumes the delimiter will only occur twice, actually occurred %i times',nDelim);
end
asciiString = char(eventValues(iDelim(1)+length(delimVec):iDelim(2)-1));
eventInd = iDelim(2)+length(delimVec):length(eventValues);
eventValues = eventValues(eventInd);
nRemoved = iDelim(2)+length(delimVec)-iDelim(1);