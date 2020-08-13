function exportMenu_Callback(obj)
try
    [filename, pathname] = uiputfile('*.csv',...
        'Export Group Data',sprintf('%s.csv',obj.ID));
    if isequal(filename,0) || isequal(pathname,0) % user select canel
        return;
    else
        fid = fopen(fullfile(pathname,filename),'Wb');
        obj.exportCSVData(fid);        
        fclose(fid);
    end
    
catch ME
    fprintf('exportMenu_Callback Failed:\nReport\n%s\n',getReport(ME));
end