classdef traceViewerClass < VDOAnalysisClass
    
    %#ok<*NASGU>
    
    properties (Constant,Hidden=true)
        menuString = 'Trace Viewer'
        % Set default axes  and line properties
        dfltYLim = [-500 500];
    end
    
    properties %(Hidden=true)
        % Management object to keep track of plots
        managerObj = VEPPlotManagerClass;
        % dataSpecifierObjects to retrieve keys and VEP traces
        kidKeyTemplate = getDataSpecifierTemplate('kidKeys');
        VEPTraceTemplate = getDataSpecifierTemplate('VEPTrace');
        VEPScoreTemplate = getDataSpecifierTemplate('VEPscore');
        channelsTemplate = getDataSpecifierTemplate('channelKeys');
        validTracesTemplate = getDataSpecifierTemplate('ValidTraces');
        % Animal-Session-Stim data selection
        animalKey = [];
        conditionKey = [];
        stimKey = [];
        channelKeys = [];
        groupKey = '';
        srcChangeHandles;
        % Working plot handles will show current selection data
        CH1_workingPlot
        Ch1ConstituentTraces = [];
        CH2_workingPlot
        Ch2ConstituentTraces = [];
        % Magnitude scoring indicators
        CH1ScoreInd
        CH2ScoreInd
        scoringTickVisibility = 'on';
        % Allow continuous updating when the slider is moved
        slideListener
        oldSlideIndex
        % Support manual scoring
        ScoreChangedListeners
        % Objects associated with data export
        exportButtons
        dataExportHandles
    end
    
    methods
        
        function obj = traceViewerClass(vdo)
            
            % Associate object with passed VEPDataClass
            obj.associateVEPDataObject(vdo);
            
            % Setup for Animal-Session-Stim data selection
            obj.srcChangeHandles = [obj.handles.animalTxt,...
                obj.handles.sessionTxt,...
                obj.handles.animalMenu,...
                obj.handles.conditionMenu,...
                obj.handles.CH2axes];
            
            % Create the working plot handles - these will show currently
            % selected data
            obj.CH1_workingPlot = plot(obj.handles.CH1axes,[0 1],[0 1],...
                'color','k','Visible','off','linewidth',2);
            obj.CH2_workingPlot = plot(obj.handles.CH2axes,[0 1],[0 1],...
                'color','k','Visible','off','linewidth',2);
            
            % Setup the slide listener
            obj.slideListener = addlistener(obj.handles.stimSlide,...
                'ContinuousValueChange',...
                @(hObj,~)stimSlide_listener_callBack(obj));
            obj.listeners(end+1) = obj.slideListener; % auto-delete
            
            % Establish axes formatting
            ylabel(obj.handles.CH1axes,'V (\muV)','fontsize',12,...
                'fontweight','bold');
            set(obj.handles.CH1axes,'YLim',obj.dfltYLim);
            set(obj.handles.CH2axes,'YLim',obj.dfltYLim);
            
            % Setup plots to show scoring data on the working plots
            obj.CH1ScoreInd = VEPScoringIndicatorClass(obj.CH1_workingPlot);
            obj.CH1ScoreInd.setVisible('on');
            obj.CH2ScoreInd = VEPScoringIndicatorClass(obj.CH2_workingPlot);
            obj.CH2ScoreInd.setVisible('on');
            
            % Setup for data export
            obj.exportButtons = [obj.handles.ch1ExportButton,...
                obj.handles.ch2ExportButton];
            obj.dataExportHandles = [obj.handles.exportPendingCheckbox,...
                obj.handles.exportDataButton,...
                obj.handles.cancelExportButton];
            evntData.NewValue = obj.handles.figureButton;
            exportCtrlPanel_Callback(obj,evntData);
            
            obj.handles.CH1Text = text(0.75,0.85,'tmp',...
                'Units','Normalized',...
                'Parent',obj.handles.CH1axes,...
                'Visible','off',...
                'Interpreter','LaTeX',...
                'FontName','Helvetica',...
                'Fontsize',14);
            
            obj.handles.CH2Text = text(0.75,0.85,'tmp',...
                'Units','Normalized',...
                'Parent',obj.handles.CH2axes,...
                'Visible','off',...
                'Interpreter','LaTeX',...
                'FontName','Helvetica',...
                'Fontsize',14);
            
            if ~isempty(obj.vdo)
                obj.vdoUpdate_Callback;
            end
            
            % Establish all Callback links
            obj.handles.exportCtrlPanel.SelectionChangeFcn = ...
                @(~,event)exportCtrlPanel_Callback(obj,event);
            obj.handles.ch1ExportButton.Callback = ...
                @(hObj,~)exportFigure_Callback(obj,hObj);
            obj.handles.ch2ExportButton.Callback = ...
                @(hObj,~)exportFigure_Callback(obj,hObj);
            obj.handles.cancelExportButton.Callback = ...
                @(hObj,~)executeDataExport_Callback(obj,hObj);
            obj.handles.exportDataButton.Callback = ...
                @(hObj,~)executeDataExport_Callback(obj,hObj);
            obj.handles.exportPendingCheckbox.Callback = ...
                @(hObj,~)checkboxOverride(hObj);
            obj.handles.exportMenu.Callback = ...
                @(varargin)exportlMenu_Callback(obj);
            obj.handles.verticalDraggingBox.Callback = ...
                @(varargin)dragOptions_Callback(obj);
            obj.handles.horizontalDraggingBox.Callback = ...
                @(varargin)dragOptions_Callback(obj);
            obj.handles.resetBox.Callback = ...
                @(varargin)resetBox_Callback(obj);
            obj.handles.hideMagsBox.Callback = ...
                @(varargin)hideMagsBox_Callback(obj);
            obj.handles.hideWPCheckbox.Callback = ...
                @(varargin)hideWPCheckbox_Callback(obj);
            obj.handles.deleteplotbutton.Callback = ...
                @(varargin)deleteplotbutton_Callback(obj);
            obj.handles.addplotbutton.Callback = ...
                @(varargin)addplotbutton_Callback(obj);
            obj.handles.showTracesCheckBox.Callback = ...
                @(varargin)updatePlots(obj);
            obj.handles.stimMenu.Callback = ...
                @(hObj,event)stimMenu_Callback(obj,hObj,event);
            obj.handles.conditionMenu.Callback = ...
                @(varargin)conditionMenu_Callback(obj);
            obj.handles.animalMenu.Callback = ...
                @(varargin)animalMenu_Callback(obj);
            obj.handles.resetScoreButton.Callback = ...
                @(hObj,~)manScoreButton_Callback(obj,hObj);
            obj.handles.cancelScoreButton.Callback = ...
                @(hObj,~)manScoreButton_Callback(obj,hObj);
            obj.handles.manScoreButton.Callback = ...
                @(hObj,~)manScoreButton_Callback(obj,hObj);
            obj.handles.ch2SelMenu.Callback = ...
                @(hObj,~)chSelMenu_Callback(obj,hObj);
            obj.handles.ch1SelMenu.Callback = ...
                @(hObj,~)chSelMenu_Callback(obj,hObj);
            obj.handles.yAxesSelectMenu.Callback = ...
                @(hObj,~)setAxes_Callback(obj,hObj);
            obj.handles.yAxesAutoMenu.Callback = ...
                @(hObj,~)setAxes_Callback(obj,hObj);
            obj.handles.xAxesSelectMenu.Callback = ...
                @(hObj,~)setAxes_Callback(obj,hObj);
            obj.handles.xAxesAutoMenu.Callback = ...
                @(hObj,~)setAxes_Callback(obj,hObj);
            obj.handles.lineWidthMenu.Callback = ...
                @(hObj,~)setAxes_Callback(obj,hObj);
            
            % Make the GUI visible
            notify(obj,'ReadyToShowGUI');
        end
        
        function delete(obj)
            delete(obj.ScoreChangedListeners);
        end
        
        function vdoUpdate_Callback(obj)
            % Called when the linked VEPDataClass object posts a
            % notification that it's contents have changed.  Also used at
            % object initialization
            
            % Get the current animal selection value
            oldAnimalKeys = cellstr(get(obj.handles.animalMenu,'String'));
            oldAnimalKey = oldAnimalKeys{get(obj.handles.animalMenu,'Value')};
            % Get the animal keys from the VEPDataObject
            animalKeys = obj.vdo.getAnimalKeys;
            set(obj.handles.animalMenu,'String',animalKeys);
            % If the previously selected animal exists, use it.
            % If not, use the first animal as the default selection
            animalIndex = strcmp(animalKeys,oldAnimalKey);
            if sum(animalIndex)
                set(obj.handles.animalMenu,'Value',find(animalIndex == 1));
            else
                set(obj.handles.animalMenu,'Value',1);
            end
            obj.animalMenu_Callback();
        end
        
        % -----------------------------------------------------------------
        % Data selection methods
        % -----------------------------------------------------------------
        
        % Select the Animal
        function animalMenu_Callback(obj)
            
            % Get the current stimulus selection value
            oldConditionKeys = cellstr(get(obj.handles.conditionMenu,'String'));
            oldConditionKey = oldConditionKeys{get(obj.handles.conditionMenu,'Value')};
            
            % Populate condition menu with conditions for the selected animal
            animalKeys = cellstr(get(obj.handles.animalMenu,'String'));
            obj.animalKey = animalKeys{get(obj.handles.animalMenu,'Value')};
            obj.kidKeyTemplate.resetDataPath();
            obj.kidKeyTemplate.setHierarchyLevel(1,obj.animalKey);
            obj.VEPTraceTemplate.resetDataPath();
            obj.VEPTraceTemplate.setHierarchyLevel(1,obj.animalKey);
            obj.VEPScoreTemplate.resetDataPath();
            obj.VEPScoreTemplate.setHierarchyLevel(1,obj.animalKey);
            obj.channelsTemplate.resetDataPath();
            obj.channelsTemplate.setHierarchyLevel(1,obj.animalKey);
            obj.validTracesTemplate.resetDataPath();
            obj.validTracesTemplate.setHierarchyLevel(1,obj.animalKey);
            conditionKeys = obj.vdo.getData(obj.kidKeyTemplate);
            set(obj.handles.conditionMenu,'String',conditionKeys);
            
            % If the previously selected condition exists for the new animal, use it.
            % If not, use the first condition as the default selection
            condIndex = strcmp(conditionKeys,oldConditionKey);
            if sum(condIndex)
                set(obj.handles.conditionMenu,'Value',find(condIndex == 1));
            else
                set(obj.handles.conditionMenu,'Value',1);
            end
            obj.conditionMenu_Callback();
        end
        
        % Select the condition
        function conditionMenu_Callback(obj)
            
            % Get the current stimulus selection value
            oldStimKeys = cellstr(get(obj.handles.stimMenu,'String'));
            oldStimKey = oldStimKeys{get(obj.handles.stimMenu,'Value')};
            
            % Populate condition menu with conditions for the selected animal
            strContents = cellstr(get(obj.handles.conditionMenu,'String'));
            obj.conditionKey = strContents{get(obj.handles.conditionMenu,'Value')};
            obj.kidKeyTemplate.setHierarchyLevel(2,obj.conditionKey);
            obj.VEPTraceTemplate.setHierarchyLevel(2,obj.conditionKey);
            obj.VEPScoreTemplate.setHierarchyLevel(2,obj.conditionKey);
            obj.channelsTemplate.setHierarchyLevel(2,obj.conditionKey);
            obj.validTracesTemplate.setHierarchyLevel(2,obj.conditionKey);
            stimKeys = obj.vdo.getData(obj.kidKeyTemplate);
            set(obj.handles.stimMenu,'String',stimKeys)
            
            % If the previously selected stim exists for the new animal, use it.
            % If not, use the first stim as the default selection
            stimIndex = strcmp(stimKeys,oldStimKey);
            if sum(stimIndex)
                selValue = find(stimIndex == 1);
            else
                selValue = 1;
            end
            set(obj.handles.stimMenu,'Value',selValue);
            
            % Setup the silder based on the current stimulus values
            nStims = length(stimKeys);
            
            if nStims == 1
                minVal = 0.9;
                sliderStepValues = [1 1];
            else
                minVal = 1;
                sliderStepValues = [1/(nStims-1) 1/(nStims-1)];
            end
            if min(sliderStepValues) < 0
                return;
            end
            set(obj.handles.stimSlide,'Min',minVal,'Max',nStims,...
                'Value',selValue,'SliderStep',sliderStepValues);
            stimMenu_Callback(obj,obj.handles.stimMenu,[]); % make default selection
        end
        
        % Select the stimulus
        function stimMenu_Callback(obj,hObject,value)
            
            % GUI Glue for Stim Slider or Menu selections
            if hObject ~= obj.handles.stimMenu
                set(obj.handles.stimMenu,'Value',value);
            else
                value = get(hObject,'Value');
                set(obj.handles.stimSlide,'Value',value);
                obj.oldSlideIndex = value;
            end
            
            strContents = cellstr(get(obj.handles.stimMenu,'String'));
            obj.stimKey = strContents{get(obj.handles.stimMenu,'Value')};
            obj.VEPTraceTemplate.setHierarchyLevel(3,obj.stimKey);
            obj.VEPScoreTemplate.setHierarchyLevel(3,obj.stimKey);
            obj.channelsTemplate.setHierarchyLevel(3,obj.stimKey);
            obj.validTracesTemplate.setHierarchyLevel(3,obj.stimKey);
            
            % Make default channel selections
            obj.chSelMenu_Callback([]);
            
            % Draw the plot in CH1 and CH2 axes.
            updatePlots(obj)
        end
        
        % Select the channel to display on each plot
        function chSelMenu_Callback(obj,hObject)
            if isempty(hObject)
                % Programatic call following stim selection
                % Get the channel keys from the current stim selection
                obj.channelKeys = obj.vdo.getData(obj.channelsTemplate);
                % Get the current channel keys from the GUI and, if they are not in the
                % list of channel keys, add and select them
                % Channel 1
                strContents = cellstr(get(obj.handles.ch1SelMenu,'String'));
                chKey = strContents{get(obj.handles.ch1SelMenu,'Value')};
                % iCh = strmatch(chKey,channelKeys);
                iCh = find(strcmp(chKey,obj.channelKeys));
                if isempty(iCh)
                    newKeys = [chKey obj.channelKeys];
                    iCh = 1;
                else
                    newKeys = obj.channelKeys;
                end
                set(obj.handles.ch1SelMenu,'String',newKeys,'Value',iCh);
                % Channel 2
                strContents = cellstr(get(obj.handles.ch2SelMenu,'String'));
                chKey = strContents{get(obj.handles.ch2SelMenu,'Value')};
                % iCh = strmatch(chKey,channelKeys);
                iCh = find(strcmp(chKey,obj.channelKeys));
                if isempty(iCh)
                    newKeys = [chKey obj.channelKeys];
                    iCh = 1;
                else
                    newKeys = obj.channelKeys;
                end
                set(obj.handles.ch2SelMenu,'String',newKeys,'Value',iCh);
            else
                % This code will get rid of invalid string values if any exist
                strContents = cellstr(get(hObject,'String'));
                chKey = strContents{get(hObject,'Value')};
                % iCh = strmatch(chKey,channelKeys);
                iCh = find(strcmp(chKey,obj.channelKeys));
                if isempty(iCh)
                    iCh = 1;
                end
                set(hObject,'String',obj.channelKeys,'Value',iCh);
                obj.updatePlots();
            end
        end
        
        % Called by slider movement evoked 'ActionEvent' listener notification
        function stimSlide_listener_callBack(obj)
            index = round(get(obj.handles.stimSlide,'Value'));
            if index ~= obj.oldSlideIndex
                obj.oldSlideIndex = index;
                %set(obj.handles.stimMenu,'value',index);
                obj.stimMenu_Callback(obj.handles.stimSlide,index);
            end
        end
        
        % -----------------------------------------------------------------
        % Plot methods
        % -----------------------------------------------------------------
        
        % Draw the plots based on the selected stimulus
        function updatePlots(obj)
            
            % Get the valid channel keys and the selected keys
            ch1Contents = cellstr(get(obj.handles.ch1SelMenu,'String'));
            ch1Key = ch1Contents{get(obj.handles.ch1SelMenu,'Value')};
            ch2Contents = cellstr(get(obj.handles.ch2SelMenu,'String'));
            ch2Key = ch2Contents{get(obj.handles.ch2SelMenu,'Value')};
            
            % Check to see if scoring ticks are visible
            if ~get(obj.handles.hideMagsBox,'value')
                obj.scoringTickVisibility = 'on';
            else
                obj.scoringTickVisibility = 'off';
            end
            
            % Get rid of constituent traces if they exist
            delete(obj.Ch1ConstituentTraces);
            obj.Ch1ConstituentTraces = [];
            delete(obj.Ch2ConstituentTraces);
            obj.Ch2ConstituentTraces = [];
            
            % Update working plot with current CH1 data
            if sum(strcmp(ch1Key,obj.channelKeys))
                set(obj.handles.ch1SelMenu,'ForegroundColor',[0 0 0]);
                obj.VEPTraceTemplate.setHierarchyLevel(4,ch1Key);
                obj.VEPScoreTemplate.setHierarchyLevel(4,ch1Key);
                [voltageTrace,tTr] = obj.vdo.getData(obj.VEPTraceTemplate);
                score = obj.vdo.getData(obj.VEPScoreTemplate);
                % Plot constituent traces if menu item is selected
                if get(obj.handles.showTracesCheckBox,'Value')
                    obj.validTracesTemplate.setHierarchyLevel(4,ch1Key);
                    [traces,tTrace] = obj.vdo.getData(obj.validTracesTemplate);
                    nTr = size(traces,2);
                    phs = zeros(1,nTr);
                    hold(obj.handles.CH1axes,'on');
                    colors = flipud(bone(nTr));
                    for iP = 1:nTr
                        phs(iP) = plot(obj.handles.CH1axes,...
                            tTrace,traces(:,iP),'color',colors(iP,:));
                    end
                    hold(obj.handles.CH1axes,'off');
                    obj.Ch1ConstituentTraces = phs;
                    uistack(phs,'bottom');
                end
                if ~isempty(voltageTrace)
                    set(obj.handles.hideWPCheckbox,'Value',0);
                    set(obj.CH1_workingPlot,...
                        'xdata',tTr,'ydata',voltageTrace,...
                        'visible','on');
                    obj.CH1ScoreInd.setScore(score);
                    set(obj.handles.CH1Text,'String',...
                        sprintf('%1.0f$\\mu$V',score.vMag),...
                        'Visible',obj.scoringTickVisibility);
                    obj.CH1ScoreInd.setVisible(obj.scoringTickVisibility);
                else
                    set(obj.CH1_workingPlot,'Visible','off');
                    set(obj.handles.CH1Text,'visible','off');
                    obj.CH1ScoreInd.setVisible('off');
                end
            else
                set(obj.handles.ch1SelMenu,'ForegroundColor',[1 0 0]);
                set(obj.CH1_workingPlot,'Visible','off');
                set(obj.handles.CH1Text,'visible','off');
                obj.CH1ScoreInd.setVisible('off');
            end
            
            % Update working plot with current CH2 data
            if sum(strcmp(ch2Key,obj.channelKeys))
                set(obj.handles.ch2SelMenu,'ForegroundColor',[0 0 0]);
                obj.VEPTraceTemplate.setHierarchyLevel(4,ch2Key);
                obj.VEPScoreTemplate.setHierarchyLevel(4,ch2Key);
                [voltageTrace,tTr] = obj.vdo.getData(obj.VEPTraceTemplate);
                score = obj.vdo.getData(obj.VEPScoreTemplate);
                % Plot constituent traces if menu item is selected
                if get(obj.handles.showTracesCheckBox,'Value')
                    obj.validTracesTemplate.setHierarchyLevel(4,ch2Key);
                    [traces,tTrace] = obj.vdo.getData(obj.validTracesTemplate);
                    nTr = size(traces,2);
                    phs = zeros(1,nTr);
                    hold(obj.handles.CH2axes,'on');
                    colors = flipud(bone(nTr));
                    for iP = 1:nTr
                        phs(iP) = plot(obj.handles.CH2axes,...
                            tTrace,traces(:,iP),'color',colors(iP,:));
                    end
                    hold(obj.handles.CH2axes,'off');
                    obj.Ch2ConstituentTraces = phs;
                    uistack(phs,'bottom');
                end
                if ~isempty(voltageTrace)
                    set(obj.handles.hideWPCheckbox,'Value',0);
                    set(obj.CH2_workingPlot,...
                        'xdata',tTr,'ydata',voltageTrace,...
                        'visible','on');
                    obj.CH2ScoreInd.setScore(score);
                    set(obj.handles.CH2Text,'String',...
                        sprintf('%1.0f$\\mu$V',score.vMag),...
                        'Visible',obj.scoringTickVisibility);
                    obj.CH2ScoreInd.setVisible(obj.scoringTickVisibility);
                else
                    set(obj.CH2_workingPlot,'Visible','off');
                    set(obj.handles.CH2Text,'visible','off');
                    obj.CH2ScoreInd.setVisible('off');
                end
            else
                set(obj.handles.ch2SelMenu,'ForegroundColor',[1 0 0]);
                set(obj.CH2_workingPlot,'Visible','off');
                set(obj.handles.CH2Text,'visible','off');
                obj.CH2ScoreInd.setVisible('off');
            end
            
            % If enabled, update the scoring info
            obj.scoresChanged_Callback;
            
        end
        
        function setAxes_Callback(obj,src)
            switch src
                case obj.handles.xAxesAutoMenu
                    set(obj.handles.CH2axes,'XLimMode','auto');
                    set(obj.handles.CH1axes,'XLimMode','auto');
                    set(obj.handles.xAxesAutoMenu,'checked','on');
                    set(obj.handles.xAxesSelectMenu,'checked','off');
                case obj.handles.xAxesSelectMenu
                    xlim = userSelectAxes('X Axis','ms',{'0' '0.5'});
                    if ~isempty(xlim)
                        set(obj.handles.CH2axes,'XLim',xlim,'XLimMode','manual');
                        set(obj.handles.CH1axes,'XLim',xlim,'XLimMode','manual');
                        set(obj.handles.xAxesAutoMenu,'checked','off');
                        set(obj.handles.xAxesSelectMenu,'checked','on');
                    end
                case obj.handles.yAxesAutoMenu
                    set(obj.handles.CH2axes,'YLimMode','auto');
                    set(obj.handles.CH1axes,'YLimMode','auto');
                    set(obj.handles.yAxesAutoMenu,'checked','on');
                    set(obj.handles.yAxesSelectMenu,'checked','off');
                case obj.handles.yAxesSelectMenu
                    ylim = userSelectAxes('Y Axis','uV',{'-500' '500'});
                    if ~isempty(ylim)
                        set(obj.handles.CH2axes,'YLim',ylim,'YLimMode','manual');
                        set(obj.handles.CH1axes,'YLim',ylim,'YLimMode','manual');
                        set(obj.handles.yAxesAutoMenu,'checked','off');
                        set(obj.handles.yAxesSelectMenu,'checked','on');
                    end
                case obj.handles.lineWidthMenu
                    userResponse = inputdlg('Select Line Width','',1,{'2'});
                    if ~isempty(userResponse)
                        linewidth = str2double(userResponse{1});
                        set(obj.CH1_workingPlot,'LineWidth',linewidth);
                        set(obj.CH2_workingPlot,'LineWidth',linewidth);
                        obj.managerObj.setLineWidth(linewidth);
                    end
            end
        end
        
        function addplotbutton_Callback(obj)
            % Tell the manager to copy the working plot
            obj.managerObj.addPlot(obj.handles);
        end

        function deleteplotbutton_Callback(obj)
            % Tell the manager to delete the selected plot
            legend = obj.handles.legendBox;
            % Create a string based on the current selection
            selected = get(legend,'Value');
            obj.managerObj.deletePlot(obj.handles,selected);
        end
                
        % -----------------------------------------------------------------
        % VEP Scoring Methods
        % -----------------------------------------------------------------
        
        function setupForManualScoring(obj)
            obj.ScoreChangedListeners = [];
        end
        
        function manScoreButton_Callback(obj,hObject)
            % Activate Manual VEP Scoring function
            switch hObject
                case obj.handles.manScoreButton
                    if strcmp(get(obj.handles.manScoreButton,'String'),'Save')
                        scoreDictName = 'Manual';
                        % Make a DataSelectionObject to find the active channelDataObjects
                        dso = obj.VEPTraceTemplate.copy();
                        dso.setDataSpecifier('returnTheObject');
                        % Get scores and save back to the VEPDataObject
                        if obj.CH1ScoreInd.scoreChanged
                            ch1Contents = cellstr(get(obj.handles.ch1SelMenu,'String'));
                            ch1Key = ch1Contents{get(obj.handles.ch1SelMenu,'Value')};
                            dso.setDataPathElement('channel',ch1Key);
                            theChannel = obj.vdo.getData(dso);
                            theScore = obj.CH1ScoreInd.getScore;
                            theChannel.addScoreFromSrc(scoreDictName,theScore);
                        end
                        if obj.CH2ScoreInd.scoreChanged
                            ch2Contents = cellstr(get(obj.handles.ch2SelMenu,'String'));
                            ch2Key = ch2Contents{get(obj.handles.ch2SelMenu,'Value')};
                            dso.setDataPathElement('channel',ch2Key);
                            theChannel = obj.vdo.getData(dso);
                            theScore = obj.CH2ScoreInd.getScore;
                            theChannel.addScoreFromSrc(scoreDictName,theScore);
                        end
                        obj.enableScoring(false);
                    else
                        obj.enableScoring(true);
                    end
                case obj.handles.cancelScoreButton
                    obj.CH1ScoreInd.restoreOriginalPosition;
                    obj.CH2ScoreInd.restoreOriginalPosition;
                    obj.scoresChanged_Callback();
                    obj.enableScoring(false);
                case obj.handles.resetScoreButton
                    obj.CH1ScoreInd.restoreOriginalPosition;
                    obj.CH2ScoreInd.restoreOriginalPosition;
                    obj.scoresChanged_Callback();
            end
            
        end
        
        function enableScoring(obj,enable)
            % Score handles are visible only during scoring
            scoreHandles = [obj.handles.ch1ScoreTxt,...
                obj.handles.ch2ScoreTxt,...
                obj.handles.cancelScoreButton,...
                obj.handles.resetScoreButton];
            % Other handles are disabled during scoring
            otherHandles = [ obj.handles.animalMenu,...
                obj.handles.conditionMenu,obj.handles.stimMenu,...
                obj.handles.stimSlide,obj.handles.exportMenu,...
                obj.handles.figureButton,obj.handles.groupButton,...
                obj.handles.dataButton, obj.handles.addplotbutton,...
                obj.handles.deleteplotbutton,obj.handles.hideWPCheckbox,...
                obj.handles.hideMagsBox,obj.handles.resetBox,...
                obj.handles.horizontalDraggingBox,...
                obj.handles.verticalDraggingBox,...
                obj.handles.ch1ExportButton,obj.handles.ch2ExportButton,...
                obj.handles.ch1SelMenu,obj.handles.ch2SelMenu];
            % Enable/disable score indicator objects
            obj.CH1ScoreInd.enableScoring(enable);
            obj.CH2ScoreInd.enableScoring(enable);
            % Set GUI and
            if enable
                set(scoreHandles,'Visible','on');
                set(otherHandles,'Enable','off');
                set(obj.handles.manScoreButton,'String','Save',...
                    'TooltipString','Manually score data');
                % Create a callback to update the displayed scores
                l1 = addlistener(obj.CH1ScoreInd,'ScoreChanged',...
                    @(src,event)scoresChanged_Callback(obj));
                l2 = addlistener(obj.CH2ScoreInd,'ScoreChanged',...
                    @(src,event)scoresChanged_Callback(obj));
                obj.ScoreChangedListeners = [l1,l2];
                % Update the displayed score data
                obj.scoresChanged_Callback();
            else
                set(scoreHandles,'Visible','off');
                set(otherHandles,'Enable','on');
                set(obj.handles.manScoreButton,'String','Score',...
                    'TooltipString','Save modified scores' );
                % Remove listener callbacks
                delete(obj.ScoreChangedListeners);
                obj.ScoreChangedListeners = [];
            end
        end
        
        function scoresChanged_Callback(obj)
            % Update the text field displaying the manual score values
            if strcmp(get(obj.handles.manScoreButton,'String'),'Save')
                set(obj.handles.ch1ScoreTxt,'String',...
                    obj.CH1ScoreInd.getScoreStr);
                set(obj.handles.ch2ScoreTxt,'String',...
                    obj.CH2ScoreInd.getScoreStr);
            end
        end
        
        % -----------------------------------------------------------------
        % Data export methods
        % -----------------------------------------------------------------
        function exportCtrlPanel_Callback(obj,eventdata)
            % Select export function
            switch get(eventdata.NewValue,'Tag') % Get Tag of selected object
                case 'figureButton'
                    obj.setupForFigureExport;
                    set(obj.dataExportHandles,'Visible','off');
                case 'groupButton'
                    obj.setupForGroupExport;
                    set(obj.dataExportHandles,'Visible','off');
                case 'dataButton'
                    obj.setupForDataExport;
                    set(obj.dataExportHandles,'Visible','on');
                otherwise
                    error('VEPDataObjectViewer.exportCtrlPanel_Callback');
            end
        end
        
        % ---- Figure Export -----
        function setupForFigureExport(obj)
            % Prepare to export axes data as a figure
            options = {'Postscript','JPEG','Figure Only'};
            set(obj.handles.exportMenu,'String',options,'Value',1,'Callback',[],...
                'ToolTipString','Set figure export type','Enable','on');
            set(obj.exportButtons,'Callback',...
                @(hObj,~)exportFigure_Callback(obj,hObj),...
                'ToolTipString','Create formatted figure','Enable','on');
        end
        
        function exportFigure_Callback(obj,hObject)
            
            % Figure out which channel to export
            switch hObject
                case obj.handles.ch1ExportButton
                    hSrc = obj.handles.CH1axes;
                    chStrs = cellstr(get(obj.handles.ch1SelMenu,'String'));
                    chStr = chStrs{get(obj.handles.ch1SelMenu,'Value')};
                    iCh = 1;
                case obj.handles.ch2ExportButton
                    hSrc = obj.handles.CH2axes;
                    chStrs = cellstr(get(obj.handles.ch2SelMenu,'String'));
                    chStr = chStrs{get(obj.handles.ch2SelMenu,'Value')};
                    iCh = 2;
            end
            
            % Copy the plot axes to a new figure
            fh = figure('color',[1 1 1]);
            ah = copyobj(hSrc,fh);
            set(ah,'units','normalized','position',[0.13 0.11 0.775 0.815]);
            oldTitle = get(ah,'Title');
            oldTitle = get(oldTitle,'String');
            title(ah,[]);
            
            % Draw a scale bar on the new axes
            xTicks = get(ah,'XTick');
            yTicks = get(ah,'YTick');
            xPts = [0 0 0.1 0.1];
            yPts = [100 0 0 0] + (yTicks(1) - (yTicks(2)-yTicks(1))/2);
            hold(ah,'on')
            lh = plot(xPts,yPts,'k');
            hold(ah,'off')
            axis(ah,'off')
            xTxtLoc = (xPts(3)-xPts(2))/2;
            yTxtLoc = yPts(2) - (yTicks(2)-yTicks(1))/3;
            th1 = text(xTxtLoc,yTxtLoc,'100 ms',...
                'Parent',ah,'HorizontalAlignment','center');
            xTxtLoc = (xTicks(1)-xTicks(2))/3;
            yTxtLoc = yPts(2) - (yPts(2)-yPts(1))/2;
            th2 = text(xTxtLoc,yTxtLoc,'100 \muV',...
                'Parent',ah,'HorizontalAlignment','center','Rotation',90);
            
            % Rescale axes to fit the scale and center the data
            deltaX = 0.05;
            deltaY = 50;
            xlim(ah,[min(xTicks(1),xPts(1)) max(xTicks(end),xPts(3))]+[-1 1]*deltaX);
            ylim(ah,[min(yTicks(2),yPts(1)) max(yTicks(end),yPts(1))]+[-1 1]*deltaY);
            
            % Truncate underlying data at the axis limits
            lineObjs = findobj(ah,'type','line');
            for iL = 1:numel(lineObjs)
                if lineObjs(iL) ~= lh % don't chop the scale bars
                    xData = get(lineObjs(iL),'xdata');
                    yData = get(lineObjs(iL),'ydata');
                    xind = (xData > xTicks(end)) | (xData < xTicks(1));
                    if ~isempty(xind)
                        xData = xData(~xind);
                        yData = yData(~xind);
                    end
                    yind = (yData > yTicks(end)) | (yData < yTicks(1));
                    if ~isempty(yind)
                        xData = xData(~yind);
                        yData = yData(~yind);
                    end
                    set(lineObjs(iL),'xdata',xData,'ydata',yData);
                end
            end
            
            % Create a legend using binding labels
            bindings = obj.managerObj.getBindings;
            keys = bindings.keys;
            if ~isempty(keys)
                legStr = {};
                for iK = 1:numel(keys)
                    theBinding = bindings(keys{iK});
                    plotHandles(iK) = theBinding{2}.lineObj; %#ok<AGROW>
                    chKeys = theBinding{4};
                    newLegStr = [theBinding{1} '_' chKeys{iCh}];
                    legStr{end+1} = regexprep(newLegStr,'_','\\_'); %#ok<AGROW>
                end
                % Add working plot title if it is visible
                if get(obj.handles.hideWPCheckbox,'Value') == 0
                    legStr{end+1} = sprintf('%s\\_%s\\_%s\\_%s',...
                        obj.animalKey,obj.conditionKey,...
                        obj.stimKey,chStr);
                    plotHandles(end+1) = handles.CH1_workingPlot;
                end
                legend(ah,plotHandles,legStr,'location','northeast')
            else
                legend(ah,oldTitle,'location','northeast');
            end
            
            % Delete extraneous text objects
            delete(findobj(fh,'String','tmp'));
            
            % Turn off clipping everywhere
            objs = findobj(fh,'-property','Clipping');
            for iO = 1:numel(objs)
                set(objs(iO),'Clipping','off');
            end
            
            % Get rid off all button down functions
            objs = findobj(fh,'-property','ButtonDownFcn');
            for iO = 1:numel(objs)
                set(objs(iO),'ButtonDownFcn',[]);
            end
            
            % Prompt for filename and export
            exportStrs = cellstr(get(obj.handles.exportMenu,'String'));
            exportType = exportStrs{get(obj.handles.exportMenu,'Value')};
            switch exportType
                case 'Postscript'
                    [filename, pathname] = uiputfile('*.eps',...
                        'Save figure as eps','tracePlot.eps');
                    if isequal(filename,0) || isequal(pathname,0) % user select cancel
                        return;
                    end
                    outputFile = fullfile(pathname,filename);
                    print(fh,'-depsc',outputFile);
                case 'JPEG'
                    [filename, pathname] = uiputfile('*.jpeg',...
                        'Save figure as jpeg','tracePlot.jpeg');
                    if isequal(filename,0) || isequal(pathname,0) % user select cancel
                        return;
                    end
                    outputFile = fullfile(pathname,filename);
                    print(fh,'-djpeg',outputFile);
            end
        end
        
        % ---- Group Export -----
        function setupForGroupExport(obj)
            % Prepare to add data to selected group
            groupKeys = obj.vdo.getGroupKeys;
            options = ['-Select Export Group-' groupKeys 'Create New Group'];
            set(obj.handles.exportMenu,'String',options,'Value',1,...
                'Callback',@(varargin)groupSelection_Callback(obj),...
                'ToolTipString','Select a group to send data to',...
                'Enable','on');
            set(obj.exportButtons,'Callback',...
                @(hObj,~)exportGroup_Callback(obj,hObj),...
                'Enable','off',...
                'ToolTipString','Export data to selected group');
        end
        
        function groupSelection_Callback(obj)
            % User selection of group to accept data export
            menuContents = cellstr(get(obj.handles.exportMenu,'String'));
            grpKey = menuContents{get(obj.handles.exportMenu,'Value')};
            switch grpKey
                case '-Select Export Group-'
                    set(obj.exportButtons,'Enable','off');
                    return
                case 'Create New Group'
                    grpKey = char(inputdlg('Enter new group name','Create new group'));
                    if isempty(grpKey)
                        set(obj.handles.exportMenu,'Value',1);
                        set(obj.exportButtons,'Enable','off');
                        return
                    end
                    obj.vdo.createNewGroup(grpKey,'VEPMagGroupClass');
                    groupKeys = obj.vdo.getGroupKeys;
                    options = ['-Select Export Group-' groupKeys 'Create New Group'];
                    set(obj.handles.exportMenu,'String',options,...
                        'Value',find(strcmp(grpKey,options)));
                    % notify(obj.vdo,'GrpMgmtRefreshGUINeeded');
                otherwise
            end
            obj.groupKey = grpKey;
            set(obj.exportButtons,'Enable','on');
        end
        
        function exportGroup_Callback(obj,hObject)
            % Export channel data to selected group
            switch hObject
                case obj.handles.ch1ExportButton
                    hMenu = obj.handles.ch1SelMenu;
                case obj.handles.ch2ExportButton
                    hMenu = obj.handles.ch2SelMenu;
                otherwise
                    return
            end
            chStrs = get(hMenu,'String');
            chKey = chStrs{get(hMenu,'Value')};
            dso = getDataSpecifierTemplate('kidKeys');
            dso.setHierarchyLevel(1,obj.animalKey);
            dso.setHierarchyLevel(2,obj.conditionKey,true);
            dso.setHierarchyLevel(3,obj.stimKey,true);
            dso.setHierarchyLevel(4,chKey);
            addDataSpecifier(obj.vdo.groupRecords(obj.groupKey),dso);
        end
        
        % ---- Data Export -----
        function setupForDataExport(obj)
            % Prepare to export data underlying a plot
            options = {'Scores' 'Average Voltage Trace' 'Individual Traces'};
            if strcmp(get(obj.handles.exportDataButton,'Visible'),'on')
                selValue = get(obj.handles.exportMenu,'Value');
            else
                selValue = 1;
            end
            set(obj.handles.exportMenu,'String',options,'Value',selValue,...
                'Callback',@(varargin)dataExportMenu_Callback(obj),...
                'ToolTipString','Select data export type','Enable','on');
            set(obj.exportButtons,'Callback',...
                @(hObj,~)exportData_Callback(obj,hObj),...
                'ToolTipString','Select data for export');
            set(obj.handles.exportPendingCheckbox,'Value',0);
            setappdata(obj.handles.exportPendingCheckbox,...
                'exportDict',containers.Map);
            set([obj.handles.exportDataButton,obj.handles.cancelExportButton],...
                'Enable','off');
        end
        
        function dataExportMenu_Callback(obj)
            menuOptions = get(obj.handles.exportMenu,'string');
            menuSelection = menuOptions{get(obj.handles.exportMenu,'Value')};
            switch menuSelection
                case 'Individual Traces'
                    set(obj.exportButtons,...
                        'ToolTipString','Export traces');
                otherwise
                    set(obj.exportButtons,...
                        'ToolTipString','Select data for export');
            end
        end
        
        function executeDataExport_Callback(obj,hObject)
            % This function is evoked by the Save and Cancel buttons - sends data in
            % the exportDictionary to a CSV file or the desktop or, if cancel, deletes
            % the dictionary and restores selection buttons
            switch hObject
                case obj.handles.cancelExportButton
                    % Prompt the user to save before quitting or cancel
                    selection = questdlg(...
                        'Pending data exists. Delete without Saving?',...
                        'Cancel Data Export',...
                        'Delete','Cancel',...
                        'Delete');
                    if strcmp(selection,'Cancel')
                        return
                    end
                case obj.handles.exportDataButton
                    exportDict = getappdata(obj.handles.exportPendingCheckbox,'exportDict');
                    % Save Data to the base workspace
                    if ~isdeployed
                        disp('Trace Export Dictionary saved to workspace');
                        assignin('base','VDOTraceExportDict',exportDict);
                    end
                    % Package Data for Export to File
                    exportType = getappdata(obj.handles.exportPendingCheckbox,'ExportType');
                    switch exportType
                        case 'Scores'
                            keys = exportDict.keys;
                            nD = length(exportDict(keys{1}));
                            outCell = cell(length(keys)+1,nD+1);
                            outCell(1,:) = {'DataSrc' 'Mag' 'Vneg' 'Vpos' ...
                                'negLatency' 'posLatency'};
                            for iK = 1:length(keys)
                                theKey = keys{iK};
                                savedData = exportDict(theKey);
                                outCell{iK+1,1} = theKey;
                                for iD = 1:nD
                                    outCell{iK+1,iD+1} = savedData(iD);
                                end
                            end
                            defaultName = 'scoreData.csv';
                        case 'Average Voltage Trace'
                            t = exportDict('t');
                            nS = length(t);
                            exportDict.remove('t');
                            keys = exportDict.keys;
                            nK = length(keys);
                            outCell = cell(nS+1,nK+1);
                            outCell{1,1} = 't';
                            for iT = 1:nS
                                outCell{iT+1,1} = t(iT);
                            end
                            for iK = 1:length(keys)
                                theKey = keys{iK};
                                theData = exportDict(theKey);
                                outCell{1,iK+1} = theKey;
                                for iT = 1:nS
                                    outCell{iT+1,iK+1} = theData(iT);
                                end
                            end
                            defaultName = 'avgVoltTraces.csv';
                        case 'Individual Traces'
                    end
                    % Prompt for output file
                    prompt = sprintf('Export data to csv file');
                    [filename, pathname] = uiputfile('*.csv',prompt,defaultName);
                    if isequal(filename,0) || isequal(pathname,0) % user selected cancel
                        return;
                    end
                    cell2csv(outCell,filename,pathname);
            end
            rmappdata(obj.handles.exportPendingCheckbox,'exportDict');
            set([obj.handles.figureButton obj.handles.groupButton],'Enable','on');
            setupForDataExport(obj);
        end
        
        function exportData_Callback(obj,hObject)
            % Called by the ch1 and ch2 export buttons - stores data in a dictionary
            % for later export to a file or the base workspace
            
            exportOptions = cellstr(get(obj.handles.exportMenu,'String'));
            exportSelection = exportOptions{get(obj.handles.exportMenu,'Value')};
            setappdata(obj.handles.exportPendingCheckbox,'ExportType',exportSelection);
            
            switch hObject
                case obj.handles.ch1ExportButton
                    hMenu = obj.handles.ch1SelMenu;
                    scoreInd = obj.CH1ScoreInd;
                    ph = obj.CH1_workingPlot;
                case obj.handles.ch2ExportButton
                    hMenu = obj.handles.ch2SelMenu;
                    scoreInd = obj.CH2ScoreInd;
                    ph = obj.CH2_workingPlot;
            end
            
            chStrs = cellstr(get(hMenu,'String'));
            chKey = chStrs{get(hMenu,'Value')};
            
            dataKey = sprintf('%s_%s_%s_%s',obj.animalKey,...
                obj.conditionKey,obj.stimKey,chKey);
            
            exportType = getappdata(obj.handles.exportPendingCheckbox,'ExportType');
            
            % Individual traces are dumped straight to a file, not buffered to a
            % dictionary
            if strcmp(exportType,'Individual Traces')
                % Get the individual traces and put into a cell array
                chContents = cellstr(get(hMenu,'String'));
                chKey = chContents{get(hMenu,'Value')};
                obj.handles.validTracesTemplate.setHierarchyLevel(4,chKey);
                [traces,tTrace] = obj.vdo.getData(obj.handles.validTracesTemplate);
                nS = length(tTrace);
                nTr = size(traces,2);
                outCell = cell(nS+1,nTr+1);
                outCell{1,1} = 't';
                for iC = 2:nTr+1
                    outCell{1,iC} = sprintf('tr%i',iC-1);
                end
                outCell(2:end,1) = num2cell(tTrace');
                outCell(2:end,2:end) = num2cell(traces);
                % Prompt for output file
                
                defaultName = genvarname(sprintf('traces_%s_%s_%s_%s',...
                    obj.animalKey,obj.conditionKey,obj.stimKey,chKey));
                prompt = sprintf('Export traces to csv file');
                [filename, filepath] = uiputfile('*.csv',prompt,defaultName);
                if isequal(filename,0) || isequal(filepath,0) % user selected cancel
                    return;
                end
                cell2csv(outCell,filename,filepath);
                return
            end
            
            exportDict = getappdata(obj.handles.exportPendingCheckbox,'exportDict');
            if isempty(exportDict)
                % Start saving data for export - lockdown options until the data is
                % either exported or canceled
                set(obj.handles.exportPendingCheckbox,'Value',1);
                set(obj.dataExportHandles,'Enable','on')
                set(obj.handles.exportMenu,'Enable','off');
                set([obj.handles.figureButton obj.handles.groupButton],'Enable','off');
                
            end
            
            switch exportType
                case 'Scores'
                    [~, vMag,neg,pos,negLat,posLat] = getScoreStr(scoreInd);
                    exportDict(dataKey) = [vMag neg pos negLat posLat];
                case 'Average Voltage Trace'
                    if ~exportDict.isKey('t')
                        exportDict('t') = get(ph,'xdata');
                    end
                    exportDict(dataKey) = get(ph,'ydata');
                    if length(exportDict('t')) ~= length(exportDict(dataKey))
                        warnstr = sprintf(...
                            'Data length for %s does not match store time array.',...
                            dataKey);
                        warndlg(warnstr);
                    end
            end
        end
        
    end
    
end

% -------------------------------------------------------------------------
% Helper Functions
% -------------------------------------------------------------------------

function checkboxOverride(hObject)
% Prevent user from chancing the pending data export checkbox value
oldValue = get(hObject,'Value');
set(hObject,'Value',~oldValue);
end

function lims = userSelectAxes(axisString,unitsStr,defaults)
prompt = {sprintf('%s minimum (%s)',axisString,unitsStr) ...
    sprintf('%s maxiumum (%s)',axisString,unitsStr)};
windowName = 'Axes Limit Selection';
userResponse = inputdlg(prompt,windowName,1,defaults);
if isempty(userResponse)
    lims = [];
else
    lims(1) = str2double(userResponse{1});
    lims(2) = str2double(userResponse{2});
end
end