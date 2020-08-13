classdef TMDAPlotClass < ManagedPlotClass
    % Extend the managed plot class to plot a voltage trace and scoring
    % tick marks
    
    properties
        tmdaResults
    end
    
    methods
        
        function obj = TMDAPlotClass(managerObj,hAxes,...
                tmdaResults,lineColor)
            x = tmdaResults(managerObj.xDataKey);
            f = tmdaResults(managerObj.fDataKey);
            obj = obj@ManagedPlotClass(managerObj,hAxes,x,f,lineColor);
            obj.tmdaResults = tmdaResults;
            lh = addlistener(managerObj,'ChangeDataRepresentationType',...
                @obj.changeDataRepresentation_Callback);
            obj.listenerHandles(end+1) = lh;
        end
        
        function changeDataRepresentation_Callback(obj,varargin)
            % Switch from CDF to PDF
            obj.setXData(obj.tmdaResults(obj.manager.xDataKey));
            obj.setYData(obj.tmdaResults(obj.manager.fDataKey));
            if obj.xTotalShift ~= 0
                obj.xData = get(obj.lineObj,'XData');
                set(obj.lineObj,'XData',obj.xData+obj.xTotalShift);
            end
            
        end
        
        function restoreOriginalPosition(obj,varargin)
            % Since switching from CDF to PDF changes the underlying data
            % set, can't use the superclass restore function - implement
            % shift using the saved totalShift values instead
            if obj.yTotalShift ~= 0
                obj.yData = get(obj.lineObj,'YData');
                set(obj.lineObj,'YData',obj.yData-obj.yTotalShift);
            end
            if obj.xTotalShift ~= 0
                obj.xData = get(obj.lineObj,'XData');
                set(obj.lineObj,'XData',obj.xData-obj.xTotalShift);
            end
        end
        
        
    end
    
end




