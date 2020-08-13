function extractPLXad
% Read field recording data from a .plx file
% [ad, ts, nSamples, ev, evTs, nEv, adFreq, adTs, adCh] = 
%             extractPLXad(filename)
%
% INPUT:
%   filename - if empty string, will use File Open dialog
% OUTPUT:
%   ad - A/D data in mV
%   ts - array of fragment timestamps (one timestamp per fragment, in
%   seconds)
%   nSamples - total number of data points per a/d channel
%   ev - array of event values
%   evTs - high resolution event timestamps
%   nEv - number of events
%   adFreq - high resolution sampling rate
%   adTs - timestamps into each returned AD channel
%   adCh - the data channel numbers for each row of ad
%
% PLX notes:
%           a/d data is stored in fragments in .plx files. Each fragment 
%           has a timestamp and some number of a/d data points. The 
%           timestamp corresponds to high resolution (based on adFreq) of 
%           the first a/d value in this fragment; these are the values in 
%           ts.  adTs fills in the gaps between each value in ts (so, 
%           there is one adTs value for each column in ad), starts at 
%           time = 0 and is based on the SlowChannel (see Plexon.h) ADFreq
%           value which is slower than adFreq.
%
% JG Notes: 
%       1. based on plx_ad.m which is stoopidly slow
%       2. function implemented as a mex function with code in
%          extractPLXad.cpp
%       3. count variable never increments so I cut out the part of the
%          code that uses it - this works fine for pure field recording but
%          might screw things up if units are being recorded?
%       4. updated to return data for multiple channels at the same time
%       5. updated to return event data and timestamps as well as ad data
%       6. non-c++ implementation in plx_ad_multichannel.m
%       7. updated c++ code to convert A/D values to mV before returning
%          based on parameters in plx header
%       8. updated c++ code to return all channels with data and fixed
%          event channel 257