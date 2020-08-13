function [stimDict filename pathname] = getStimsFromTxtFile(startDirectory)

if nargin == 0
    startDirectory = pwd;
end

stimDict = [];

[filename pathname] = uigetfile('*.txt','Select a Stimulus definition text file',...
    'MultiSelect', 'off',startDirectory);
if isequal(filename,0) || isequal(pathname,0) % user select cancel
    return;
end

try
    fid = fopen(fullfile(pathname,filename));
    txtValues = textscan(fid,'%s','Delimiter','\n');
    txtValues = txtValues{:};
    fclose(fid);
    nStims = numel(txtValues);
    dictionary = containers.Map;
    for iS = 1:nStims
        txtStr = txtValues{iS};
        parts = regexp(txtStr,'=','split');
        stimKey = parts{1};
        nVals = numel(parts) - 1;
        if nVals > 1
            stimVals = zeros(1,nVals);
            for iN = 1:nVals
                stimVals(iN) = str2double(parts{iN+1});
            end
        else
            stimVals = str2num(parts{2}); %#ok<*ST2NM>
        end
        dictionary(stimKey) = stimVals;
        disp([stimKey ': ' num2str(stimVals)])
    end
    stimDict = dictionary;
    
catch ME
    warnstr = sprintf(...
        'getStimsFromTxtFile Failed for %s:\nReport\n%s',...
        filename,getReport(ME));
    warndlg(warnstr);
    
end