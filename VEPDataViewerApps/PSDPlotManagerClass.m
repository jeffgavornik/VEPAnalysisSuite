classdef PSDPlotManagerClass < PlotManagerClass
    % Extend the plot manager class to manage power spectrum plots 
    
    properties
        xDataKey
        pxxDataKey
    end
    
    events
       ChangeDataRepresentationType 
    end
    
    methods
        
        function obj = PSDPlotManagerClass(xDataKey,PXXDataKey)
            obj = obj@PlotManagerClass;
            obj.enableHorizontalDragging = false;
            obj.enableVerticalDragging = false;
            obj.xDataKey = xDataKey;
            obj.pxxDataKey = PXXDataKey;
        end
        
        function addPlot(obj,handles)
            % Generate a keyString based on animal-session-stim
            keyStr = sprintf('%s_%s_%s',...
                handles.PSDTemplate.getHierarchyLevel(1),...
                handles.PSDTemplate.getHierarchyLevel(2),...
                handles.PSDTemplate.getHierarchyLevel(3));
            if(~obj.isPlotKey(keyStr)) % Don't add if already added
                LHPSDResults = getappdata(handles.figure1,'LHPSDResults');
                RHPSDResults = getappdata(handles.figure1,'RHPSDResults');
                obj.addPlotKey(keyStr);
                [theColor RGBColor HEXColor] = obj.getColor();
                selectionStr = sprintf(...
                    '<html><font color = "%s">%s</font></html>',...
                    HEXColor,keyStr);
                % Create new plots from the LH and RH data
                dpoLH = PSDPlotClass(obj,handles.LHaxes,...
                    LHPSDResults,RGBColor);
                dpoLH.makeDragable;
                dpoRH = PSDPlotClass(obj,handles.RHaxes,...
                    RHPSDResults,RGBColor);
                dpoRH.makeDragable;
                % Add the selection string to the legendBox
                oldStr = get(handles.legendBox,'String');
                if ~iscell(oldStr)
                    set(handles.legendBox,'String',{selectionStr});
                else
                    set(handles.legendBox,'String',[oldStr;{selectionStr}]);
                end
                % Bind the plots, keyStr and color
                binding = {keyStr,[dpoLH dpoRH],theColor};
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
                dpoHandles = theBinding{2};
                theColor = theBinding{3};
                % Release the plot, binding and color from the manager
                obj.releaseColor(theColor);
                obj.removePlotKey(keyStr);
                obj.releaseBinding(selectionStr);
                % Delete the plots
                delete(dpoHandles);
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
        
        function changeDataRepresentation(obj,xDataKey,fDataKey)
            notify(obj,'ChangeDataRepresentationType');
        end
        
    end
end