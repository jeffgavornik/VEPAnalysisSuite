classdef TMDAPlotManagerClass < PlotManagerClass
    % Extend the plot manager class to manage distribution plots 
    
    properties
        fDataKey
        xDataKey
    end
    
    events
       ChangeDataRepresentationType 
    end
    
    methods
        
        function obj = TMDAPlotManagerClass(xDataKey,fDataKey)
            obj = obj@PlotManagerClass;
            obj.enableHorizontalDragging = false;
            obj.enableVerticalDragging = false;
            obj.xDataKey = xDataKey;
            obj.fDataKey = fDataKey;
        end
        
        function addPlot(obj,handles)
            % Generate a keyString based on animal-session-stim
            keyStr = sprintf('%s_%s_%s',...
                handles.TMDATemplate.getHierarchyLevel(1),...
                handles.TMDATemplate.getHierarchyLevel(2),...
                handles.TMDATemplate.getHierarchyLevel(3));
            if(~obj.isPlotKey(keyStr)) % Don't add if already added
                LHTMDAResults = getappdata(handles.figure1,'LHTMDAResults');
                RHTMDAResults = getappdata(handles.figure1,'RHTMDAResults');
                obj.addPlotKey(keyStr);
                [theColor,RGBColor,HEXColor] = obj.getColor();
                selectionStr = sprintf(...
                    '<html><font color = "%s">%s (LH=%i,RH=%i)</font></html>',...
                    HEXColor,keyStr,...
                    round(LHTMDAResults('meanKey')),...
                    round(RHTMDAResults('meanKey')));
                % Create new plots from the LH and RH data
                dpoLH = TMDAPlotClass(obj,handles.LHaxes,...
                    LHTMDAResults,RGBColor);
                dpoLH.makeDragable;
                dpoRH = TMDAPlotClass(obj,handles.RHaxes,...
                    RHTMDAResults,RGBColor);
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
            obj.fDataKey = fDataKey;
            obj.xDataKey = xDataKey;
            notify(obj,'ChangeDataRepresentationType');
        end
        
    end
end