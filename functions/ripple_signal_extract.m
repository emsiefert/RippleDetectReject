function ripple_signal_extract(master_vars,ref_type,elecs,rpband)
%Wrapper function to extract ripple LFP, SD signals
%Created March 2024, Yvonne Chen
%% Housekeeping
%- Define ripple data directory
sbj_name =  master_vars.sbj_name;
project_name = master_vars.project_name;
block_name = master_vars.block_num;
rp_data_dir = master_vars.SWR_dir;
rp_result_dir = master_vars.SWR_result_dir;
%elecs needs to be a row vector
if ~(size(elecs,1)==1)
    elecs=elecs';
end
epoch_timewindow = 200; %ms

%- Running detection on each channel
for ci = elecs
    fprintf('Extracting peri ripple LFP and Fil signals for channel %.d... \n',ci)
    %-load ripple output 
    load(sprintf('%s/outRipple_%s_%s_%s_%.d_%g-%g.mat',...
        rp_data_dir,sbj_name,block_name,ref_type,ci,rpband(1),rpband(2)));

    %- Ripple band filtered data & down sample to 1000 Hz
    RP_fil = decimate(detect_output.fildata, master_vars.compress,'FIR'); 
    
    %-Load LFPs
    load(sprintf('%s/WMBPiEEG%s_%.2d.mat',master_vars.WM_dir,block_name,ci));

    %- Load TF data
    load(sprintf('%s/TF_decomp_%s_%s_%s_%.d',...
        master_vars.Spec_dir, ref_type, master_vars.sbj_name, block_name,ci));        

    %- extract raw LFP data and down sample to 1000 Hz
    LFP = decimate(double(analogTraces), master_vars.compress,'FIR');

    %- extract TF_data
    TF_data = band.tf_data.amplitude;
    %convert to 1000 Hz (1ms/sample)
    event_start_time = round(detect_output.EvtIndiv.startTime/master_vars.compress);
    event_end_time = round(detect_output.EvtIndiv.endTime/master_vars.compress);
    
    if ~isfield(detect_output.EvtIndiv,'maxTime')
        event_max_time =[];
    else
        event_max_time = round(detect_output.EvtIndiv.maxTime/master_vars.compress);
    end
    %% Extract event LFP, Ripple band filtered data, and TF data

    eventEpoch = eventSignalEpoch(event_start_time,event_end_time,event_max_time,LFP,RP_fil,TF_data,epoch_timewindow);

    save(sprintf('%s/ripple_LFP_TF_DS_%s_%s_%.d_%g-%g.mat',...
        rp_data_dir,block_name,ref_type,ci,rpband(1),rpband(2)),'eventEpoch');
end
