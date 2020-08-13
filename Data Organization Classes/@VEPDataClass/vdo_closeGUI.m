function vdo_closeGUI(obj,forceFlag)

if nargin < 2
    forceFlag = false;
end

handles = guidata(obj.fh);
if ~obj.isHeadless
    if obj.dirtyBit && ~forceFlag
        % Prompt the user to save before quitting or cancel
        prompt = sprintf('Save changes before quitting?');
        selection = questdlg(prompt,...
            ['Close ' obj.ID '...'],...
            'Save Changes','Discard Changes','Cancel',...
            'Save Changes');
        switch selection
            case 'Cancel'
                return;
            case 'Save Changes'
                obj.vdo_guiCallbacks(handles.saveDataMenu,[]);
        end
    end
    
    % Close the GUI by deleting its graphics object handle
    obj.occupado(true)
    delete(handles.figure1);
    
    % Post a notification so that any open data viewers will close
    notify(obj,'CloseViewers');
    
end

% Delete the object
delete(obj);

end