function norm_EWUpdateGUI(obj,src)
 
handles = guidata(obj.fh_n);
assignin('base','handles',handles);

% Ignore multiple normSource selection presses
if src == handles.grpButton && ~get(handles.grpButton,'Value') == 1
    set(handles.grpButton,'Value',1);
    return
end

if src == handles.manualButton && ~get(handles.manualButton,'Value') == 1
    set(handles.manualButton,'Value',1);
    return
end

try
    vdo = obj.parent;
    configureOption = 'Default';
    grpMembers = obj.dataSpecifiers.keys;
    nM = length(grpMembers);
    switch src
        % Handle the case where the GUI has just been opened - if a
        % dataSrc is already specified, configure the GUI appropriately
        case 0
            % Populate the table with group members
            normFactors = cell(nM,1);
            % Look to see if there is a saved dataSrc
            switch obj.normFactors('dataSrc')
                case 'Group'
                    % If a group has been saved, select it
                    if obj.normFactors.isKey('NormGrpKey')
                        configureOption = 'Group';
                        normGrpKey = obj.normFactors('NormGrpKey');
                        groupKeys = [vdo.groupRecords.keys];
                        selValue = find(strcmp(groupKeys,normGrpKey));
                        set(handles.groupSelectionMenu,...
                            'string',groupKeys,'Value',selValue);
                        set(handles.normTable,'ColumnFormat',...
                            {'char' ...
                            vdo.groupRecords(normGrpKey).dataSpecifiers.keys});
                        % Load stored normalization values
                        for iM = 1:nM
                            memberKey = grpMembers{iM};
                            if obj.normFactors.isKey(memberKey)
                                normFactor = obj.normFactors(memberKey);
                                if ~ischar(normFactor)
                                    normFactor = '';
                                end
                            else
                                normFactor = '';
                            end
                            normFactors{iM} = normFactor;
                        end
                    end
                case 'Manual'
                    configureOption = 'Manual';
                    for iM = 1:nM
                        memberKey = grpMembers{iM};
                        if obj.normFactors.isKey(memberKey)
                            normFactor = obj.normFactors(memberKey);
                            if ischar(normFactor)
                                normFactor = 1;
                            end
                        else
                            normFactor = 1;
                        end
                        normFactors{iM} = normFactor;
                    end
            end
        case handles.grpButton
            configureOption = 'Default';
            normFactors = cell(nM,1);
        case handles.manualButton
            configureOption = 'Manual';
            normFactors = num2cell(ones(nM,1));
    end
    newData = [grpMembers' normFactors];
    set(handles.normTable,'Data',newData);
    
    switch configureOption
        case 'Default'
            groupKeys = [{'Select Group'} vdo.groupRecords.keys];
            set(handles.groupSelectionMenu,'Visible','on',...
                'string',groupKeys,'Value',1);
            setappdata(handles.figure1,'dataSrc','Group');
        case 'Group'
            setappdata(handles.figure1,'dataSrc','Group');
        case 'Manual'
            set(handles.grpButton,'Value',0);
            set(handles.manualButton,'Value',1);
            set(handles.normTable,'ColumnFormat',{'char' 'numeric'});
            set(handles.groupSelectionMenu,'Visible','off');
            setappdata(handles.figure1,'dataSrc','Manual');
    end
    
  
    
    %     % Get the data source from the current GUI state
    %     grpSel = get(handles.grpButton,'Value');
    %     manSel = get(handles.manualButton,'Value');
    %     if grpSel && ~manSel
    %         dataSrc = 'Group';
    %     elseif ~grpSel && manSel
    %         dataSrc = 'Manual';
    %     else
    %         error('Group and Manual both selected');
    %     end
    %     obj.normFactors('dataSrc') = dataSrc;
    %
    %     % Configure the GUI based on group content and existing selections
    %     grpMembers = obj.dataSpecifiers.keys;
    %     nM = length(grpMembers);
    %     normFactors = cell(1,nM);
    %     switch dataSrc
    %         case 'Manual'
    %             set(handles.groupSelectionMenu,'Visible','off');
    %             obj.normFactors('NormGrpKey') = '';
    %             set(handles.normTable,'ColumnFormat',{'char' 'numeric'});
%                 for iM = 1:nM
%                     memberKey = grpMembers{iM};
%                     if obj.normFactors.isKey(memberKey)
%                         normFactor = obj.normFactors(memberKey);
%                         if ischar(normFactor)
%                             normFactor = 1;
%                         end
%                     else
%                         normFactor = 1;
%                     end
%                     normFactors{iM} = normFactor;
%                 end
    %         case 'Group'
    %             set(handles.groupSelectionMenu,'Visible','on');
    %             set(handles.groupSelectionMenu,'string',groupKeys);
    %             % If a normalization group was specified before GUI opening, select
    %             % it on the GUI
    %             if exist('normGrpKey','var')
    %                 selVal = find(strcmp(groupKeys,normGrpKey));
    %                 if isempty(selVal)
    %                     selVal = 1;
    %                 end
    %                 set(handles.groupSelectionMenu,'Value',selVal);
    %             end
    %
    %     end
    %
    %     % Write back table contents
    %     newData = [grpMembers' normFactors'];
    %     set(handles.normTable,'Data',newData);
    
    
catch ME
    fprintf(2,'Error Report: %s',getReport(ME));
    beep
end


end