function channelKey = getKeyForChannelNumber(channel,autoName)
% Determine what data was being recorded based on the Plexon recording
% rigs' standard configurations
%
% PlxRecOne: 16,18
% PlxRecTwo: 0,2
% Omniplex: 80,82

if nargin == 1 || isempty(autoName)
    autoName = true;
end

if autoName
    switch channel
        case {0,16,80}
            channelKey = 'LH';
            return
        case {2,18,82}
            channelKey = 'RH';
            return
        case {6,7,22,23}
            channelKey = 'piezzo';
            return
    end
end
channelKey = num2str(channel);