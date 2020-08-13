function extractPLXEventVEPs
% Function to extract voltages for a fixed period of time following each
% presentation of all stobed events in a plexon file
%
% [packs,tvec] = extractPLXEventVEPs(ts_ev,ad_data,t,pack_length)
%
% Inputs:
% ts_ev are high res event time stamps
% ad_data is the raw voltage trace
% t are low res time points for each sample in ad_data
% pack_length is the time to extract, in seconds, following each event
% stamp
% 
% Outputs:
% packs - matrix of voltage trace following all strobed event presentations
% t_vec - time vector starting from 0 and increasing by dt
%
% Notes:
%   1. function implemented as a mex function with code in
%      extractPLXEventVEPs.cpp
%   2. function automatically centers each extracted voltage trace so that
%      mean value of the first 10 data points is zero
