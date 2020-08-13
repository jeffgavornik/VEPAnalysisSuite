classdef dragDropEventClass < event.EventData
    % Used for lineObj drag events by the ManagedPlotClass
    properties
        xShift;
        yShift;
    end
    methods
        function obj = dragDropEventClass(xShift,yShift)
            obj.xShift = xShift;
            obj.yShift = yShift;
        end
    end
end