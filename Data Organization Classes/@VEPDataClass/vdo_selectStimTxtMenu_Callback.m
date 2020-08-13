function vdo_selectStimTxtMenu_Callback(obj,~)

if isappdata(obj.fh,'CurrentStimDirectory')
    startDirectory = getappdata(obj.fh,'CurrentStimDirectory');
else
    startDirectory = pwd;
end

[stimsDict filename pathname] = getStimsFromTxtFile(startDirectory);
if isempty(stimsDict)
    return;
end
setappdata(obj.fh,'CurrentStimDirectory',pathname);
obj.stimDefStr = filename;
obj.stimDefs = stimsDict;
obj.vdo_updateGUI_Callback;

end