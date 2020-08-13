classdef PSDPlotClass < ManagedPlotClass
    % Extend the managed plot class to plot a voltage trace and scoring
    % tick marks
    
    properties
        psdResults
        normType
        presType
    end
    
    methods
        
        function obj = PSDPlotClass(managerObj,hAxes,...
                psdResults,lineColor)
            x = psdResults(managerObj.xDataKey);
            Pxx = 10*log10(psdResults(managerObj.pxxDataKey));
            Pxx = psdResults(managerObj.pxxDataKey);
            obj = obj@ManagedPlotClass(managerObj,hAxes,x,Pxx,lineColor);
            obj.psdResults = psdResults;
            lh = addlistener(managerObj,'ChangeDataRepresentationType',...
                @obj.changeDataRepresentation_Callback);
            obj.listenerHandles(end+1) = lh;
        end
        
        function applyNormalization(obj)
            switch obj.normType
                case 'Raw PSD'
                    
                case 'Percent Total'
                    
                case 'By Frequency'
                    
            end
        end
                
        function changeDataRepresentation_Callback(obj,varargin)
            % Switch from CDF to PDF
            obj.setXData(obj.tmdaResults(obj.manager.xDataKey));
            obj.setYData(obj.tmdaResults(obj.manager.pxxDataKey));
            if obj.xTotalShift ~= 0
                obj.xData = get(obj.lineObj,'XData');
                set(obj.lineObj,'XData',10*log10(obj.xData)+obj.xTotalShift);
            end
            
        end
        
        
    end
    
end




