function norm_doneButton_Callback(obj)

% Write the app data back to the object and close the GUI
obj.normDescStr = getappdata(obj.fh_n,'normDescStr');
obj.normFactors = getappdata(obj.fh_n,'normFactors');
obj.norm_closeGUI();
notify(obj.parent,'GrpMgmtRefreshGUINeeded');
