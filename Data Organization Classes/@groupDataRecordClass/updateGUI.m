function updateGUI(obj)

if ~isempty(obj.fh)
    handles = guidata(obj.fh);
    if get(handles.groupMembersBox,'Value') < 1
        set(handles.groupMembersBox,'Value',1);
    end
    set(handles.groupMembersBox,'String',obj.getSpecifierKeys());
    set(handles.grpPanel,'Title',sprintf('Group Members: %s',obj.ID));
    set(handles.figure1,'Name',sprintf('%s',class(obj)));
end