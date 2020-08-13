function [ev,evTs] = plotEventValues(plxFiles)

if isstruct(plxFiles) % pass output of dir()
    nFiles = size(plxFiles,1);
    tmp = cell(1,nFiles);
    for iF = 1:nFiles
        tmp{iF} = plxFiles(iF).name;
    end
    plxFiles = tmp;
end
    
if ~iscell(plxFiles)
    plxFiles = {plxFiles};
end

for iF = 1:length(plxFiles)
    try
        [~, ~, ~, ev, evTs, ~, ~, ~, ~] = ...
            extractPLXad(plxFiles{iF});
        figure
        plot(evTs,ev);
        title(regexprep(plxFiles{iF},'_','\\_'));
    catch ME
        fprintf('extract failed for %s\n:s',plxFiles{iF},getReport(ME));
    end
    
end