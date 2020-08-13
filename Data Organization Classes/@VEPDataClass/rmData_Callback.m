function rmData_Callback(obj,varargin)
try
    % Launch a GUI to select elements for removal
    obj.rmData_openGUI;
catch ME
    error('rmData_Callback Failed:\nReport\n%s\n',getReport(ME));
end
