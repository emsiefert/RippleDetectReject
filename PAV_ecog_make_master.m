%% PAV_ecog_make_master.m
%
% Run once for each recorded data block. Creates the directory structure
% for the block and a master file (master_vars) with recording information
% that is used throughout the ripple pipeline.
% Output: master_vars, saved to
%   <data_root>/originalData/<sbj>/master_<project>_<sbj>_<block>.mat
%
% Dependencies: base MATLAB only
%
% [many early versions]
% Brett Foster, May 2016 - Department of Neurosurgery, BCM.
% Updates:
% September 2017 - Yvonne Chen - Department of Neurosurgery, BCM.
% Apr-May 2018 - Eleonora Bartoli
% last updated June 4 2018
%   2021 - Jan - recording naming change
%   2024 - April - added sleep recording directory setup

%% start/tidy
clear all
close all
clc

%% User paths - edit these for your machine
% raw data is expected in <raw_root>/<sbj>/iEEGData/macro/<block>/
raw_root    = '~/Documents/MATLAB/ECoG/EMU_Data';
data_root   = '~/Documents/MATLAB/ECoG/neuralData'; % processed data
result_root = '~/Documents/MATLAB/ECoG/Results';    % figures and results

%% Variables
% Taking input from keyboard
master_vars.sbj_name = input('Subject code (i.e. PAV038): ','s');
master_vars.project_name = input('Project name (i.e. EOEC): ','s');
master_vars.block_num = input('Block number (zero padded, i.e. 007): ','s'); % EMU Block num, ONE AT A TIME
master_vars.nchan = input('Number of channel recorded: '); % include extracranial if we have
master_vars.refchan = []; %ref test

master_vars.badchan = input('Bad channels: '); % add in Ref and Ground plus any from recording that know arent working
master_vars.epichan = input('Epileptic activity channels: ');
%remove redundancy of chans in bad and epi.
master_vars.epichan= setdiff(master_vars.epichan,master_vars.badchan);

%recording info
%If recording setup has changed, then input new variables, if not, use
%default
rinfo = input('Has the recording setup changed? (y/n) ','s');
%If yes - input new recording variables
if strcmp(rinfo,'y')
    master_vars.ecog_srate = input('What is the ECoG sampling rate? ');%2000;
    master_vars.compress = input('What is the ECoG downsampling factor? ');%2
%If no - use default
else
    master_vars.ecog_srate = 2000;
    master_vars.compress = 2; % downsample 2000 -> 1000 Hz
end

%% Directories for this block
sbj_name = master_vars.sbj_name;
block_name = master_vars.block_num;
master_vars.raw_dir    = sprintf('%s/%s/iEEGData/macro/%s',raw_root,sbj_name,block_name);
master_vars.Filt_dir   = sprintf('%s/FiltData/%s/%s',data_root,sbj_name,block_name); % notch filtered data
master_vars.WM_dir     = sprintf('%s/WMData/%s/%s',data_root,sbj_name,block_name);   % white matter referenced data
master_vars.Spec_dir   = sprintf('%s/SpecData/%s/%s',data_root,sbj_name,block_name); % time-frequency data
master_vars.SWR_dir    = sprintf('%s/SWRsData/%s/%s',data_root,sbj_name,block_name); % ripple detection output
master_vars.SWR_result_dir = sprintf('%s/%s_Ripple/%s/%s',result_root,master_vars.project_name,sbj_name,block_name);

dir_fields = {'Filt_dir','WM_dir','Spec_dir','SWR_dir','SWR_result_dir'};
for di = 1:length(dir_fields)
    if ~isfolder(master_vars.(dir_fields{di}))
        mkdir(master_vars.(dir_fields{di}));
    end
end
disp('***Data directory is created***')

%% The number of sample points in a channel
load(sprintf('%s/%s_Datafile_%s_ch001.mat',master_vars.raw_dir,sbj_name,block_name),'datafile');
master_vars.chanlength = length(datafile);
clear datafile

%% Saving master_vars
master_dir = sprintf('%s/originalData/%s',data_root,sbj_name);
if ~isfolder(master_dir)
    mkdir(master_dir);
end
fn = sprintf('%s/master_%s_%s_%s.mat',master_dir,master_vars.project_name,sbj_name,block_name);
save(fn,'master_vars');

disp('Master created and saved!')
