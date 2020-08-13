classdef VEPPlotManagerClass < PlotManagerClass
    % Extend the plot manager class to manage voltage traces 
    
    properties
        tickVisibility % show score tick marks
    end
    
    events
        ToggleMagTicks
    end
    
    methods
        
        function obj = VEPPlotManagerClass(varargin)
            obj = obj@PlotManagerClass;
            obj.tickVisibility = 'on';
        end
        
        function addPlot(obj,handles)
            % Generate a keyString based on animal-session-stim
            keyStr = sprintf('%s_%s_%s',...
                handles.VEPScoreTemplate.getHierarchyLevel(1),...
                handles.VEPScoreTemplate.getHierarchyLevel(2),...
                handles.VEPScoreTemplate.getHierarchyLevel(3));
            if(~obj.isPlotKey(keyStr)) % Don't add if already added
                obj.addPlotKey(keyStr);
                [theColor,RGBColor,HEXColor] = obj.getColor();
                CH1MagStr = get(handles.CH1Text,'String');
                CH2MagStr = get(handles.CH2Text,'String');
                CH1Str = 'CH1';
                CH2Str = 'CH2';
                % For VDOTraceViewer, get the channel labels as well as the
                % magnitudes
                if isfield(handles,'ch1SelMenu')
                    strContents = cellstr(get(handles.ch1SelMenu,'String'));
                    CH1Str = strContents{get(handles.ch1SelMenu,'Value')};
                end
                if isfield(handles,'ch2SelMenu')
                    strContents = cellstr(get(handles.ch2SelMenu,'String'));
                    CH2Str = strContents{get(handles.ch2SelMenu,'Value')};
                end
                selectionStr = sprintf(...
                    '<html><font color = "%s">%s (%s=%s %s=%s)</font></html>',...
                    HEXColor,keyStr,...
                    CH1Str,...
                    CH1MagStr(1:regexp(CH1MagStr,'\$','once')-1),...
                    CH2Str,...
                    CH2MagStr(1:regexp(CH2MagStr,'\$','once')-1));
                % Create new plots from the CH1 and CH2 data
                vtpoCH1 = VoltageTracePlotClass(obj,handles.CH1axes,...
                    get(handles.CH1_workingPlot,'xdata'),...
                    get(handles.CH1_workingPlot,'ydata'),...
                    handles.CH1ScoreInd.getData('xData','neg'),...
                    handles.CH1ScoreInd.getData('yData','neg'),...
                    handles.CH1ScoreInd.getData('xData','pos'),...
                    handles.CH1ScoreInd.getData('yData','pos'),...
                    RGBColor);
                vtpoCH1.makeDragable;
                vtpoCH2 = VoltageTracePlotClass(obj,handles.CH2axes,...
                    get(handles.CH2_workingPlot,'xdata'),...
                    get(handles.CH2_workingPlot,'ydata'),...
                    handles.CH2ScoreInd.getData('xData','neg'),...
                    handles.CH2ScoreInd.getData('yData','neg'),...
                    handles.CH2ScoreInd.getData('xData','pos'),...
                    handles.CH2ScoreInd.getData('yData','pos'),...
                    RGBColor);
                vtpoCH2.makeDragable;
                % Add the selection string to the legendBox
                oldStr = get(handles.legendBox,'String');
                if ~iscell(oldStr)
                    set(handles.legendBox,'String',{selectionStr});
                else
                    set(handles.legendBox,'String',[oldStr;{selectionStr}]);
                end
                % Get channel keys, if they exist - this works with
                % VDOTraceViewer
                ch1Key = '';
                if isfield(handles,'ch1SelMenu')
                    chStrs = cellstr(get(handles.ch1SelMenu,'String'));
                    ch1Key = chStrs{get(handles.ch1SelMenu,'Value')};
                end
                ch2Key = '';
                if isfield(handles,'ch2SelMenu')
                    chStrs = cellstr(get(handles.ch2SelMenu,'String'));
                    ch2Key = chStrs{get(handles.ch2SelMenu,'Value')};
                end
                chKeys = {ch1Key ch2Key};
                % Bind the plots, keyStr and color
                binding = {keyStr,[vtpoCH1 vtpoCH2],theColor,chKeys};
                obj.createBinding(selectionStr,binding);
            end
        end
        
        function deletePlot(obj,handles,selectionIndex)
            % Get the selection from the legend box
            curStr = get(handles.legendBox,'String');
            selectionStr = curStr{selectionIndex};
            % Retrieve the binding from the manager
            theBinding = obj.getBinding(selectionStr);
            if ~isempty(theBinding)
                % Unpack the bound elements
                keyStr = theBinding{1};
                vtpoHandles = theBinding{2};
                theColor = theBinding{3};
                % Release the plot, binding and color from the manager
                obj.releaseColor(theColor);
                obj.removePlotKey(keyStr);
                obj.releaseBinding(selectionStr);
                % Delete the plots
                delete(vtpoHandles);
                % Update the legend
                if (length(curStr) >= 2)
                    curStr(get(handles.legendBox,'Value')) = [];
                    set(handles.legendBox, 'String', curStr, ...
                        'Value', min(selectionIndex,length(curStr)));
                else
                    curStr = '';
                    set(handles.legendBox, 'String', curStr)
                end
            end
        end
        
        function tickVisibility = getTickVisibility(obj)
            tickVisibility = obj.tickVisibility;
        end
        
        function toggleTickVisibility(obj)
            if strcmp(obj.tickVisibility,'on')
                obj.tickVisibility = 'off';
            else
                obj.tickVisibility = 'on';
            end
            notify(obj,'ToggleMagTicks');
        end
        
        function setTickVisibility(obj,onOrOff)
            switch lower(onOrOff)
                case 'on'
                    obj.tickVisibility = 'on';
                case 'off'
                    obj.tickVisibility = 'off';
            end
            notify(obj,'ToggleMagTicks');
        end
        
    end
end