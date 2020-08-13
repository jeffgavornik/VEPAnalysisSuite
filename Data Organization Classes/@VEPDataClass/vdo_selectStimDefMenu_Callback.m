function vdo_selectStimDefMenu_Callback(obj,~)
% Select a stimulus definition function file and use it to assign stimulus
% definitions

if isappdata(obj.fh,'CurrentStimDirectory')
        startDirectory = getappdata(obj.fh,'CurrentStimDirectory');
    else
        startDirectory = pwd;
end
    
[filename path] = uigetfile('*_sdf.m','Select Stimulus Function File',...
    'MultiSelect', 'off',startDirectory);

if filename ~= 0
    
    currPath = pwd;
    if ~strcmp(currPath,path)
        cd(path)
    end
    
    try
        
        ind = regexp(filename,'.m');
        if ~isempty(ind)
            file = filename(1:ind(end)-1);
        end
        hstimDefFnc = str2func(file);
        stimDefs = hstimDefFnc();
        if ~isempty(stimDefs)
            obj.stimDefStr = sprintf('%s()',file);
            obj.stimDefs = stimDefs;
            obj.vdo_updateGUI_Callback;
        end
        
    catch ME
        warnStr = sprintf(...
            'vdo_selectStimDefMenu_Callback Failed for %s:\nReport\n%s',...
            file,getReport(ME));
        warndlg(warnStr);
    end
    
    if ~strcmp(currPath,path)
        cd(currPath)
    end
    
    setappdata(obj.fh,'CurrentStimDirectory',path);
end

end