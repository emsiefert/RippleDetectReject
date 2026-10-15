function [master_vars]= WMbipolarRef(master_vars)
% Rereferencing notch filtered depth probes to a white matter (WM) channel
% master_vars.WM_chans - cell array, one row per reference:
%   {WM reference chan, channels referenced to it}
%   i.e. {2, [4 5 6]; 10, [11 12 13]}
% Saves <WM_dir>/WMBPiEEG<block>_<chan>.mat (variable 'analogTraces')
% Adds master_vars.WM_chan_idx: [index, channel, reference chan]
% Adapted from bipolarRef.m  & commonAvgRef by BLF
% Sept 2018 - average white matter bipolar ref - YYC
% March 2019 - modified to do same probe white matter bipolar ref and multi-chan white matter avg - YYC
% May 2024 - sleep data

%% variable names
block_name= master_vars.block_num;
probes = master_vars.WM_chans;
load_dir = master_vars.Filt_dir;
save_dir = master_vars.WM_dir;

WM_chan_idx=[];

%% Create whitematter bipolar reference
fprintf('Making bipolar reference from noise filt. data\n')
ii = 1; %keep track of channel count
%Loop through each reference
for pi = 1:size(probes,1) %loop through all reference
    ref_chan = probes{pi,1}; %WM
    ci = probes{pi,2};
    if numel(ref_chan)~=1
        error('Each row of WM_chans needs exactly one white matter reference channel.')
    end

    %load ref
    load(sprintf('%s/fiEEG%s_%.d.mat',load_dir,block_name,ref_chan));
    ref = analogTraces;

    %loop through all channels
    for chan_counter = 1:length(ci)
        disp(['Reading Chan: ' sprintf('%.2d',ci(chan_counter))])

        %load chans
        load(sprintf('%s/fiEEG%s_%.d.mat',load_dir,block_name,ci(chan_counter)));
        chan1 = analogTraces;
        clear analogTraces

        %subtract chans for bipolar
        analogTraces = chan1-ref;

        %index of bipolar pairs
        WM_chan_idx(ii,:) = [ii ci(chan_counter) ref_chan];

        %save bipolar
        save(sprintf('%s/WMBPiEEG%s_%.2d.mat',save_dir,block_name,ci(chan_counter)),'analogTraces');
        ii = ii+1; %overall chan. counter
        clear chan1
    end %end of channel loop
end %of probe loop

%% Fix globals
master_vars.WM_chan_idx = WM_chan_idx; %add variable to know pairs
