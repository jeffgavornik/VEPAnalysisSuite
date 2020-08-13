function vdo_addSpike2MatData_Callback(obj,varargin)
obj.occupado(true)
try
    if isappdata(obj.fh,'CurrentDirectory')
        startDirectory = getappdata(obj.fh,'CurrentDirectory');
    else
        startDirectory = pwd;
    end
    % Launch a GUI to select files
    [files,thePath] = uigetfile('*.mat','Select Spike2 .mat Files',...
        'MultiSelect', 'on',startDirectory);
    if ~isequal(files,0)
        setappdata(obj.fh,'CurrentDirectory',thePath);
        if ~iscell(files)
            files = {files};
        end
        if files{1} ~= 0
            for iFile = 1:numel(files)
                theFileName = files{iFile};
                VEPDataFileAttributesObject = ...
                    VEPDataFileAttributesClass(theFileName,thePath);
                obj.addData(VEPDataFileAttributesObject);
            end
        end
    end
catch ME
    handleError(ME,true,'vdo_addSpike2MatData_Callback Failed');
end
obj.occupado(false)
