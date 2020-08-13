classdef PlotManagerClass < handle
    
    properties
        legendStr % cell array of legendStr
        
        % Parameters to manage plot contents
        keyStrDict % dictionary(used as hashset) that keeps track of what's already plotted
        handleBindings % bind  plot elements together
        
        % Parameters to assign plot colors
        colorSelector % cell array of colors
        usedColors % array filled with 0s and 1s for unused/used colors
        
        % Plot parameters
        lineWidth
        enableHorizontalDragging;
        enableVerticalDragging;
    end
    
    events
        SetLineWidth
        RestoreOriginalPosition
    end
    
    methods
        
        function obj = PlotManagerClass(varargin)
            obj.colorSelector = {'blue' 'red' 'dark green' 'Orchid'...
                'cyan' 'orange' 'gray' 'spring green' 'brown'...
                'light sea green'};
            maxnum = numel(obj.colorSelector);
            obj.legendStr = cell(1,maxnum);
            obj.usedColors = zeros(1,maxnum);
            obj.keyStrDict = containers.Map;
            obj.handleBindings = containers.Map;
            obj.lineWidth = 1.5;
            obj.enableHorizontalDragging = true;
            obj.enableVerticalDragging = true;
        end
        
        % Manage plot colors ----------------------------------------------
        
        % Return an unused color
        function [theColor,rgb,hex] = getColor(obj)
            colorIndex = find(obj.usedColors==0,1);
            obj.usedColors(colorIndex) = 1;
            theColor = obj.colorSelector{colorIndex};
            rgb = RGBColor(theColor);
            hex = HEXColor(theColor);
        end
        
        % Return color back to unused pool
        function releaseColor(obj,color)
            obj.usedColors(strcmp(obj.colorSelector,color)) = 0;
        end
        
        % Manage plot contents --------------------------------------------
        
        % Check to see if a key already exists in the manager
        function bool = isPlotKey(obj,key)
            bool = obj.keyStrDict.isKey(key);
        end
        
        % Add a plot description key
        function addPlotKey(obj,key)
            obj.keyStrDict(key) = [];
        end
        
        % Remove plot description key
        function removePlotKey(obj,key)
            remove(obj.keyStrDict,key);
        end
        
        % Create a binding of disparate plot elements
        function createBinding(obj,key,boundElementsCell)
            obj.handleBindings(key) = boundElementsCell;
        end
        
        % Get a stored binding
        function theBinding = getBinding(obj,key)
            if obj.handleBindings.isKey(key)
                theBinding = obj.handleBindings(key);
            else
                theBinding = [];
            end
        end
        
        % Remove a binding
        function releaseBinding(obj,key)
            remove(obj.handleBindings,key);
        end
        
        function bindings = getBindings(obj)
            bindings = obj.handleBindings;
        end
        
        
        % Set/enable/disable plot properties ------------------------------
        
        function lineWidth = getLineWidth(obj)
            lineWidth = obj.lineWidth;
        end
        
        function setLineWidth(obj,lineWidth)
            obj.lineWidth = lineWidth;
            notify(obj,'SetLineWidth');
        end
        
        function enabled = allowHorizontalDragging(obj)
            enabled = obj.enableHorizontalDragging;
        end
        
        function enabled = allowVerticalDragging(obj)
            enabled = obj.enableVerticalDragging;
        end
        
        function toggleHorizontalDragging(obj)
            obj.enableHorizontalDragging = ~obj.enableHorizontalDragging;
        end
        
        function toggleVerticalDragging(obj)
            obj.enableVerticalDragging = ~obj.enableVerticalDragging;
        end
        
        function restorePlotsToOriginalPosition(obj)
            notify(obj,'RestoreOriginalPosition');
        end
        
    end
end