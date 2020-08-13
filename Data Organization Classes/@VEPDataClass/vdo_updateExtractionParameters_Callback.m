function vdo_updateExtractionParameters_Callback(obj,src)
% Provides the ability for the user to change default import, scoring and
% analysis parameters from the GUI

handles = guidata(obj.fh);
switch src
    case handles.extractTimeWindowTxt
        prompt = sprintf('Enter the data extraction time in seconds');
        windowName = 'Extraction Parameter Update';
        oldValue = obj.getExtractTimeWindow;
        defaultValue = sprintf('%1.3f',oldValue);
        userResponse = inputdlg(prompt,windowName,1,{defaultValue});
        if ~isempty(userResponse)
            newValue = str2double(userResponse{1});
            if newValue ~= oldValue
                obj.setExtractTimeWindow(newValue);
            end
            notify(obj,'ReloadRawData');
            notify(obj,'ExtractTraces');
            notify(obj,'RefreshGUINeeded');
        end
    case handles.negLatRangeText
        prompt = {'Enter the min negative latency in seconds',...
            'Enter the max negative latency in seconds'};
        windowName = 'Extraction Parameter Update';
        oldValues = obj.getNegativeLatencyRange;
        defaultValues = {sprintf('%1.3f',oldValues(1)),...
            sprintf('%1.3f',oldValues(2))};
        userResponse = inputdlg(prompt,windowName,1,defaultValues);
        if ~isempty(userResponse)
            newValues = [str2double(userResponse{1}),...
                str2double(userResponse{2})];
            if sum(oldValues == newValues) < 2
                obj.setNegativeLatencyRange(newValues);
            end
            % notify(obj,'RefreshGUINeeded');
            % obj.performTraceOperations('ScoringParameters');
            % notify(obj,'UpdateViewers');
        end
    case handles.maxPosLatText
        prompt = sprintf('Enter the maximum positive latency in seconds');
        windowName = 'Extraction Parameter Update';
        oldValue = obj.getMaxPositiveLatency;
        defaultValue = sprintf('%1.3f',oldValue);
        userResponse = inputdlg(prompt,windowName,1,{defaultValue});
        if ~isempty(userResponse)
            newValue = str2double(userResponse{1});
            if newValue ~= oldValue
                obj.setMaxPositiveLatency(newValue);
            end
            % notify(obj,'RefreshGUINeeded');
            % obj.performTraceOperations('ScoringParameters');
            % notify(obj,'UpdateViewers');
        end
    case handles.smoothWidthText
        prompt = sprintf('Enter the smoothing kernel width');
        windowName = 'Extraction Parameter Update';
        oldValue = obj.getSmoothWidth;
        defaultValue = sprintf('%i',oldValue);
        userResponse = inputdlg(prompt,windowName,1,{defaultValue});
        if ~isempty(userResponse)
            newValue = str2double(userResponse{1});
            if newValue ~= oldValue
                obj.setSmoothWidth(newValue);
            end
            % notify(obj,'RefreshGUINeeded');
            % obj.performTraceOperations('Smoothing');
            % notify(obj,'UpdateViewers');
        end
    case handles.scrubThresholdTxt
        prompt = sprintf('Enter the trace rejection threshold in uV');
        windowName = 'Extraction Parameter Update';
        oldValue = obj.getScrubThreshold;
        defaultValue = sprintf('%i',oldValue);
        userResponse = inputdlg(prompt,windowName,1,{defaultValue});
        if ~isempty(userResponse)
            newValue = str2double(userResponse{1});
            if newValue ~= oldValue
                obj.setScrubThreshold(newValue);
            end
            % notify(obj,'RefreshGUINeeded');
            % obj.performTraceOperations('Threshold');
            % notify(obj,'UpdateViewers');
        end
    otherwise
        disp('wtf');
end
end