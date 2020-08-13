function norm_closeGUI(obj)

if ~isempty(obj.fh_n)
    handles = guidata(obj.fh_n);
    delete(handles.closeListener);
    delete(handles.updateListener);
    delete(obj.fh_n);
    obj.fh_n = [];
end