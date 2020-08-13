function y = exp_smooth(x,sig,pad_flag,print_flag)
% Function to smooth a function by convolution with a normalized kernel
% Returns smoothed function with same dimensions as original data
% y = gauss_smooth(x,sig,pad_flag,print_flag)
% x is the data
% sig is stddev for kernel in same units as data
% pad_flag = 1 reflect ends (default)
% pad_flag = 2 pad with first and last values
% pad_flag = 3 duplicate end data without reflection

if ~exist('sig','var') || isempty(sig)
    sig = 100;
end

if ~exist('pad_flag','var') || isempty(pad_flag)
    pad_flag = 1; % set default value
end

if ~exist('print_flag','var') || isempty(print_flag)
    print_flag = false; % set default value
end

padMult = 4; % pad width in multiples of sig

% kernel = normpdf(-sig*padMult:sig*padMult,0,sig); % kernel kernel
kernel = exp((1:2*sig*padMult+1)/sig);
kernel = kernel / sum(kernel);
% kernel = fliplr(kernel);
nx = length(x);

if pad_flag ~= 0 % pad data to avoid end effects
    np = sig*padMult; % number of elements in the pad
     if np>nx
        error('exp_smooth: pad too large for data (sig=%i,np=%i,nx=%i)',sig,np,nx);
    end
    x_pad = ones(nx + 2*np,1);
    le = np+1; % left most element of x in x_pad indici
    re = nx+le-1; % right most element of x in x_pad indici
    x_pad(le:re) = x; % copy x data into x_pad
    switch pad_flag
        case 1
            % pad by reflecting ends of x data
            x_pad(np:-1:1) = x(1) +  (x(1) - x(2:np+1)); % left pad
            x_pad(re+1:end) = x(nx) + (x(nx) - x(nx-1:-1:nx-np)); % right pad
        case 2
            % pad with first and last values
            x_pad(np:-1:1) = x(1) * ones(1,np); % left pad
            x_pad(re+1:end) = x(nx) * ones(1,np); % right pad
        case 3
            % pad duplicating the ends without reflection
            x_pad(np:-1:1) = x(2:np+1); % left pad
            x_pad(re+1:end) = x(nx-1:-1:nx-np); % right pad
    end
    y = conv(x_pad,kernel);
    y = y(2*np+1:length(y)-(2*np+1)+1);
else
    y = conv(x,kernel,'same');
%     y = y(padMult*sig:length(y)-(padMult*sig+1));
end

if print_flag
    figure
    sh = subplot(2,1,1);
    hold on
    if pad_flag ~= 0
        plot((1:numel(x_pad))-np,x_pad,'g');
    end
    plot(1:nx,x)
    plot(1:nx,y,'r')
    if pad_flag ~= 0
        xlim([(1-np) (nx+np)])
        legend('padded','original','smoothed','location','best');
    else
        xlim([1 nx])
        legend('original','smoothed','location','best');
    end
    title(sprintf('Sig = %1.2f,Pad Flag = %i',sig,pad_flag));
    subplot(2,1,2)
    plot(1:length(kernel),fliplr(kernel))
    legend('Kernel')
    xlim(get(sh,'xlim'))
end