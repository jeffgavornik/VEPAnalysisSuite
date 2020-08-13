classdef DistributionPlotClass < ManagedPlotClass
    % Extend the managed plot class to plot a voltage trace and scoring
    % tick marks
    
    methods
        
        function obj = DistributionPlotClass(managerObj,hAxes,...
                x,y,lineColor)
            % Plot the distribution trace
            obj = obj@ManagedPlotClass(managerObj,hAxes,x,y,lineColor);
        end
        
    end
    
end




