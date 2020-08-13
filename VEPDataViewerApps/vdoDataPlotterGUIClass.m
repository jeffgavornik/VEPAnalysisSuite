classdef vdoDataPlotterGUIClass < managedListenerClass & handle
    
    properties
        % These properties should all be set by openGUI
        hGUI
        guiHandles
        animalMenu
        sessionMenu
        stimMenu
        stimSlider
    end
    
    properties (Hidden=true)
        vdo
        animalKey
        sessionKey
        stimKey
        channelKeys
        kidKeyTemplate = getDataSpecifierTemplate('kidKeys');
    end
    
    events
        AnimalSelectionChanged
        SessionSelectionChanged
        StimulusSelectionChanged
    end
    
    methods (Abstract)
        openGUI(obj);
        updateGUI(obj);
    end
    
    methods
        
        function obj = vdoDataPlotterGUIClass(vdo)
            try
                if nargin < 1 || ~isa(vdo,'VEPDataClass')
                    error('Initialization requires a VEPDataClass object');
                end
                obj.vdo = vdo;
                obj.openGUI;
                set(obj.hGUI,'CloseRequestFcn',@(src,evnt)delete(obj));
                obj.newListener(vdo,'UpdateViewers',...
                    @(src,event)vdoUpdateCallback(obj));
                obj.newListener(vdo,'CloseViewers',...
                    @(src,eventdata)delete(obj));
                obj.newListener(obj,...
                    'AnimalSelectionChanged',@sessionMenuCallback);
                obj.newListener(obj,...
                    'SessionSelectionChanged',@stimMenuCallback);
                obj.newListener(obj.stimSlider,...
                    'ContinuousValueChange',@stimSlideCallback);
            catch ME
                handleError(ME,true,'Initialization Error');
                rethrow(ME);
            end
        end
        
        function delete(obj)
            delete(obj.hGUI);
        end
        
    end
    
    methods (Access=private)
        
        function vdoUpdateCallback(obj)
            % Get the current animal selection value
            oldAnimalKeys = cellstr(get(obj.animalMenu,'String'));
            oldAnimalKey = oldAnimalKeys{get(obj.animalMenu,'Value')};
            % Get the animal keys from the VEPDataObject
            animalKeys = obj.vdo.getAnimalKeys;
            set(obj.animalMenu,'String',animalKeys);
            % If the previously selected animal exists, use it.
            % If not, use the first animal as the default selection
            animalIndex = strcmp(animalKeys,oldAnimalKey);
            if sum(animalIndex)
                set(obj.animalMenu,'Value',find(animalIndex == 1));
            else
                set(obj.animalMenu,'Value',1);
            end
            obj.animalMenuCallback();
        end
        
        % Select the Animal
        function animalMenuCallback(obj)
            % Get the current stimulus selection value
            oldSessionKeys = cellstr(get(obj.sessionMenu,'String'));
            oldSessionKey = oldSessionKeys{get(obj.sessionMenu,'Value')};
            % Populate condition menu with conditions for the selected
            % animal
            animalKeys = cellstr(get(obj.animalMenu,'String'));
            obj.animalKey = animalKeys{get(obj.animalMenu,'Value')};
            obj.kidKeyTemplate.resetDataPath();
            obj.kidKeyTemplate.setHierarchyLevel(1,obj.animalKey);
            sessionKeys = obj.vdo.getData(obj.kidKeyTemplate);
            set(obj.sessionMenu,'String',sessionKeys);
            % If the previously selected condition exists for the new
            % animal, use it. If not, use the first condition as the
            % default selection
            condIndex = strcmp(sessionKeys,oldSessionKey);
            if sum(condIndex)
                set(obj.sessionMenu,'Value',find(condIndex == 1));
            else
                set(obj.sessionMenu,'Value',1);
            end
            notify(obj,'AnimalSelectionChanged');
        end
        
        % Select the Session
        function sessionMenuCallback(obj)
            % Get the current stimulus selection value
            oldStimKeys = cellstr(get(obj.stimMenu,'String'));
            oldStimKey = oldStimKeys{get(obj.stimMenu,'Value')};
            % Populate condition menu with conditions for the selected
            % animal
            strContents = cellstr(get(obj.sessionMenu,'String'));
            obj.sessionKey = strContents{get(obj.sessionMenu,'Value')};
            obj.kidKeyTemplate.setHierarchyLevel(2,obj.sessionKey);
            stimKeys = obj.vdo.getData(obj.kidKeyTemplate);
            set(obj.stimMenu,'String',stimKeys)
            % If the previously selected stim exists for the new animal,
            % use it. If not, use the first stim as the default selection
            stimIndex = strcmp(stimKeys,oldStimKey);
            if sum(stimIndex)
                selValue = find(stimIndex == 1);
            else
                selValue = 1;
            end
            set(obj.stimMenu,'Value',selValue);
            % Setup the silder based on the current stimulus values
            nStims = length(stimKeys);
            if nStims == 1
                minVal = 0.9;
                sliderStepValues = [1 1];
            else
                minVal = 1;
                sliderStepValues = [1/(nStims-1) 1/(nStims-1)];
            end
            if min(sliderStepValues) < 0
                return;
            end
            set(obj.stimSlider,'Min',minVal,'Max',nStims,...
                'Value',selValue,'SliderStep',sliderStepValues);
            notify(obj,'SessionSelectionChanged');
        end
        
        % Select the Stimulus - post notification when complete
        function stimMenu_Callback(obj,index)
            if nargin > 1 % GUI Glue
                set(obj.stimMenu,'Value',index);
            else
                value = get(obj,'Value');
                set(obj.stimSlide,'Value',value,'UserData',value);
            end
            strContents = cellstr(get(obj.stimMenu,'String'));
            obj.stimKey = strContents{get(obj.stimMenu,'Value')};
            notify(obj,'StimulusSelectionChanged');
        end
        
        function stimSlide_listener_callBack(obj)
            index = round(get(obj,'Value'));
            if index ~= obj.stimSlider.UserData
                obj.stimSlider.UserData = index;
                set(obj.stimMenu,'value',index);
                stimMenu_Callback(obj,index);
            end
        end
        
    end
    
end