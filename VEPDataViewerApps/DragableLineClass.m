classdef DragableLineClass < handle
    
    properties
        % Properties associated with the line object
        lineObj
        hAxes
        % Copies of the unshifted x and y data for position restoration
        x0
        y0
        % Properties used to drag the plot
        yDragEnabled
        yGrab
        yTotalShift
        yData
        xDragEnabled
        xGrab
        xTotalShift
        xData        
    end
    
    events
        Grabbing
        Dragging
        Dropping
    end
    
    methods
        
        function obj = DragableLineClass(hAxes,x,y)
            obj.hAxes = hAxes;
            hold(hAxes,'on');
            obj.lineObj = plot(hAxes,x,y);
            hold(hAxes,'off');
            obj.yTotalShift = 0;
            obj.xTotalShift = 0;
            obj.yDragEnabled = true;
            obj.xDragEnabled = true;
        end
        
        function delete(obj)
            if ishandle(obj.lineObj)
                delete([obj.lineObj]);
            end
        end
        
        % Methods to change existing plots
        function xData = getXData(obj)
            xData = get(obj.lineObj,'XData');
        end
        
        function setXData(obj,xData)
            set(obj.lineObj,'XData',xData);
        end
        
        function offsetXData(obj,offset)
            theData = get(obj.lineObj,'XData');
            set(obj.lineObj,'XData',theData+offset);
        end
        
        function yData = getYData(obj)
            yData = get(obj.lineObj,'YData');
        end
        
        function setYData(obj,yData)
            set(obj.lineObj,'YData',yData);
        end
        
        function offsetYData(obj,offset)
            theData = get(obj.lineObj,'YData');
            set(obj.lineObj,'YData',theData+offset);
        end
        
        function setLineWidth(obj,lineWidth)
            set(obj.lineObj,'LineWidth',lineWidth);
        end
        
        function setLineStyle(obj,lineStyle)
            set(obj.lineObj,'LineStyle',lineStyle);
        end
        
        function setLineColor(obj,lineColor)
            set(obj.lineObj,'Color',lineColor);
        end
        
        function setVisible(obj,visible)
            set(obj.lineObj,'Visible',visible);
        end
        
        function toggleVisible(obj)
           if strcmpi(get(obj.lineObj,'Visible'),'on')
               set(obj.lineObj,'Visible','off');
           else
               set(obj.lineObj,'Visible','on');
           end
        end
        
        % Make the plot mouse-dragable
        function makeDragable(obj)
            set(obj.lineObj,'ButtonDownFcn',...
                @(src,event)obj.dragPlot(src,event,1));
        end
        
        function makeStatic(obj)
            set(obj.lineObj,'ButtonDownFcn',[]);
        end
        
        % Drag the line
        function dragPlot(obj,~,~,buttonEventType)
            % Save the original data for restoration after drag events
            if isempty(obj.x0)
                obj.x0 = get(obj.lineObj,'XData');
                obj.y0 = get(obj.lineObj,'YData');
            end
            switch buttonEventType
                case 1 % grabbing the line
                    % Get the starting position of the line and mouse
                    % pointer
                    cp=get(obj.hAxes,'CurrentPoint');
                    obj.xGrab = cp(1,1);
                    obj.yGrab = cp(1,2);
                    obj.yData = get(obj.lineObj,'YData');
                    obj.xData = get(obj.lineObj,'XData');
                    % Make dashed line for dragging
                    obj.setDragStyle();
                    % Update mouse callback functions for the figure
                    % handles = guidata(obj.hAxes);
                    handles = guihandles(obj.hAxes);
                    hFig = handles.figure1;
                    set(hFig,'windowbuttonmotionfcn',...
                        @(src,event)obj.dragPlot(src,event,2));
                    set(hFig, 'windowbuttonupfcn',...
                        @(src,event)obj.dragPlot(src,event,3));
                    % Post dragging notification
                    notify(obj,'Grabbing');
                case 2 % dragging the line
                    cp=get(obj.hAxes,'CurrentPoint');
                    if obj.yDragEnabled
                        yShift = obj.yGrab-cp(1,2);
                        set(obj.lineObj,'YData',obj.yData-yShift);
                        %yShift = obj.yData-(obj.yGrab-cp(1,2));
                        %set(obj.lineObj,'YData',yShift);
                    else
                        yShift = 0;
                    end
                    if obj.xDragEnabled
                        xShift = obj.xGrab-cp(1,1);
                        set(obj.lineObj,'XData',obj.xData-xShift);
                        %xShift = obj.xData-(obj.xGrab-cp(1,1));
                        %set(obj.lineObj,'XData',xShift);
                    else
                        xShift = 0;
                    end
                    notify(obj,'Dragging',...
                        dragDropEventClass(xShift,yShift));
                case 3 % dropping the line
                    % Calculate the total shift over this drag based on the
                    % final mouse position
                    cp=get(obj.hAxes,'CurrentPoint');
                    if obj.xDragEnabled
                        xShift = (obj.xGrab-cp(1,1));
                        set(obj.lineObj,'XData',obj.xData-xShift);
                    else
                        xShift = 0;
                    end
                    if obj.yDragEnabled
                        yShift = (obj.yGrab-cp(1,2));
                        set(obj.lineObj,'YData',obj.yData-yShift);
                    else
                        yShift = 0;
                    end
                    % Update the total shift from the original position
                    obj.xTotalShift = obj.xTotalShift - xShift;
                    obj.yTotalShift = obj.yTotalShift - yShift;
                    % Restore solid line
                    obj.setDropStyle();
                    % Update mouse callback functions for the figure
                    % handles = guidata(obj.hAxes);
                    handles = guihandles(obj.hAxes);
                    hFig = handles.figure1;
                    set(hFig,'windowbuttonmotionfcn',[]);
                    set(hFig, 'windowbuttonupfcn',[]);
                    % Post drop notification
                    notify(obj,'Dropping',dragDropEventClass(...
                        xShift,yShift));
            end
        end
        
        function setDragStyle(obj)
            set(obj.lineObj,'LineStyle','--');
        end
        
        function setDropStyle(obj)
            set(obj.lineObj,'LineStyle','-');
        end
        
        function restoreOriginalPosition(obj,varargin)
            if obj.yTotalShift ~= 0
                set(obj.lineObj,'YData',obj.y0);
                obj.yTotalShift = 0;
            end
            if obj.xTotalShift ~= 0
                set(obj.lineObj,'XData',obj.x0);
                obj.xTotalShift = 0;
            end
        end
        
        
    end
    
end