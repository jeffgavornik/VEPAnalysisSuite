function grpMgmt_closeGUI(obj)
if ~isempty(obj.fh_grpMgmt)
    handles = guidata(obj.fh_grpMgmt);
    delete(handles.figure1);
    obj.fh_grpMgmt = [];
    obj.closeGUI('fh_memSel');
end
