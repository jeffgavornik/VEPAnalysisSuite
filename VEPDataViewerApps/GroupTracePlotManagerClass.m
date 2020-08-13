classdef GroupTracePlotManagerClass < PlotManagerClass
    % Extend the plot manager class to manage voltage traces 
    
    properties
    end
    
    events
    end
    
    methods
        
        function obj = GroupTracePlotManagerClass(varargin)
            obj = obj@PlotManagerClass;
        end
        
        function addPlot(obj,handles)
            groupKeys = cellstr(get(handles.stimMenu,'String'));
            keyStr = groupKeys{get(handles.stimMenu,'Value')};
            n = getappdata(handles.figure1,'currentN');
            keyStr = sprintf('%s (n=%i)',keyStr,n);
            if(~obj.isPlotKey(keyStr)) % Don't add if already added
                obj.addPlotKey(keyStr);
                [theColor,RGBColor,HEXColor] = obj.getColor();
                selectionStr = sprintf(...
                    '<html><font color = "%s">%s</font></html>',...
                    HEXColor,keyStr);
                % Create new plots from the CH1 and CH2 data
                thePlot = ManagedPlotClass(obj,handles.CH1axes,...
                    get(handles.CH1_workingPlot,'xdata'),...
                    get(handles.CH1_workingPlot,'ydata'),...
                    RGBColor);
                thePlot.makeDragable;
                % Add the selection string to the legendBox
                oldStr = get(handles.legendBox,'String');
                if ~iscell(oldStr)
                    set(handles.legendBox,'String',{selectionStr});
                else
                    set(handles.legendBox,'String',[oldStr;{selectionStr}]);
                end
                % Bind the plots, keyStr and color
                binding = {keyStr,thePlot,theColor};
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
                thePlot = theBinding{2};
                theColor = theBinding{3};
                % Release the plot, binding and color from the manager
                obj.releaseColor(theColor);
                obj.removePlotKey(keyStr);
                obj.releaseBinding(selectionStr);
                % Delete the plots
                delete(thePlot);
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
        
    end
end