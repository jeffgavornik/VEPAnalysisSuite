function memSel_updateData_Callback(obj)

if ~isempty(obj.fh_memSel)
    handles = guidata(obj.fh_memSel);
    % Create cell arrays that will hold the keys for each layer of the
    % hiearchy and populate with current vdo contents
    animalKeys = obj.getAnimalKeys;
    animalKeysCell = cell(numel(animalKeys),2);
    animalKeysCell(:,1) = {false};
    animalKeysCell(:,2) = animalKeys';
    % Check to see if a previously selected animal still exists and, if so
    % select it again
    if isappdata(handles.figure1,'animalKey')
        animalKey = getappdata(handles.figure1,'animalKey');
        selVal = find(strcmp(animalKeys,animalKey));
        if ~isempty(selVal)
            animalKeysCell{selVal,1} = true;
            theAnimal = obj.animalRecords(animalKey);
        else
            rmappdata(handles.figure1,'animalKey');
        end
    end
    setappdata(handles.figure1,'animalKeys',animalKeysCell);
    
    % Maintain previous session selection or initialize
    initSession = true;
    if exist('theAnimal','var') && isappdata(handles.figure1,'sessionKey')
        sessionKeys = theAnimal.getKidKeys;
        sessionKey = getappdata(handles.figure1,'sessionKey');
        selVal = find(strcmp(sessionKeys,sessionKey));
        if ~isempty(selVal)
            sessionKeysCell = cell(numel(sessionKeys),2);
            sessionKeysCell(:,1) = {false};
            sessionKeysCell(:,2) = sessionKeys';
            sessionKeysCell{selVal,1} = true;
            setappdata(handles.figure1,'sessionKeys',sessionKeysCell);
            theSession = theAnimal.kids(sessionKey);
            initSession = false;
        else
            rmappdata(handles.figure1,'sessionKey');
        end
    end
    if initSession
        setappdata(handles.figure1,'sessionKeys',cell(0,2));
    end
    
    % Maintain previous stim selection or initialize
    initStim = true;
    if exist('theSession','var') && isappdata(handles.figure1,'stimKey')
        stimKeys = theSession.getKidKeys;
        stimKey = getappdata(handles.figure1,'stimKey');
        selVal = find(strcmp(stimKeys,stimKey));
        if ~isempty(selVal)
            stimKeysCell = cell(numel(stimKeys),2);
            stimKeysCell(:,1) = {false};
            stimKeysCell(:,2) = stimKeys';
            stimKeysCell{selVal,1} = true;
            setappdata(handles.figure1,'stimKeys',stimKeysCell);
            theStim = theSession.kids(stimKey);
            initStim = false;
        else
            rmappdata(handles.figure1,'stimKey');
        end
    end
    if initStim
        setappdata(handles.figure1,'stimKeys',cell(0,2));
    end
    
    % Maintain previous channel selections or initialize
    initChannels = true;
    if exist('theStim','var') && isappdata(handles.figure1,'channelKeys');
        initChannels = false;
        channelKeys = theStim.getKidKeys;
        channelKeysCell = cell(numel(channelKeys),2);
        channelKeysCell(:,1) = {false};
        channelKeysCell(:,2) = channelKeys;
        oldChannels = getappdata(handles.figure1,'channelKeys');
        oldChannelKeys = oldChannels(:,2);
        oldChannelSels = oldChannels(:,1);
        for iC = 1:numel(oldChannelKeys)
            if oldChannelSels{iC}
                oldChannelKey = oldChannelKeys{iC};
                selVal = find(strcmp(channelKeys,oldChannelKey));
                if ~isempty(selVal)
                    channelKeysCell{selVal,1} = true;
                end
            end
        end
        setappdata(handles.figure1,'channelKeys',channelKeysCell);
    end
    if initChannels
        setappdata(handles.figure1,'channelKeys',cell(0,2));
    end
    
    % Call method to draw the GUI
    obj.memSel_updateGUI_Callback();
end