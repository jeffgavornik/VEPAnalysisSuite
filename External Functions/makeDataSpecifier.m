function template = makeDataSpecifier(type,pathKeys,args)
% Defines dataSpecifierClass objects with a template for accessing specific
% types of data from the VEPDataClass hiearchy
%
% See groupDataRecordClass.m to see an example of how to instantiate a
% template to retrieve data for a specific record

if isa(pathKeys,'char')
    pathKeys = regexp(pathKeys,'_','split');
end

if ~exist('pathKeys','var') || isempty(pathKeys)
    pathKeys = {'' '' '' ''};
end

switch lower(type)
    case 'vepmag'
        % Must supply animal, session, stim and channel
        dataSpecifier = 'getMeanScoreData';
        args = 'vMag';
    case 'vepscore'
        % Must supply animal, session, stim and channel
        dataSpecifier = 'getMeanScoreData';
    case 'veptrace'
        % Must supply animal, session, stim and channel
        dataSpecifier = 'getMeanTrace';
    case 'kidkeys'
        dataSpecifier = 'getKidKeys';
    case 'tmda'
        dataSpecifier = 'getTMDA';
    case 'psd'
        dataSpecifier = 'getPSD';
    case 'channelkeys'
        dataSpecifier = 'getChannelKeys';
    case 'deletekid' % deletes data, doesn't return data
        dataSpecifier = 'deleteKid';
    case 'validtraces'
        dataSpecifier = 'getTraces';
    case 'alltraces'
        dataSpecifier = 'getTraces';
        args = true;
    case 'scorelatencies'
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