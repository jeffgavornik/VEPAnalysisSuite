function vdo_selectPRGratingStimsMenu_Callback(obj,~)

stimsDict = PRGratingStims_sdf;
if ~isempty(stimsDict)
    obj.stimDefStr = 'PRGratingStims()';
    obj.stimDefs = stimsDict;
    obj.vdo_updateGUI_Callback;
end

end