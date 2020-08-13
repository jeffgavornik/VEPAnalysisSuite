function varargout = psdTracewiseAnalysis(traces,adFreq)

useChronux = false;

if useChronux
    params.Fs=adFreq; % sampling frequency
    params.fpass=[0 500]; % band of frequencies to be kept
    params.tapers=[3 5]; % taper parameters
    params.pad=2; % pad factor for fft
    params.err=[2 0.05];
    params.trialave=1;
    [S,f,Serr]=mtspectrumc(traces,params);
    % [S,f]=mtspectrumc(traces,params);
end

% Calculate PSD
[nSamples,nTraces] = size(traces);
nfft = min([2^nextpow2(nSamples) 8192]);
Pxx = zeros(nfft/2,nTraces);
for iT = 1:nTraces
    trace = traces(:,iT);
    % trace = trace - mean(trace); % Get rid of DC
    Px = abs(fft(trace,nfft)).^2/nSamples/adFreq;
    Px = Px(1:nfft/2)';
    % [Px,freqs] = periodogram(trace,[],nfft,adFreq);
    Pxx(:,iT) = Px;
end
freqs = linspace(0,adFreq/2,nfft/2);

% Calculate the mean and smooth
muPxx = mean(Pxx,2);

sePxx = std(Pxx,0,2) / sqrt(nSamples);
% smoothWidth = round(1*length(freqs)/(freqs(end)-freqs(1))); % 1 Hz kernel
% muPxx = smooth(muPxx,smoothWidth);

% Return Results
if nargout == 1
    psdResults = containers.Map;
    psdResults('Pxx') = Pxx;
    psdResults('freqs') = freqs;
    psdResults('muPxx') = muPxx;
    if useChronux
        psdResults('S') = S;
        psdResults('f') = f;
        psdResults('Serr') = Serr;
    end
    varargout(1) = {psdResults};
else
    varargout(1) = {muPxx};
    varargout(2) = {freqs};
end

% % % 
% % Plot
% figure
% hold on
% 
% dB_muPxx = 10*log10(muPxx);
% db_sePxx = 10*log10(sePxx);
% 
% muPlus = muPxx + sigPxx;
% muMinus = muPxx - sigPxx;
% 
% plot(freqs(freqs<=500),dB_muPxx(freqs<=500));
% plot(f,10*log10(S),'r'); xlabel('Frequency Hz'); ylabel('Spectrum');
% disp(1)
% % plot(freqs,10*log10(muPlus),'r--');
% % plot(freqs,10*log10(muMinus),'g--');
% % 
% % error('beep')