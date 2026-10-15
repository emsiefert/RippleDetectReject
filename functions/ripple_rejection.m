function ripple_rejection(master_vars,ref_type,elecs,rpband)
%Wrapper function to extract handle spectra-based ripple rejection
%Moditified March 2024, Yvonne Chen

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
for ci = elecs %loop through electrodes
    load(sprintf('%s/ripple_LFP_TF_DS_%s_%s_%.d_%g-%g.mat',...
        rp_data_dir,block_name,ref_type,ci,rpband(1),rpband(2)));

    %-gather peak info from each sd trial
    % number of events
    t_num = size(eventEpoch.SD,1);
    sd_epoch = eventEpoch.SD;

    %-setup rejection parameters
    rejParam.low_cut_freq = 30;
    rejParam.RP_band=rpband;
    rejParam.noise_cut_off = 10000;
    rejParam.perc_height_cut_off = 0.5; %50 percept of the main ripple peak
    rejParam.height_cut_off = 1; %other peak higher than the main peak

    % cell mat: num of ripple event * 2
    % - each cell contain peak in SD and to keep to reject the event
    event_pk_rej_info =[];
    for it = 1:t_num %loop through trials
        event_sd = sd_epoch(it,:);
        % run individual event based spectura rejection
        [eventRejOut]=ripple_spec_reject(event_sd,rejParam);
        event_pk_rej_info{it,1} = eventRejOut;
        event_pk_rej_info{it,2} = eventRejOut.rej_code;

        %% eventRejOut.pk_info contains
        % 1 - Height of the peak
        % 2 - location of the peak (freq)
        % 3 - Width of the peak
        % 4 - prominence of the peak
        % 5- % prom of the second largest peak
        % 6 - reject code
            % rej_code:
            %   -1. excess noise
            %   -2. no ripple peak
            %   -3. ripple peak is not the prominte peak
            %   -4. noise in high frequency
            %   -5. large peaks outside ripple band
    end %end of event loop
    save(sprintf('%s/ripple_rej_info_%s_%s_%.d_%g-%g.mat',...
        rp_data_dir,block_name,ref_type,ci,rejParam.RP_band(1),rejParam.RP_band(2)),'event_pk_rej_info');
end %end of channel loop
