function template = getDataSpecifierTemplate(type,args)
% Defines dataSpecifierClass objects with a template for accessing specific
% types of data from the VEPDataClass hiearchy
%
% See groupDataRecordClass.m to see an example of how to instantiate a
% template to retrieve data for a specific record

switch lower(type)
    case 'vepmag'
        % Must supply animal, session, stim and channel
        pathKeys = {'' '' '' ''};
        dataSpecifier = 'getMeanScoreData';
        args = 'vMag';
    case 'vepnegmag'
        % Must supply animal, session, stim and channel
        pathKeys = {'' '' '' ''};
        dataSpecifier = 'getMeanScoreData';
        args = 'vNeg';
    case 'vepscore'
        % Must supply animal, session, stim and channel
        pathKeys = {'' '' '' ''};
        dataSpecifier = 'getMeanScoreData';
    case 'veptrace'
        % Must supply animal, session, stim and channel
        pathKeys = {'' '' '' ''};
        dataSpecifier = 'getMeanTrace';
    case 'kidkeys'
        pathKeys = {''};
        dataSpecifier = 'getKidKeys';
    case 'tmda'
        % Must supply animal, session, stim and channel
        pathKeys = {'' '' '' ''};
        dataSpecifier = 'getTMDA';
    case 'psd'
        % Must supply animal, session, stim and channel
        pathKeys = {'' '' '' ''};
        dataSpecifier = 'getPSD';
    case 'channelkeys'
        pathKeys = {'' '' ''};
        dataSpecifier = 'getChannelKeys';
    case 'deletekid' % deletes data, doesn't return data
        pathKeys = {'' '' '' ''};
        dataSpecifier = 'deleteKid';
        args = ''; % must be specified before dispatch'
    case 'validtraces'
        % Must supply animal, session, stim and channel
        pathKeys = {'' '' '' ''};
        dataSpecifier = 'getTraces';
    case 'alltraces'
        % Must supply animal, session, stim and channel
        pathKeys = {'' '' '' ''};
        dataSpecifier = 'getTraces';
        args = true;
    case 'scorelatencies'
        pathKeys = {'' '' '' ''};
        dataSpecifier = 'getScoreLatencies';
    otherwise
        fprintf('getDataSpecifierTemplate: unknown type %s\n',type);
        template = [];
        return
end

if exist('args','var')
    template = dataSpecifierClass(pathKeys,dataSpecifier,args);
else
    template = dataSpecifierClass(pathKeys,dataSpecifier);
end