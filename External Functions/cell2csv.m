function cell2csv(cellData,filename,filepath)

[rows,cols] = size(cellData);

fid = fopen(fullfile(filepath,filename) ,'Wb');

for row = 1:rows
    for col = 1:cols
        data = cellData{row,col};
        if ~isempty(data)
            switch class(data)
                case {'double' 'single'}
                    % If there is no difference between the float and int
                    % representation of the data, format print statement as an
                    % integer.  Otherwise, format as a float.
                    if ~isnan(data)
                        if data-cast(cast(data,'int32'),'double') ~= 0
                            fprintf(fid,'%g',data);
                        else
                            fprintf(fid,'%i',data);
                        end
                    end
                case 'char'
                    data = regexprep(data,',',' '); % get rid of any commas
                    fprintf(fid,'%s',data);
                otherwise
                    fprintf(fid,'nan');
            end
        end
        if col == cols
            fprintf(fid,'\n');
        else
            fprintf(fid,',');
        end
    end
end

fclose(fid);