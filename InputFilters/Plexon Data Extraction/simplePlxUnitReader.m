function fileContents = simplePlxUnitReader(filenames)
% Wrapper that makes it easy to get spike data without having to remember
% all the order of output variables

%#ok<*ASGLU>


if nargin == 0
    [filenames,dirPath] = uigetfile('*.plx','Select Plexon Data File',...
        'MultiSelect', 'on',pwd);
    if isequal(filenames,0)
        fileContents = [];
        return;
    end
else
    dirPath = pwd;
end

if ~iscell(filenames)
    filenames = {filenames};
end

for ii = 1:length(filenames)
    
    
    try
        
        if exist(filenames{ii},'file') == 2
            plxFileName = filenames{ii}; % handle case that path was included in name
        else
            plxFileName = fullfile(dirPath,filenames{ii});
        end
        
        % Code adapted from the plexon SDK ----------------------------
        
        % Get file info
        [fi.OpenedFileName, fi.Version, fi.Freq, fi.Comment, ...
            fi.Trodalness, fi.NPW, fi.PreThresh, fi.SpikePeakV, ...
            fi.SpikeADResBits, fi.SlowPeakV, fi.SlowADResBits, ...
            fi.Duration, fi.DateTime] = plx_information(plxFileName);
        
        %         disp(['Opened File Name: ' OpenedFileName]);
        %         disp(['Version: ' num2str(Version)]);
        %         disp(['Frequency : ' num2str(Freq)]);
        %         disp(['Comment : ' Comment]);
        %         disp(['Date/Time : ' DateTime]);
        %         disp(['Duration : ' num2str(Duration)]);
        %         disp(['Num Pts Per Wave : ' num2str(NPW)]);
        %         disp(['Num Pts Pre-Threshold : ' num2str(PreThresh)]);
        %         % some of the information is only filled if the plx file version is >102
        %         if ( Version > 102 )
        %             if ( Trodalness < 2 )
        %                 disp('Data type : Single Electrode');
        %             elseif ( Trodalness == 2 )
        %                 disp('Data type : Stereotrode');
        %             elseif ( Trodalness == 4 )
        %                 disp('Data type : Tetrode');
        %             else
        %                 disp('Data type : Unknown');
        %             end
        %
        %             disp(['Spike Peak Voltage (mV) : ' num2str(SpikePeakV)]);
        %             disp(['Spike A/D Resolution (bits) : ' num2str(SpikeADResBits)]);
        %             disp(['Slow A/D Peak Voltage (mV) : ' num2str(SlowPeakV)]);
        %             disp(['Slow A/D Resolution (bits) : ' num2str(SlowADResBits)]);
        %         end
        
        % get some counts
        [tscounts, wfcounts, evcounts, slowcounts] = plx_info(plxFileName,1);
        
        % tscounts, wfcounts are indexed by (unit+1,channel+1)
        % tscounts(:,ch+1) is the per-unit counts for channel ch
        % sum( tscounts(:,ch+1) ) is the total wfs for channel ch (all units)
        % [nunits, nchannels] = size( tscounts )
        % To get number of nonzero units/channels, use nnz() function
        
        % gives actual number of units (including unsorted) and actual number of
        % channels plus 1
        [nunits1, nchannels1] = size( tscounts );
        
        % we will read in the timestamps of all units,channels into a two-dim cell
        % array named allts, with each cell containing the timestamps for a unit,channel.
        
        % Note that allts second dim is indexed by the 1-based channel number.
        % preallocate for speed
        
        % read spike times and package
        [fi.nspk,spk_filters] = plx_chan_filters(plxFileName);
        [~,spk_gains] = plx_chan_gains(plxFileName);
        [~,spk_threshs] = plx_chan_thresholds(plxFileName);
        [~,spk_names] = plx_chan_names(plxFileName);
        spikeDataObject = plxSpikeChannelClass;
        for ich = 1:nchannels1-1
            for iunit = 1:nunits1   % starting with unit 0 (unsorted)
                if ( tscounts( iunit , ich+1 ) > 0 )
                    % get the timestamps for this channel and unit, save
                    % all data into an easy to access format
                    [nts, ts] = plx_ts(plxFileName, ich , iunit-1 );
                    spikeDataObject.addSpikeTimes(ich,iunit-1,ts);
                    spikeDataObject.addSpikeChannelName(ich,spk_names(ich,:));
                    spikeDataObject.addSpikeThreshold(ich,spk_threshs(ich));
                    spikeDataObject.addSpikeGain(ich,spk_gains(ich));
                    spikeDataObject.addSpikeFilter(ich,spk_filters(ich));
                end
            end
        end
        
        %         % get the a/d data into a cell array also.
        %         % This is complicated by channel numbering.
        %         % The number of samples for analog channel 0 is stored at slowcounts(1).
        %         % Note that analog ch numbering starts at 0, not 1 in the data, but the
        %         % 'allad' cell array is indexed by ich+1
        %         numads = 0;
        %         [u,nslowchannels] = size( slowcounts );
        %         if ( nslowchannels > 0 )
        %             % preallocate for speed
        %             allad = cell(1,nslowchannels);
        %             for ich = 0:nslowchannels-1
        %                 if ( slowcounts(ich+1) > 0 )
        %                     [adfreq, nad, tsad, fnad, allad{ich+1}] = plx_ad(OpenedFileName, ich);
        %                     numads = numads + 1;
        %                 end
        %             end
        %         end
        %
        %         if ( numads > 0 )
        %             [nad,adfreqs] = plx_adchan_freqs(OpenedFileName);
        %             [nad,adgains] = plx_adchan_gains(OpenedFileName);
        %             [nad,adnames] = plx_adchan_names(OpenedFileName);
        %
        %             % just for fun, plot the channels with a/d data
        %             iplot = 1;
        %             numPlots = min(4, numads);
        %             for ich = 1:nslowchannels
        %                 [ nsamples, u ] = size(allad{ich});
        %                 if ( nsamples > 0 )
        %                     subplot(numPlots,1,iplot); plot(allad{ich});
        %                     iplot = iplot + 1;
        %                 end
        %                 if iplot > numPlots
        %                     break;
        %                 end
        %             end
        %         end
        
        % and finally the events
        [~,nevchannels] = size( evcounts );
        if ( nevchannels > 0 )
            % need the event chanmap to make any sense of these
            [~,evchans] = plx_event_chanmap(plxFileName);
            for iev = 1:nevchannels
                if ( evcounts(iev) > 0 )
                    evch = evchans(iev);
                    if ( evch == 257 )
                        [~, evTs, ev] = plx_event_ts(plxFileName, evch);
                    end
                end
            end
        end
        %[nev,evnames] = plx_event_names(OpenedFileName);
        
        
        % -------------------------------------------------------------
        
        % Look for metadata if it exists
        [eventValues,asciiString,eventInd] = ...
            readASCIIFromEventCodes(ev');
        ev = eventValues;
        nEv = length(eventValues);
        evTs = evTs(eventInd);
        
        % Convert meta data to stimulus definitions
        stimDefs = readStimDefsFromMetaData(asciiString);
        keys = stimDefs.keys;
        for iK = 1:length(keys)
            if sum(ev == stimDefs(keys{iK})) == 0
                stimDefs.remove(keys{iK});
            end
        end
        
        % Write everything to the return structure
        fileContents(ii).filename = plxFileName; %#ok<*AGROW>
        fileContents(ii).spikeData = spikeDataObject;
        %fileContents(ii).adData = ad;
        %fileContents(ii).adTimestamps = adTs;
        %fileContents(ii).adFreq = adFreq;
        %fileContents(ii).adChannels = adCh;
        %fileContents(ii).nSamples = nSamples;
        fileContents(ii).eventValues = ev;
        fileContents(ii).eventTimestamps = evTs;
        fileContents(ii).nEvents = nEv;
        fileContents(ii).asciiString = asciiString;
        fileContents(ii).stimDefs = stimDefs;
        fileContents(ii).fileInfo = fi;
        
    catch ME
        handleError(ME,true,'Plx File Read Error');
        fileContents = [];
        
    end
end


