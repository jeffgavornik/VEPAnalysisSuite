classdef VEPScoreTickClass < DragableLineClass
   
    properties
        voltagePlotHandle % VEP being scored
        listenerHandle
        index
        vVal
        tVal
        yRange
    end
    
    events
        DropComplete
    end
    
    methods
        
        function obj = VEPScoreTickClass(plotHandle,axes,x,y)
            obj = obj@DragableLineClass(axes,x,y);
            obj.yDragEnabled = false;
            obj.setLineColor('black');
            obj.voltagePlotHandle = plotHandle;
            obj.listenerHandle = ...
                addlistener(obj,'Dropping',@obj.dropping_Callback);
        end
        
        function delete(obj)
            delete@DragableLineClass(obj);
            delete(obj.listenerHandle);
        end
        
        function setDragStyle(obj)
            % Fill the vertical extent of the axes while dragging
            obj.setYData(get(obj.hAxes,'YLim'));
            set(obj.lineObj,'LineStyle','--');
        end
        
        function setScoreInfo(obj,index,vVal,tVal)
            obj.index = index;
            obj.vVal = vVal;
            obj.tVal = tVal;
        end
        
        function dragPlot(obj,~,~,buttonEventType)
            if buttonEventType == 1
                obj.yRange = range(get(obj.voltagePlotHandle,'YData'));
                % fprintf(2,'grab size = %f\n',obj.yRange);
            end
            dragPlot@DragableLineClass(obj,[],[],buttonEventType);
        end
        
        function dropping_Callback(obj,varargin)
            % Find the voltage at the dropped location based on the
            % associated voltagePlotHandle
            tData = get(obj.voltagePlotHandle,'XData');
            vData = get(obj.voltagePlotHandle,'YData');
            droppedLocation = obj.getXData();
            tFinal = droppedLocation(1);
            if tFinal < tData(1)
                extrapval = 1;
            else
                extrapval = length(tData);
            end
            % Find the nearest valid index
            iDrop = interp1(tData,1:length(tData),...
                tFinal,'nearest',extrapval);
            % Redraw the indicator
            tDrop = tData(iDrop);
            vDrop = vData(iDrop);
            obj.setXData([1 1]*tDrop);
            % obj.setYData([-50 50]+vDrop);
            obj.setYData(vDrop + 0.5*diff(obj.y0)*[-1 1]);
            % Save the position
            obj.vVal = vDrop;
            obj.tVal = tDrop;
            obj.index = iDrop;
            % Notify that the drop is complete
            notify(obj,'DropComplete');
        end
        
        function restoreOriginalPosition(obj,varargin)
            if obj.xTotalShift ~= 0
                obj.yTotalShift = 1; % force y values to reset
            end
            restoreOriginalPosition@DragableLineClass(obj,varargin);
        end
        
        function score = getScores(obj)
            if obj.xTotalShift == 0
                score = [];
            else
                score.index = obj.index;
                score.tVal = obj.tVal;
                score.vVal = obj.vVal;
            end
        end
        
        function data = getData(obj,dataKey)
            % dataKey should be XData or YData
            data = get(obj.lineObj,dataKey);
        end
        
    end
    
end