function closeGUI(obj,fhName)
% Generic method to cleanly close any figure spawned by the VEPDataObject
% fprintf('VEPDataClass.closeGUI %s\n',fhName);
if ~isempty(obj.(fhName))
    handles = guidata(obj.(fhName));
    delete(handles.closeListener);
    delete(handles.updateListener);
    delete(handles.figure1);
    obj.(fhName) = [];
end