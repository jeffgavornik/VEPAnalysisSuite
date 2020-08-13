function norm_EWGroupSelection_Callback(obj)

handles = guidata(obj.fh_n);
vdo = obj.parent;

% Get the selected normalization group from the GUI
groupKeys = get(handles.groupSelectionMenu,'String');
selVal = get(handles.groupSelectionMenu,'Value');
normGrpKey = groupKeys{selVal};
if strcmp(normGrpKey,'Select Group')
%     data = get(handles.normTable,'data');
%     data(:,2) = cell(size(data,1),1);
%     set(handles.normTable,'Data',data,'ColumnFormat',{'char' 'char'});
    return
end
normGrp = vdo.groupRecords(normGrpKey);

% Update menu to get rid of the 'select group' option
if sum(strcmp(get(handles.groupSelectionMenu,'String'),'Select Group'))
    set(handles.groupSelectionMenu,'string',vdo.groupRecords.keys,...
        'Value',get(handles.groupSelectionMenu,'Value')-1);
end

% Get the current selection values from the GUI and member keys for 
% both groups
data = get(handles.normTable,'data');
grpMembers = data(:,1)';
normMembers = normGrp.dataSpecifiers.keys;

% Make default selections assuming indici match across the groups
nG = length(grpMembers);
nN = length(normMembers);
normValues = cell(1,nG);
for iG = 1:nG
    if iG <= nN
        normValues{iG} = normMembers{iG};
    else
        normValues{iG} = '';
    end
end

% Write data back to the table and allow user to modify selection keys
newData = [grpMembers' normValues'];
set(handles.normTable,'Data',newData,'ColumnFormat',{'char' normMembers});

% Save the current selections as app data
setappdata(handles.figure1,'normGrpKey',normGrpKey);
setappdata(handles.figure1,'normGrp',normGrp);

% norm_EWUpdateGUI(obj);