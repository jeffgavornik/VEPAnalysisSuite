function stimDefs = readStimDefsFromMetaData(asciiStr)
% Reads stimulus definition values from an ascii string.  Assumes that the
% string has been formatted as ...ID:%s,EvntValue:%i,... to indicate
% event values
stimDefs = containers.Map;
iID = regexp(asciiStr,'ID:');
iComma = regexp(asciiStr,',');
iEV = regexp(asciiStr,'EvntValue:');
nID = length(iID);
nEV = length(iEV);
if nID ~= nEV
    return;
end
for ii = 1:nID
    iStart = iID(ii)+3;
    iStop = min(iComma(iComma>iStart))-1;
    ID = asciiStr(iStart:iStop);
    iStart = iEV(ii)+10;
    iStop = min(iComma(iComma>iStart))-1;
    EV = asciiStr(iStart:iStop);
    ID = sprintf('%02i:%s',str2double(EV),ID);
    % Make sure there are no duplicate stim definitions
    while stimDefs.isKey(ID)
        ID = sprintf('%s*',ID);
    end
    stimDefs(ID) = str2double(EV);
    % fprintf('%s=%i\n',ID,str2double(EV));
end