function vdo_guiCallbacks(obj,src,evnt)
% Handles most GUI callbacks for VEPDataObject

%#ok<*INUSD>

handles = guihandles(obj.fh);
obj.occupado(true);

try
    switch src
        
        % File Menu Items ------------------
        
        case {handles.saveDataMenu,handles.saveDataAsMenu}
            if obj.dirtyBit || src == handles.saveDataAsMenu
                [filename, pathname] = uiputfile('*.vdo',...
                    'Enter name for VEPData Object',sprintf('%s.vdo',obj.ID));
                if ~(isequal(filename,0) || isequal(pathname,0)) % not cancel
                    outputFile = fullfile(pathname,filename);
                    obj.ID = filename(1:end-4); % remove .vdo from the filename
                    obj.prepForSave();
                    fprintf('Saving VDO as ''%s''\n',outputFile);
                    save('-v7.3',outputFile,'obj');
                    obj.dirtyBit = false;
                    notify(obj,'RefreshGUINeeded');
                end
            end
            
        case handles.archiveMenu
            if isempty(obj.ID)
                id = 'VDO';
            else
                id = obj.ID;
            end
            [filename,filepath] = uiputfile('*.txt',...
                'Enter name of text file to archive VEP Analysis contents',...
                sprintf('%s_report.txt',id));
            if ~(isequal(filename,0) || isequal(filepath,0)) % not cancel
                fid = fopen(fullfile(filepath,filename) ,'Wb');
                obj.reportContent(fid);
                fclose(fid);
            end
            
        case handles.openMenu
            [filename,filepath] = uigetfile('*.vdo','Select a VEP Data Object file',...
                'MultiSelect', 'off');
            if ~(isequal(filename,0) || isequal(filepath,0)) % not cancel
                %obj.vdo_closeGUI;
                VEPDataClass.open(filename,filepath);
            end
            
        case handles.sendToCmdWndMenu
            % Save group data in the base workspace
            varName = sprintf('vdo_%s',matlab.lang.makeValidName(obj.ID));
            fprintf('Creating variable ''%s'' in base workspace\n',varName);
            assignin('base',varName,obj);
            
        % Data Menu Items ------------------
        % Note: see vdo_populateInputFilterMenu for input filters
            
        case handles.rmDataMenu
            % Launch a GUI to select elements for removal
            obj.rmData_openGUI;
            
        case handles.autoChNameMenu
            checked = get(src,'Checked');
            if strcmp(checked,'on')
                set(src,'Checked','off');
                obj.setAutoChannelNaming(false);
            else
                set(src,'Checked','on');
                obj.setAutoChannelNaming(true);
            end
            
        case handles.manageChannelNamesMenu
            channelNames_openGUI(obj);
            
        % Following tenatively planned to be deleted
        case handles.exportDataToWksp
            error('Export data to workspace not implemented');
            
        case handles.exportDataToXL
            if isappdata(obj.fh,'CurrentDirectory')
                startDirectory = getappdata(obj.fh,'CurrentDirectory');
            else
                startDirectory = pwd;
            end
            exportDirectory = uigetfile(startDirectory);
            if ~isequal(exportDirectory,0) % not cancel
                obj.exportDataToCSV(exportDirectory);
            end
            
        % Analysis Menu Items ------------------
            
        case handles.viewerMenu
            %if isempty(varargin)
            %    VEPDataObjectViewer(obj);
            %else
            VDOTraceViewer(obj);
            %end
        case handles.tmdaMenu
            obj.performTraceOperations('TMDA')
            TraceMagDistViewer(obj);
        case handles.traceViewerMenu
            VDOTraceViewer(obj);
        case handles.psdMenu
            PSDViewer(obj);
            
            % Groups Menu Items ------------------
            
        case handles.manageGrpMenu
            obj.grpMgmt_openGUI;
        case handles.groupTraceViewerMenu
            GroupTraceViewer(obj);
        case handles.groupPSDViewerMenu
            GroupPSDViewer(obj);
        case handles.grpBarPlotMenu
            GroupDataBarPlotter(obj);
            
    end
    
catch ME
    handleError(ME,~obj.isHeadless,'GUI Callback Error');
end

obj.occupado(false)
