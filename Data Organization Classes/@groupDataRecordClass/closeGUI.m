function closeGUI(obj,~,~)
handles = guidata(obj.fh);
delete(handles.figure1);
obj.fh = [];
end