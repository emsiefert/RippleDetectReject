function [eventNum, detectparam] =ripple_detection(master_vars,ref_type,elecs,RP_band)
% Wrapper function for ripple detection on white matter referenced macro data
% Saves <SWR_dir>/outRipple_<sbj>_<block>_<ref_type>_<chan>_<lo>-<hi>.mat
% Dependencies: master_var, Ripple_Detect
%% ripple band input
if nargin < 4 %use default ripple band
    RP_band = [80 120];
end
%% Housekeeping
%- Define data directory
sbj_name =  master_vars.sbj_name;
project_name = master_vars.project_name;
block_name = master_vars.block_num;
rp_data_dir = master_vars.SWR_dir;
fprintf('Processing %s %s...\n',sbj_name,project_name)

%elecs needs to be a row vector
if ~(size(elecs,1)==1)
    elecs=elecs';
end
 %- Running detection on each channel
 for ci = elecs
    %% load the data
    load(sprintf('%s/WMBPiEEG%s_%.2d.mat',master_vars.WM_dir,block_name,ci));

    data = double(analogTraces); %srate = 2k Hz

    %% Setting up detection parameters
    %-basic recording
    param.srate = master_vars.ecog_srate; %2000 Hz
    %-ripple band filter setting
    param.rpband = RP_band;%[80 120]; %ripple band range
    param.env.type = 'rms';%- 'rms' or 'analytic'
    param.env.smoothEnv= 0.02; %seconds
    param.env.smooth = 'yes';%'yes' or 'no'
    %-ripple band amplitude detection threshold
    param.criterion.amp.center = 'mean'; %'median' or 'mean'
    param.criterion.amp.var = 'std'; %'std'
    param.criterion.amp.upperCutoff = 9;
    param.criterion.amp.scale = 2.5;
    %-ripple duration detection threshold
    if round((1/min(RP_band))*3,3)<=.025
        param.criterion.dur = 0.025;
    else
        param.criterion.dur = round((1/min(RP_band))*3,3); %second
    end
    param.criterion.Mergedur = 0.5; %second - merges events with gaps shorter than this; can change to smaller values more typical (~0.015-0.05)
    param.criterion.dur_check = {'minLength','MergeLength'};

    %% Ripple detection
    %-input data and detection parameters
    detect_output = Ripple_Detect(data,param);
    eventNum = length(detect_output.EvtIndiv.startTime);
    detectparam = detect_output.detect;
    %-save ripple outputdata
    save(sprintf('%s/outRipple_%s_%s_%s_%.d_%g-%g.mat',...
        rp_data_dir,sbj_name,block_name,ref_type,ci,param.rpband(1),param.rpband(2)),'detect_output');
end %end of the channel loop
