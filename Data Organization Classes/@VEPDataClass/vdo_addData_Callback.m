function vdo_addData_Callback(obj,extStr,promptStr,dirSelect,objectCreateString)
% Method that prompts the user to select data files with a specified type
% and passes selected file to a subclass of dataFileClass for type-specific
% import

% NOTE - this hardcodes plexon and openephys data types, should use
% objectCreateString to be flexible for any data source.  This would be
% passed from vdo_populateInputFilterMenu

obj.occupado(true)
%#ok<*UNRCH>
multiSelect = true; % use uigetdir2 which is undocumented but works for now
try
    if isappdata(obj.fh,'CurrentDirectory')
        startDirectory = getappdata(obj.fh,'CurrentDirectory');
    else
        startDirectory = pwd;
    end
    % Launch a GUI to select files
    if dirSelect
        if multiSelect
            paths = uigetdir2;
            for iP = 1:length(paths)
                thePath = paths{iP};
                dataFileObj = openEPhysDataClass(thePath);
                dataFileObj.registerForFileOwnerSupport(obj);
                obj.addData(dataFileObj);
            end
        else
            thePath = uigetdir([],promptStr); 
            if ~isequal(thePath,0)
                % TYPE SPECIFIC OBJECT CREATION HERE
                dataFileObj = openEPhysDataClass(thePath);
                dataFileObj.registerForFileOwnerSupport(obj);
                obj.addData(dataFileObj);
            end
        end
    else
        [files,thePath] = uigetfile(extStr,promptStr,...
            'MultiSelect', 'on',startDirectory);
        if ~isequal(files,0)
            setappdata(obj.fh,'CurrentDirectory',thePath);
            if ~iscell(files)
                files = {files};
            end
            if files{1} ~= 0
                for iFile = 1:numel(files)
                    theFileName = files{iFile};
                    % TYPE SPECIFIC OBJECT CREATION HERE
                    dataFileObj = eval(sprintf('%s(''%s'',''%s'');',...
                        objectCreateString,theFileName,thePath));
                    %dataFileObj = plxFileDataClass(theFileName,thePath);
                    dataFileObj.registerForFileOwnerSupport(obj);
                    obj.addData(dataFileObj);
                end
            end
        end
    end
catch ME
  handleError(ME,~obj.isHeadless,...
          'VEPDataClass.vdo_addData_Callback');
%     error('addPlxData_Callback Failed:\nReport\n%s\n',getReport(ME));
end
obj.occupado(false)
