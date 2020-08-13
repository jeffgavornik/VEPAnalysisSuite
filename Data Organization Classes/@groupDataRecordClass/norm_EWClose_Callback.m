function norm_EWClose_Callback(obj,src)

handles = guidata(obj.fh_n);

switch src
    case handles.figure1
        
    case handles.cancelButton
        
    case handles.saveButton
        
        % Save the user selections
        dataSrc = getappdata(handles.figure1,'dataSrc');
        obj.normFactors('dataSrc') = dataSrc;
        if isappdata(handles.figure1,'normGrpKey')
            obj.normFactors('NormGrpKey') = ...
                getappdata(handles.figure1,'normGrpKey');
        end
        
        tableData = get(handles.normTable,'Data');
        for iC = 1:size(tableData,1)
            memberKey = tableData{iC,1};
            normValue = tableData{iC,2};
            if ~isempty(normValue)
                obj.normFactors(memberKey) = normValue;
            end
        end
        
        switch dataSrc
            case 'Group'
                if isappdata(handles.figure1,'normGrpKey')
                    obj.normDescStr = sprintf('%s:''%s''',dataSrc,...
                        getappdata(handles.figure1,'normGrpKey'));
                else
                    obj.normDescStr = 'Group:N/A';
                end
            case 'Manual'
                obj.normDescStr = sprintf('%s\nConfiguration',dataSrc);
        end

end

obj.norm_closeGUI;
notify(obj.parent,'GrpMgmtRefreshGUINeeded');