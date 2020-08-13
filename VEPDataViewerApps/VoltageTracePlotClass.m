classdef VoltageTracePlotClass < ManagedPlotClass
    % Extend the managed plot class to plot a voltage trace and scoring
    % tick marks
    
    properties
        negMagPlot
        posMagPlot
        % Properties for drag events
        yNeg
        yPos
        xNeg
        xPos
    end
    
    methods
        
        function obj = VoltageTracePlotClass(managerObj,hAxes,...
                x,y,xNeg,yNeg,xPos,yPos,lineColor)
            % Plot the voltage trace
            obj = obj@ManagedPlotClass(managerObj,hAxes,x,y,lineColor);
            % Add scoring ticks
            obj.negMagPlot = DragableLineClass(hAxes,xNeg,yNeg);
            obj.negMagPlot.setLineColor(lineColor);
            obj.negMagPlot.setLineWidth(1);
            obj.negMagPlot.setVisible(obj.manager.getTickVisibility);
            obj.posMagPlot = DragableLineClass(hAxes,xPos,yPos);
            obj.posMagPlot.setLineColor(lineColor);
            obj.posMagPlot.setLineWidth(1);
            obj.posMagPlot.setVisible(obj.manager.getTickVisibility);
            
            % Setup listeners for dragging events
            l1 = addlistener(obj.manager,...
                'ToggleMagTicks',@obj.toggleTicks_Callback);
            l2 = addlistener(obj,'Grabbing',@obj.grabbing_Callback);
            l3 = addlistener(obj,'Dropping',@obj.dropping_Callback);
            obj.listenerHandles(end+[1 2 3]) = [l1 l2 l3];
        end
        
        %function delete(obj)
        %    delete@ManagedPlotClass(obj);
        %    if ishandle(obj.negMagPlot)
        %        delete([obj.negMagPlot obj.posMagPlot]);
        %    end
        %end
        
        function toggleTicks_Callback(obj,varargin)
            obj.negMagPlot.setVisible(obj.manager.getTickVisibility);
            obj.posMagPlot.setVisible(obj.manager.getTickVisibility);
        end
        
        function dropping_Callback(obj,~,eventData)
            %fprintf('%s: dropping xShift=%f yShift=%f\n',class(obj),...
            %    eventData.xShift,eventData.yShift);
            % Shift tick marks
            obj.negMagPlot.offsetYData(-eventData.yShift);
            obj.posMagPlot.offsetYData(-eventData.yShift);
            obj.negMagPlot.offsetXData(-eventData.xShift);
            obj.posMagPlot.offsetXData(-eventData.xShift);
            % Restore visibility
            if strcmp(obj.manager.getTickVisibility,'on')
                obj.negMagPlot.setVisible('on');
                obj.posMagPlot.setVisible('on');
            end
        end
        
        function grabbing_Callback(obj,varargin)
            % Hide tick marks during drag operation
            if strcmp(obj.manager.getTickVisibility,'on')
                obj.negMagPlot.setVisible('off');
                obj.posMagPlot.setVisible('off');
            end
        end
        
        function restoreOriginalPosition(obj,varargin)
            % Superclass will zero totalShift values out so make a copy
            % first
            yShift = obj.yTotalShift;
            xShift = obj.xTotalShift;
            % Call superclass
            restoreOriginalPosition@ManagedPlotClass(obj,varargin{:});
            % Shift scoring marks
            if yShift ~= 0
                obj.negMagPlot.offsetYData(-yShift);
                obj.posMagPlot.offsetYData(-yShift);
            end
            if xShift ~= 0
                obj.negMagPlot.offsetXData(-xShift);
                obj.posMagPlot.offsetXData(-xShift);
            end
        end
        
    end
    
end




