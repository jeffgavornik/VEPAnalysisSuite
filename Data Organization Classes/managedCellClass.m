classdef managedCellClass < handle
    % manage a cell array that doubles its size if the number of elements
    % exceeds its capacity
    %
    % Since it is very slow to dynamically remove elements from large cell
    % arrays, the class maintains an array of valid data indici - calling
    % a remove function actually just invalidates array elements - and only
    % valid indici are returned by the getContents method
    %
    % JG
    
    properties
        cellArray
        index
        nElements
        validIndici
    end
    
    methods
        function obj = managedCellClass(nElements)
            obj.cellArray = cell(1,nElements);
            obj.nElements = nElements;
            obj.validIndici = false(1,nElements);
            obj.index = 0;
            objectTrackerClass.startTracking(obj);
        end
        
        function delete(obj)
            % fprintf('%s deleting\n',class(obj));
            objectTrackerClass.stopTracking(obj);
        end
        
        function index = addData(obj,newData)
            obj.index = obj.index + 1;
            if obj.index > obj.nElements
                % fprintf(2,'managedCellClass: doubling size\n');
                obj.cellArray = [obj.cellArray cell(1,obj.nElements)];
                obj.validIndici = [obj.validIndici false(1,obj.nElements)];
                obj.nElements = 2*obj.nElements;
            end
            obj.cellArray{obj.index} = newData;
            obj.validIndici(obj.index) = true;
            index = obj.index;
        end
        
        function theContents = getContents(obj)
            theContents = obj.cellArray(obj.validIndici);
        end
        
        function removeData(obj,elementValue)
            for ii = 1:obj.nElements
                if isequal(elementValue,obj.cellArray{ii})
                    obj.validIndici(ii) = false;
                    return;
                end
            end
        end
        
        function removeDataAtIndex(obj,index)
            obj.validIndici(index) = false;
        end
        
    end
    
end
            
                