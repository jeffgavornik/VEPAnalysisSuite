function vdo_populateInputFilterMenu(obj)
% This method looks for all subclasses of dataFileClass in the
% InputFilters  directory, adds them to the menu and gui handles structure
% and assigns callbacks

try
  % Find the path to the InputFilters directory
  dirPath = fileparts(which('dataFileClass'));
  if isempty(dirPath)
    error('InputFilters directory is not on the path');
  end
  files = dir([dirPath '/*.m']);
  if isempty(files)
    error('No .m files in %s',dirPath);
  end
  handles = guihandles(obj.fh);
  dataMenu = handles.dataMenu;
  nF = length(files);
  count = 0;
  for iF= 1:nF
    file = files(iF);
    theClass = file.name;
    theClass = theClass(1:end-2);
    mcls = meta.class.fromName(theClass);
    %disp(superclasses(mcls.Name))
    if sum(strcmp('dataFileClass',superclasses(mcls.Name)))
        mp=mcls.PropertyList;
        [~,loc]=ismember('menuString',{mp.Name});
        menuString = mp(loc).DefaultValue;
        [~,loc]=ismember('fileExtensionString',{mp.Name});
        extStr = mp(loc).DefaultValue;
        [~,loc]=ismember('selectionPromptString',{mp.Name});
        promptStr = mp(loc).DefaultValue;
        [~,loc]=ismember('dataDirSelections',{mp.Name});
        dirSelect = mp(loc).DefaultValue;
        % disp(['vdo_populateInputFilterMenu: ' theClass ' ' menuString]);
        uimenu(dataMenu,'label',menuString,...
            'Callback',@(src,event)vdo_addData_Callback(obj,extStr,...
            promptStr,dirSelect,mcls.Name));
        count = count + 1;
    end
    
  end
  kids = get(dataMenu,'Children');
  set(dataMenu,'Children',kids([count+1:end,1:count]));
  
catch ME
  handleError(ME,~obj.isHeadless,...
    'VEPDataClass.vdo_populateInputFilterMenu');
end
