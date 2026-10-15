function [channel_event_attr]=ripple_inspect_plot(master_vars,ref_type,elecs,rpband,fig_flag)
% Summarize kept/rejected ripples for each channel and (optionally) plot
% the average LFP, ripple band, spectrum and time-frequency of kept vs.
% rejected events. fig_flag - 'yes' to save a figure per channel to SWR_result_dir
% channel_event_attr - one row per channel:
%   {chan, ripple rate (Hz), recording length (s), # kept, # rejected,
%    [start peak end (ms), duration (ms), peak amp, peak freq] of kept ripples}

%if no fig_flag given
if nargin < 5 
    fig_flag = 'no';
end
%% Ripple data visualization    

sbj_name =  master_vars.sbj_name;
project_name = master_vars.project_name;
block_name = master_vars.block_num;
rp_data_dir = master_vars.SWR_dir;
rp_result_dir = master_vars.SWR_result_dir;

%elecs needs to be a row vector
if ~(size(elecs,1)==1)
    elecs=elecs';
end
channel_event_attr=[];
for eid = 1:length(elecs) %loop through elecs
    ci = elecs(eid);
    %% loading data
    %-load ripple detect mat
    load(sprintf('%s/outRipple_%s_%s_%s_%.d_%g-%g.mat',...
        rp_data_dir,sbj_name,block_name,ref_type,ci,rpband(1),rpband(2)));
    %-load peri-ripple singal mat
    load(sprintf('%s/ripple_LFP_TF_DS_%s_%s_%.d_%g-%g.mat',...
        rp_data_dir,block_name,ref_type,ci,rpband(1),rpband(2)));
    %-load event rej info mat
    load(sprintf('%s/ripple_rej_info_%s_%s_%.d_%g-%g.mat',...
        rp_data_dir,block_name,ref_type,ci,rpband(1),rpband(2)));

    compressFactor = master_vars.compress;
    
    %-loop through all detected events to extract ripple attribute
    num_event = length(detect_output.EvtIndiv.startTime);
    %-1.Peak time
    %-2.Duration
    %-3.Amp
    %-4.Peak Freq.
    if isfield(detect_output.EvtIndiv,'maxTime')
        peaktime = round(detect_output.EvtIndiv.maxTime./compressFactor);
        peakAmp = detect_output.EvtIndiv.maxAmp;
    else
        peaktime =[];
        peakAmp = [];
    end
    starttime = round(detect_output.EvtIndiv.startTime./compressFactor);
    endtime = round(detect_output.EvtIndiv.endTime./compressFactor);
    rippleTime = [starttime(:) peaktime(:) endtime(:)];

    duration = detect_output.EvtIndiv.duration./compressFactor;
    
    peakFreq =[];
    Rej_code =[];
    for ni= 1:num_event
        %get peak freq from SD peak processing
        pf = double(event_pk_rej_info{ni,1}.RPpeak(2));
        peakFreq = [peakFreq;pf];
        %event rejection
        rej = event_pk_rej_info{ni,2};
        Rej_code =[Rej_code; rej];
    end
    
    event_attr = [duration(:) peakAmp(:) peakFreq(:)];
    
    keep_event_idx = find(Rej_code==0);
    rej_event_idx = find(Rej_code>0);
    %calculate ripple rate
    nripple = length(keep_event_idx);
    lenSess = master_vars.chanlength/master_vars.ecog_srate; %convert to seconds
    RateHz = nripple/lenSess;

    %-Save channel event attribute
    channel_event_attr{eid,1} = ci;
    channel_event_attr{eid,2} = RateHz;
    channel_event_attr{eid,3} = lenSess;
    channel_event_attr{eid,4} = length(keep_event_idx);
    channel_event_attr{eid,5} = length(rej_event_idx);
    channel_event_attr{eid,6} = [rippleTime(keep_event_idx,:) event_attr(keep_event_idx,:)];


    if strcmp(fig_flag,'yes')
    
        load spect_cmap.mat;
        figure(1)
        set(gcf,'Position',[1400 300 1000 800]);
        set(gca,'FontSize',21);
        sgtitle(sprintf('Channel %d, ripples: %g kepted, %g rejected',ci,length(keep_event_idx),length(rej_event_idx)))
        %-LFP
        subplot(4,3,1)
        plot(mean(eventEpoch.LFP(keep_event_idx,:),1),'k','linewidth',2)
        xlim([0 400]);
        xticks(0:100:400)
        xticklabels(-200:100:200)
        ylabel('Amp (\muV')
        
        subplot(4,3,2)
        plot(mean(eventEpoch.LFP(rej_event_idx,:),1),'r','linewidth',2)
        xlim([0 400]);
        xticks(0:100:400)
        xticklabels(-200:100:200)
        ylabel('Amp (\muV')
        %-Fil
        subplot(4,3,4)
        plot(mean(eventEpoch.BPFil(keep_event_idx,:),1),'k','linewidth',2)
        xlim([0 400]);
        xticks(0:100:400)
        xticklabels(-200:100:200)
        ylabel('Amp (\muV')
        subplot(4,3,5)
        plot(mean(eventEpoch.BPFil(rej_event_idx,:),1),'r','linewidth',2)
        xlim([0 400]);
        xticks(0:100:400)
        xticklabels(-200:100:200)
        ylabel('Amp (\muV')
        %-SD
        subplot(4,3,[3 6])
        plot(mean(eventEpoch.SD(keep_event_idx,:),1),'k','linewidth',2)
        hold on
        plot(mean(eventEpoch.SD(rej_event_idx,:),1),'r','linewidth',2)
        xlabel ('Freq (Hz)')
        ylabel( '% signal change')
            
        %TF
        subplot(4,3,[7 10])
        imagesc(mean(eventEpoch.TF(:,:,keep_event_idx),3))
        axis xy
        colormap(RB_spect_cmap);
            
        xlim([0 400]);
        xticks(0:100:400)
        xticklabels(-200:100:200)
        caxis([-300 300])
        xlabel ('Time (ms)')
        ylabel ('Freq (Hz)')

        subplot(4,3,[8 11])
        imagesc(mean(eventEpoch.TF(:,:,rej_event_idx),3))
        axis xy
        colormap(RB_spect_cmap); 
        xlim([0 400]);
        xticks(0:100:400)
        xticklabels(-200:100:200)
        caxis([-300 300])
        
        xlabel ('Time (ms)')
        ylabel ('Freq (Hz)')
        
        subplot(4,3,[9 12])
        colorbar('west')
        caxis([-300 300])
        axis off
        
        pause(3)
        fdir = sprintf('%s/%s%s_ripple_attri_%s_%.d_%g-%g',...
            rp_result_dir,master_vars.sbj_name,block_name,ref_type,ci,rpband(1),rpband(2));
        set(gcf,'PaperPositionMode','auto')
        print('-f1','-dpng',fdir);
        clf
    end
end
