function parameters = default_vep_parameters
% Function to create an analysis  parameter set used when reading VEP data 
% from a plexon file.  Returns a structure with the following elements:
%   tw - number of seconds following each strobbed event to extract
%   threshold - voltage threshold, in uV, used to invalidate individual 
%               traces. Note, a value of 0 will result in all traces being
%               considered valid
%   sw - defines the size of the gaussian smoothing kernel
%   negativeLatencyRange - defines the latency window, in sec, to restrict
%                          autoscore search for VEP minimum
%   maxPositiveLatency - defines upper limit on time range for finding the
%                        max positivity during autoscore

% Define the amount of time, in seconds, to extract following each
% strobed event
parameters.extractTimeWindow = 0.3;

% threshold is peak-to-peak voltage threshold, in uV, used to invalidate
% individual traces as being corrupted by noise
parameters.scrubThreshold = 3000;

% sw is the standard deviation of a normal gaussian, with units of time
% based on  sampling frequency, that is convolved with the calculated VEP
% after averaging all valid traces
parameters.smoothWidth = 4;

% The following parameters are used by the autoscore routine - the values
% were chosen heurestically
parameters.negativeLatencyRange = [0.025 0.1];
parameters.maxPositiveLatency = 0.15;

% Set the default trace mag distribution analysis type
% parameters.tmdaType = 'Tracewise';
parameters.TMDAType = 'ExactLatency';

% The following are optional channel specific overrides
parameters.extractTimeWindowOverride = containers.Map;
parameters.extractTimeWindowOverride('piezzo') = [-10 20];