classdef unitPlotter < vdoDataPlotterGUIClass
    
    properties (Constant)
        guiFile = 'unitViewer.fig';
    end
    
    methods
%         
        function obj = unitPlotter(vdo)
            obj = obj@vdoDataPlotterGUIClass(vdo);
        end
        
    end
        
        methods
            
            function openGUI(obj)
                
                try
                    obj.hGUI = openfig(obj.guiFile,'new');
                    obj.guiHandles = guihandles(obj.hGUI);
                    obj.animalMenu = obj.guiHandles.animalMenu;
                    obj.sessionMenu = obj.guiHandles.sessionMenu;
                    obj.stimMenu = obj.guiHandles.stimulusMenu;
                    obj.stimSlider = obj.guiHandles.stimSlider;
                    formatGUIElements(obj.guiHandles);
                    obj.updateGUI;
                    set(obj.hGUI,'Visible','on',...
                        'Name',class(obj));
                catch ME
                    delete(obj.hGUI);
                    rethrow(ME);
                end
                drawnow;
            end
            
            function updateGUI(obj)
                
            end
            
        end
        
end
