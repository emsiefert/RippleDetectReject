%% Ripple detection, spectral rejection, and plotting
% Run Ripple_preprocess.m for each block first.
%
% Dependencies:
%   MATLAB R2018b or newer (sgtitle)
%   MATLAB Signal Processing Toolbox (fir1, filtfilt, envelope, decimate, findpeaks)
%   MATLAB Statistics and Machine Learning Toolbox (nanmean, nanmedian, nanstd)
%   functions/: ripple_detection, Ripple_Detect, ripple_signal_extract,
%     eventSignalEpoch, ripple_rejection, ripple_spec_reject,
%     ripple_inspect_plot, spect_cmap.mat

%% Housekeeping
clear all;clc;

%% User paths - edit these for your machine
data_root = '~/Documents/MATLAB/ECoG/neuralData'; % same as in PAV_ecog_make_master.m
addpath(fullfile(fileparts(mfilename('fullpath')),'functions'))

sbj_name = input('Subject code (i.e. PAV038): ','s');
project_name = input('Project name (i.e. EOEC): ','s');
block_nums = input('Block numbers: ');
ref_type = 'WM'; % white matter reference, set in Ripple_preprocess.m

fprintf('Processing %s %s...\n',sbj_name,project_name)
for block_index = 1:length(block_nums)
    block_name   = sprintf('%03d',block_nums(block_index)); %create block name
    %Load subject info master file
    load(sprintf('%s/originalData/%s/master_%s_%s_%s.mat'...
            ,data_root,sbj_name, project_name, sbj_name, block_name));
   %% Ripple detection
   %- get the electrodes for detection
   elecs = master_vars.WM_chan_idx(:,2);
   RP_band = [80 120];
   %-run detection
   ripple_detection(master_vars,ref_type,elecs,RP_band);

    %% Ripple rejection
   % - Extract LFP, TF, SD data for ripple rejection analysis
   ripple_signal_extract(master_vars,ref_type,elecs,RP_band);
   % - spectura based rejection
   %Evaluate each trials and based on the ripple power spectra
   ripple_rejection(master_vars,ref_type,elecs,RP_band);


   %% Ripple data visualization
   [channel_event_attr]=ripple_inspect_plot(master_vars,ref_type,elecs,RP_band,'yes'); %yes to print figures
end %end of the block loop
