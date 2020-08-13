function isSet = checkArgsForValue(targetValue,varargin)
% Compares each string argument against the targetValue.  If any match,
% then isSet is true.  Otherwise it is false.  Ignores case.  See
% groupDataRecordsClass.getGroupData for example use.

isSet = false;
try
    if sum(strcmpi(targetValue,varargin{:}))
        isSet = true;
    end
catch ME
    fprintf(2,'checkArgsForValueFailed, returning false.  Reason:\n%s\n',...
        getReport(ME));
end