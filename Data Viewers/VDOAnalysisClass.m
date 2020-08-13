classdef (Abstract) VDOAnalysisClass < handle
    
    properties (Constant,Abstract)
        menuString
    end
    
    properties %(Hidden=true)
        vdo % VEPDataClass object
        fh % figure handle
        handles % structure of gui object handles
        listeners % respond to vdo events
    end
    
    events
        ReadyToShowGUI % Set notification after all formatting work is complete
    end
    
    methods (Abstract=true)
        
    end
    
    methods
        
        function obj = VDOAnalysisClass
            % Open the GUI
            obj.fh = openfig(class(obj),'new','invisible');
            obj.handles = guihandles(obj.fh);
            formatGUIElements(obj.handles);
            % Redirect  close request function
            set(obj.handles.figure1,'CloseRequestFcn',...
                @(hObject,eventdata)closereq_Callback(obj));
            % Setup event listeners
            obj.listeners = addlistener(obj,'ReadyToShowGUI',...
                @(src,event)revealGUIFigure(obj));
        end
        
        function closereq_Callback(obj)
            delete(obj);
        end
        
        function delete(obj)
            % Delete all event listeners
            delete(obj.listeners);
            delete(obj.fh);
        end
        
        function revealGUIFigure(obj)
            % Make the GUI visible
            set(obj.fh,'Visible','on');
        end
        
        function associateVEPDataObject(obj,vdo)
            try
                if ~isa(vdo,'VEPDataClass')
                    error('Non-VEPDataClass object associatied with %s object',...
                        class(obj));
                end
                obj.vdo = vdo;
                % Add listeners for update and close events
                obj.listeners(end+1) = addlistener(obj.vdo,'UpdateViewers',...
                    @(src,event)vdoUpdate_Callback(obj));
                obj.listeners(end+1) = addlistener(obj.vdo,'CloseViewers',...
                    @(src,eventdata)closereq_Callback(obj));
            catch ME
                handleError(ME,true,'VEPDataClass object required');
            end
        end
        
    end
        
    
end