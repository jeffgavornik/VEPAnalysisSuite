function norm_openGui(obj)

if isempty(obj.fh_n)
    % Open the GUI and create handles
    switch obj.normType
        case 'None'
            return;
        case 'Scalar'
            % Setup scalar specific elements
            obj.fh_n = openfig('normPanel_scalar.fig','new','invisible');
            updateClbk = @(src,event)norm_ScalarUpdateGUI_Callback(obj);
            handles = guihandles(obj.fh_n);
            set(handles.sourceMenu,'Callback',updateClbk);
            set(handles.normValue,'Callback',...
                @(src,event)norm_ScalarNormValue_Callback(obj));
            set(handles.doneButton,'Callback',...
                @(src,event)norm_doneButton_Callback(obj));
            set(obj.fh_n,'CloseRequestFcn',@(src,event)norm_closeGUI(obj));
        case 'Element-wise'
            % Setup element-wise specific elements
            obj.fh_n = openfig('normPanel_elementWise','new','invisible');
            updateClbk = @(src,event)norm_EWUpdateGUI(obj,0);
            handles = guihandles(obj.fh_n);
            set([handles.grpButton handles.manualButton],...
                'Callback',@(src,event)norm_EWUpdateGUI(obj,src));
            set(handles.groupSelectionMenu, 'Callback',...
                @(src,event)norm_EWGroupSelection_Callback(obj));
            set(handles.saveButton,'Callback',...
                @(src,event)norm_EWClose_Callback(obj,src));
            set(handles.cancelButton,'Callback',...
                @(src,event)norm_EWClose_Callback(obj,src));
            set(obj.fh_n,'CloseRequestFcn',...
                @(src,event)norm_EWClose_Callback(obj,src));
            
    end
    set(handles.groupPanel,'title',obj.ID);
    % Set color for the source menu as per matlab standards
    if ispc && isequal(get(handles.sourceMenu,'BackgroundColor'), ...
            get(0,'defaultUicontrolBackgroundColor'))
        set(handles.sourceMenu,'BackgroundColor','white');
    end
    % Set listeners for close and refresh events
    handles.closeListener = addlistener(obj.parent,'CloseViewers',...
        @(src,event)norm_closeGUI(obj));
    handles.updateListener = addlistener(obj.parent,'GrpMgmtRefreshGUINeeded',...
        updateClbk);
    % Save the handles
    guidata(obj.fh_n,handles);
    % Store the current normalization variables to app data - they will be
    % manipulated by the callbacks and written back to the object by the
    % done button
    setappdata(obj.fh_n,'normDescStr',obj.normDescStr);
    setappdata(obj.fh_n,'normFactors',obj.normFactors);
    % Override the GUI selection if a valid normalization source already
    % exists
    dataSrc = obj.normFactors('dataSrc');
    if ~strcmp(dataSrc,'Not Set')
        setappdata(obj.fh_n,'overrideGUISelection',dataSrc);
    end
    % Call the method to update the GUI
    updateClbk();
    % Make the GUI visible
    set(obj.fh_n,'Visible','on');
else
    % Raise the existing GUI
    figure(obj.fh_n);
end