%% Created to process macro electrode LFP for ripple detection
% Basic preprocessing - notch filter, white matter re-reference, and
% time-frequency decomposition. Run PAV_ecog_make_master.m for each block first.
%
% Dependencies:
%   MATLAB Signal Processing Toolbox (decimate)
%   functions/: noiseFiltData, notch, WMbipolarRef, ecog_tf_decomp, ecog_decomp_wavelet
% Created March 2024 - Yvonne Chen - UPenn

%% Housekeeping
clear all;clc;

%% User paths - edit these for your machine
data_root = '~/Documents/MATLAB/ECoG/neuralData'; % same as in PAV_ecog_make_master.m
%- Ripple function folder
addpath(fullfile(fileparts(mfilename('fullpath')),'functions'))

%- variable input
sbj_name = input('Subject code (i.e. PAV038): ','s');
project_name= input('Project name (i.e. EOEC): ','s');
block_nums = input('Block numbers: ');
ref_type = 'WM'; % referenced to a single white matter contact
%- white matter referecing setup, i.e. chan 2 is the reference for chans [4 5 6]
WM_ref_num = input('How many white matter reference channels?  ');
for cc = 1:WM_ref_num
    WM_chans{cc,1} = input(sprintf('White matter reference chan %g (one chan num):  ',cc));
    WM_chans{cc,2} = input(sprintf(['Channel(s) referenced to chan ' num2str(WM_chans{cc,1}) ':  ']));
end

% Loop through blocks
for block_index = 1:length(block_nums)
    block_name   = sprintf('%03d',block_nums(block_index)); %create block name
    %Load subject info master file
    masterfn = sprintf('%s/originalData/%s/master_%s_%s_%s.mat'...
            ,data_root,sbj_name, project_name, sbj_name, block_name);
    load(masterfn);

    %% Preprocessing
    %% - Notch filter -
    % Filtering 60 Hz line noise (+harmonics)
    if ~isfile(sprintf('%s/fiEEG%s_%d.mat',master_vars.Filt_dir,block_name,master_vars.nchan))
        noiseFiltData(master_vars);
    else
        fprintf('Filt data exist, skipping filter block %s...\n',block_name)
    end

    %% Reference data to white matter
    master_vars.WM_chans = WM_chans;
    [master_vars] = WMbipolarRef(master_vars);

    save(masterfn,'master_vars'); % note: new variables will be saved

    %% signal decomposition
    f_start = 1;
    f_step = 1;
    f_end = 200;
    f_width = 2;

    f_lo = f_start:f_step:f_end;
    f_hi = f_start+f_width:f_step:f_end+f_width;
    freqs = [f_lo; f_hi]';

    elecs = master_vars.WM_chan_idx(:,2);
    ecog_tf_decomp(master_vars, elecs, freqs, ref_type);
end %end of the block loop
