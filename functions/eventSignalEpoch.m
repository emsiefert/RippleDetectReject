function eventEpoch=eventSignalEpoch(event_start_time, event_end_time, event_max_time,LFP,RP_fil,TF_data,epoch_timewindow) 
% Given ripple timing info, extract ripple from LPF, ripple band fil, TF
% with epoch timing window
% Calculate spectural density during ripple.
% Created March 2024 Yvonne Chen 

%- Extract ripple info 
event_paddedtime = [event_max_time(:)-epoch_timewindow, event_max_time(:)+epoch_timewindow];
event_time = [event_start_time(:) event_end_time(:)];

%- TF data normalization        
norm_bkgrd = mean(TF_data,2);

%setup saving variables
fil_epoch=[];
lfp_epoch=[];
tf_epoch =[];
sd_epoch =[];
for ri = 1:size(event_time,1) %loop through all the detected events
    timewindow = event_paddedtime(ri,1):event_paddedtime(ri,2);
    trialtimewindow =  event_time(ri,1):event_time(ri,2);
    % check the timing of the window
    if timewindow(1)>=1 && timewindow(end)<length(LFP)
        %-LFP data
        l_epoch = LFP(timewindow);
       
        %-Bandpass fil data
        f_epoch = RP_fil(timewindow);
        
        %-TF data
        t_epoch = TF_data(:,timewindow);
        %normalized using the background signal
        t_epoch = bsxfun(@rdivide, t_epoch, norm_bkgrd);
        t_epoch = (t_epoch.*100)-100; %make it percentage change

    elseif  timewindow(1)<0 %epoch started before the recording %zero padding
        zeropad = zeros(1,abs(timewindow(1))+1);
        %-LFP data
        l_epoch =[zeropad LFP(1:timewindow(end))];
        %-Bandpass fill 
        f_epoch = [zeropad RP_fil(1:timewindow(end))];
        %-TF data
        zeropadMat = zeros(size(TF_data,1),abs(timewindow(1))+1);
        t_epoch = [zeropadMat TF_data(:,1:timewindow(end))];
        %normalized using the background signal
        t_epoch = bsxfun(@rdivide, t_epoch, norm_bkgrd);
        t_epoch = (t_epoch.*100)-100; %make it percentage change
    elseif timewindow(end)>length(LFP)%epoch ended after the recording %zero padding
        zeropad = zeros(1,abs(timewindow(end)-length(LFP)));
        %-LFP data
        l_epoch =[LFP(timewindow(1):length(LFP)) zeropad];
        %-Bandpass fill 
        f_epoch = [RP_fil(timewindow(1):length(LFP)) zeropad];
        %-TF data
        zeropadMat = zeros(size(TF_data,1),abs(timewindow(end)-length(LFP)));
        t_epoch = [TF_data(:,timewindow(1):length(LFP)) zeropadMat];
        %normalized using the background signal
        t_epoch = bsxfun(@rdivide, t_epoch, norm_bkgrd);
        t_epoch = (t_epoch.*100)-100; %make it percentage change
    end %end of the if statement

    %-SD data of only during ripple 
    if trialtimewindow(1)==0
        s_epoch = TF_data(:,trialtimewindow(2:end));
    else
        s_epoch = TF_data(:,trialtimewindow);
    end
    %normalized using the background signal
    s_epoch = bsxfun(@rdivide, s_epoch, norm_bkgrd);
    s_epoch = (s_epoch.*100)-100; %make it percentage change
    
    %-SD data
    sd_epoch = [sd_epoch;(mean(s_epoch,2))'];

    %-LFP data
    lfp_epoch = [lfp_epoch; l_epoch];
    
    %-Bandpass fil data
    fil_epoch =[fil_epoch; f_epoch];
    
    %-TF data
    tf_epoch = cat(3,tf_epoch,t_epoch);
    
end

eventEpoch.LFP = lfp_epoch;
eventEpoch.BPFil = fil_epoch;
eventEpoch.TF = tf_epoch;
eventEpoch.SD = sd_epoch;
eventEpoch.time = epoch_timewindow;