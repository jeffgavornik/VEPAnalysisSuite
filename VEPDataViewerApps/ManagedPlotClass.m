classdef ManagedPlotClass < DragableLineClass
    
    properties
        % Properties used to manage the plot
        manager
        listenerHandles
    end
    
    methods
        
        function obj = ManagedPlotClass(managerObj,hAxes,x,y,lineColor)
            obj = obj@DragableLineClass(hAxes,x,y);
            obj.setLineColor(lineColor);
            obj.manager = managerObj;
            l1 = addlistener(obj.manager,...
                'SetLineWidth',@obj.setLineWidth);
            l2 = addlistener(obj.manager,...
                'RestoreOriginalPosition',@obj.restoreOriginalPosition);
            obj.listenerHandles = [l1 l2];
            obj.setLineWidth();
        end
        
        function delete(obj)
            delete@DragableLineClass(obj);
            delete(obj.listenerHandles);
        end
        
        function setLineWidth(obj)
            setLineWidth@DragableLineClass(obj,...
                obj.manager.getLineWidth);
        end
        
        function dragPlot(obj,~,~,buttonEventType)
            if buttonEventType == 1
                obj.yDragEnabled = obj.manager.allowVerticalDragging;
                obj.xDragEnabled = obj.manager.allowHorizontalDragging;
            end
            dragPlot@DragableLineClass(obj,[],[],buttonEventType);
        end
        
    end
    
end




