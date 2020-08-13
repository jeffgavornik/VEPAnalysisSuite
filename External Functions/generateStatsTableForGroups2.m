function statsTable = generateStatsTableForGroups2(vdo,...
    groupKeys,specifiedAnimalKeys,TxNames,...
    printHeader,normalize,averageAnimals,showSrc,fid,outputType,GrpLabels)

% outputType can be 'Columns' (one column for each group key) or 'Indexed'
% (one row for each sample including a column that specifies the group key)

% Modified from original version to allow for multiple treatment specifiers
% when using indexed output

if ~exist('printHeader','var') || isempty(printHeader)
    printHeader = false;
end

if ~exist('normalize','var') || isempty(normalize)
    normalize = false;
end

if ~exist('averageAnimals','var') || isempty(averageAnimals)
    averageAnimals = false;
end

if ~exist('showSrc','var') || isempty(showSrc)
    showSrc = false;
end

if ~exist('fid','var') || isempty(fid)
    fid = 1;
end

if ~exist('outputType','var') || isempty(outputType)
    outputType = 'Columns';
end

if ~exist('GrpLabels','var') || isempty(GrpLabels)
    specifiedLabels = false;
else
    specifiedLabels = true;
end

% Set a flag if a specific subset of animal keys has been designated
animalsSpecified = exist('specifiedAnimalKeys','var') && ~isempty(specifiedAnimalKeys);

% Get the groups dictionary from the VDO
groupDict = vdo.groupRecords;

% By default, use all groups
if ~exist('groupKeys','var') || isempty(groupKeys)
    groupKeys = groupDict.keys;
end

% Set a default treatment name
if ~exist('TxNames','var') || isempty(TxNames)
    TxNames = {'Unspecified'};
end

if strcmpi(outputType,'Columns')
    if isa(TxNames,'cell')
        if numel(TxNames) > 1
            fprintf(2,'Only one TxName allowed for Column output. Using first value\n');
        end
        TxName = TxNames{1};
    else
        TxName = TxNames;
    end
end

if strcmpi(outputType,'Indexed')
    if ~isa(TxNames,'cell')
        TxNames = {TxNames};
    end
end

switch lower(outputType)
    case 'columns'
        % Figure out how many groups and animals there are pre-allocate the cell
        % array with nAnimal rows and nGroup columns. Assign a column number for
        % each group.  Write the header if needed.
        nGrps = length(groupKeys);
        groupCols = containers.Map; % holds column numbers for each group
        if printHeader
            fprintf(fid,'Tx,');
            if showSrc
                fprintf(fid,'SrcID,');
            end
        end
        % allAnimals = {};
        animalCounts = containers.Map;
        for iG = 1:nGrps
            grpKey = groupKeys{iG};
            groupCols(grpKey) = 1+iG+showSrc;
            animalIDs = getGroupAnimalIDs(groupDict(groupKeys{iG}),averageAnimals);
            if animalsSpecified % ignore non-specified animals
                if ~iscell(specifiedAnimalKeys)
                    specifiedAnimalKeys = {specifiedAnimalKeys};
                end
                iKeep = false(size(animalIDs));
                for iK = 1:length(specifiedAnimalKeys);
                    theKey = specifiedAnimalKeys{iK};
                    iKeep = iKeep | strcmpi(animalIDs,theKey);
                end
                animalIDs = animalIDs(iKeep);
            end
            % Count the number of occurances of each animal in the group and save
            % the max over all groups
            for iA = 1:length(animalIDs)
                animalID = animalIDs{iA};
                newCount = sum(strcmpi(animalIDs,animalID));
                if animalCounts.isKey(animalID)
                    oldCount = animalCounts(animalID);
                else
                    oldCount = 0;
                end
                animalCounts(animalID) = max(oldCount,newCount);
            end
            if printHeader
                if specifiedLabels
                    grpKey = GrpLabels{iG};
                end
                fprintf(fid,'%s',grpKey);
                if iG ~= nGrps
                    fprintf(fid,',');
                end
            end
            %     allAnimals = {allAnimals animalIDs}; %#ok<AGROW>
        end
        if printHeader
            fprintf(fid,'\n');
        end
        % Total up the number of animal rows that will be needed and create a cell
        % array that holds all of the animal IDs with the correct count
        nRows = 0;
        animalKeys = animalCounts.keys;
        nAK = length(animalKeys);
        for iK = 1:nAK
            nOccurances = animalCounts(animalKeys{iK});
            nRows = nRows + nOccurances;
        end
        statsTable = cell(nRows,1+nGrps+showSrc);
        
        % Loop over all of the animals,populating the stats table with the
        % returned values for each group
        rowCount = 0;
        for iA = 1:nAK
            animalID = animalKeys{iA};
            count = animalCounts(animalID);
            for dataIndex = 1:count
                rowCount = rowCount + 1;
                statsTable{rowCount,1} = TxName;
                if showSrc
                    statsTable{rowCount,2} = animalID;
                end
                for iG = 1:nGrps
                    grpKey = groupKeys{iG};
                    theGrp = groupDict(grpKey);
                    grpCol = groupCols(grpKey);
                    % Get the data for the animal from the group
                    if ~normalize
                        grpData = theGrp.getDataForAnimalKey(animalID);
                    else
                        [~,grpData] = theGrp.getDataForAnimalKey(animalID);
                    end
                    if averageAnimals
                        grpData = mean(grpData);
                    end
                    if dataIndex <= length(grpData)
                        grpData = grpData(dataIndex);
                    else
                        grpData = [];
                    end
                    % Populate the table
                    statsTable{rowCount,grpCol} = grpData;
                end
            end
        end
        
    case 'indexed'
        
        % Figure out which column to put what data into and preallocate
        % cell array
        nTx = numel(TxNames);
        statsTable = cell(5000,3+nTx); % pre-allocate
        srcCol = 1;
        txCols = srcCol + [1:nTx];
        grpNameCol = max(txCols)+1;
        dataCol = grpNameCol + 1;
        
        if printHeader
            fprintf(fid,'SrcID,');
            for iT = 1:nTx
                fprintf(fid,'Tx%i,',iT);
            end
            fprintf(fid,'Grp,Data\n');
        end
        count = 1;
        for iG = 1:length(groupKeys)
            grpKey = groupKeys{iG};
            theGrp = groupDict(grpKey);
            [data normData src] = getGroupData(theGrp);
            for iD = 1:numel(src)
                parts = regexp(src{iD},'_','split');
                src{iD} = parts{1};
            end
            if averageAnimals
                animalIDs = unique(src);
                nA = length(animalIDs);
                newData = zeros(1,nA);
                for iA = 1:nA
                    ind = strcmp(src,animalIDs{iA});
                    if normalize
                        newData(iA) = mean(normData(ind));
                    else
                        newData(iA) = mean(data(ind));
                    end
                end
                if normalize
                    normData = newData;
                else
                    data = newData;
                end
                src = animalIDs;
            end
            if specifiedLabels
                grpKey = GrpLabels{iG};
            end
            for iD = 1:numel(src)
                if normalize
                    grpData = normData(iD);
                else
                    grpData = data(iD);
                end
                statsTable{count,srcCol} = src{iD};
                for iT = 1:nTx
                    statsTable{count,txCols(iT)} = TxNames{iT};
                end
                statsTable{count,grpNameCol} = grpKey;
                statsTable{count,dataCol} = grpData;
                count = count + 1;
            end
        end
        statsTable = statsTable(1:count-1,:);
        
        
    otherwise
        error('generateStatsTableForGroups: unknown output type "%s"',...
            outputType);
end

% Print out the contents of the statsTable
[rows,cols] = size(statsTable);
for row = 1:rows
    for col = 1:cols
        val = statsTable{row,col};
        if isa(val,'char')
            fprintf(fid,'%s',val);
        else
            fprintf(fid,'%f',val);
        end
        if col ~= cols
            fprintf(fid,',');
        end
    end
    fprintf(fid,'\n');
end
