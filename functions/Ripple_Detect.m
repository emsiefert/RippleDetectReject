function RippleOut=Ripple_Detect(data,param)
% Ripple detection code 
% Using defined ripple band and amplitude and duration checks for ripple
% detection 
% Created - 2020 - Yvonne Chen 
% Updated - 05/2023 to handle param outside the function
%         - March 2024 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Configuration of parameters:
% param.srate = 2k or 30 k %sampling rate
% param.rpband = [80 120] %ripple band range
% 
% %- ripple band filtered data envelop parameters
% param.env.type =  'rms' or 'analytic'
% param.env.smoothEnv = %in seconds - window for the envelope and for smoothing it
% param.env.smooth = %'yes' or 'no'
% 
% %- ripple detection threshold settings
% %-- Amplitude-based
% param.criterion.amp.center; %'median' or 'mean'
% param.criterion.amp.var; %'std'
% param.criterion.amp.scale;
% param.criterion.amp.upperCutoff;
%
% %-- Duration-based
% param.criterion.dur_check; %different checks 
% param.criterion.dur; %second
% param.criterion.Mergedur; %second

%% Housekeeping
%- signal info.
LFP = data;%signal
srate = param.srate; %sampling rate
RP_band = param.rpband; %ripple band range

%- ripple band filtered data envelop parameters
env_type = param.env.type;%- 'rms' or 'analytic'
env_window = param.env.smoothEnv;%in seconds
env_smooth = param.env.smooth; %'yes' or 'no'

%- ripple detection threshold settings
%-- Amplitude-based
amp_center = param.criterion.amp.center; %'median' or 'mean'
amp_var = param.criterion.amp.var; %'std'
detect_scale = param.criterion.amp.scale;
detect_upperCutoff = param.criterion.amp.upperCutoff;
%-- Duration-based
duration_check = param.criterion.dur_check; %different checks 
min_dur = param.criterion.dur; %second
merge_dur = param.criterion.Mergedur; %second
%- save the parameters to the output
RippleOut.param = param;

%% Bandpass filter data - ripple band
fprintf('Filtering data with ripple band values: %g - %g Hz \n',RP_band(1),RP_band(2));
% - FIR bandpass filter with - forward and reverse filter for zero-phase warpping 
% - length of the filter in points {default 3*fix(srate/locutoff)}
%-- Nyquist frequency
NyF = srate/2;
%-- Filter order
order = 3*fix(srate/min(RP_band))+1;
%-- FIR filter coefficients
B = fir1(order, [min(RP_band)/NyF max(RP_band)/NyF]);
A = 1;
%- Zero-phase digital filtering - two pass filter
bp_data = filtfilt(B, A, LFP')';
%- Save ripple filtered data
RippleOut.fildata = bp_data;

%% calculate envelope of bandpass filtered signal
%- find envelope of the data depending one the envelope type
env_bp_data = envelope(bp_data,round(env_window * srate),env_type);

%-envelope smoothing for detection - if 'yes'
if strcmp(env_smooth,'yes')
    env_smooth_window = param.env.smoothEnv;
    env_bp_data = smoothdata(env_bp_data,2,'movmean',round(env_smooth_window * srate)); 
    %smoothed envelope of bandpass filtered signal 
end

%% determine amplitude threshold based the amp detection parameters
fprintf('Detecting ripple with amplitude threshold... \n');

% gather data for variance threshold calculation
%- Find signal center based on sigal median or mean
switch amp_center
    case 'median'
        detect_center = nanmedian(env_bp_data,2);
    case 'mean'
        detect_center = nanmean(env_bp_data,2);
end

%- Find signal variance
%- using standard deviation 
detect_var = nanstd(env_bp_data,1,2);

%- Find amplitude detection thresholds 
% setup detection function
thresfun = @(x,y,z) x + (y .* z);
%x- center,  y- variance, z-scaler
detect_thres_val = thresfun(detect_center, detect_var, detect_scale);
detect_upperCutoff_val = thresfun(detect_center, detect_var, detect_upperCutoff);

%- upperCutoff < Inf set samples above upperCutoff to NaN and re-calculate the threshold
if param.criterion.amp.upperCutoff < Inf
    env_bp_data(env_bp_data>detect_upperCutoff_val) = nan; %replace higher to nan

    %- Find signal center based on sigal median or mean
    switch amp_center
        case 'median'
            detect_center = nanmedian(env_bp_data,2);
        case 'mean'
            detect_center = nanmean(env_bp_data,2);
    end
    %- Find signal variance
    %- using standard deviation 
    detect_var = nanstd(env_bp_data,1,2);
    %x- center,  y- variance, z-scaler
    detect_thres_val = thresfun(detect_center, detect_var, detect_scale);
end


%- Save detection threshold value to output
RippleOut.detect.ampCenter=detect_center;
RippleOut.detect.ampVar=detect_var;
RippleOut.detect.thresh=detect_thres_val;
RippleOut.detect.upperCutoff=detect_upperCutoff_val;

%% Detect event time based on amplitude threshold
detected_times = all([env_bp_data >= detect_thres_val;... %greater than threshold
                      env_bp_data <= detect_upperCutoff_val]); %less than upper cut off

tmp_detected = detected_times;

%% Discard events do not meet duration threshold 
fprintf('Checking ripple duration... \n');
for ci = 1:length(duration_check)
    %- Detect time points that amplitude threshold crossings 
    detected_diff    = diff([0 tmp_detected  0]);
    start_idx  = find(detected_diff > 0);
    end_idx  = find(detected_diff < 0)-1;
    
    check_condi = duration_check{ci};
    switch check_condi
        case 'minLength' % Discard intervals not fulfilling minimal length
            %- Find the length of each ripple and check if it shorter than the duration
            % thresholds - flag for rejection 
            tmpLength  = (end_idx-start_idx+1) < round(min_dur * srate); % length based rejection: 1-reject; 0-keep
            % Find the time points to reject 
            rm_idx = cell2mat(reshape(arrayfun(@(x,y) x:y, start_idx(tmpLength), end_idx(tmpLength), 'UniformOutput', 0),1,sum(tmpLength)));
            % remove these time points from ripple detected file
            tmp_detected(rm_idx)  = 0;
        case 'MergeLength' % Merge intervals closer than specified margin
            %- Find the length between ripples and if it's shorter than
            %merge duration 
            for evnts = 1:length(start_idx)-1
                if (start_idx(evnts+1)-end_idx(evnts)) <= round(merge_dur * srate) % gap shorter than merge duration - merge
                    %merge interals
                    tmp_detected(start_idx(evnts):end_idx(evnts+1)) = 1;
                end %end of if 
            end %end of trial for loop
    end %end of switch/case
end

%% Extract final ripple event info
detected_diff    = diff([0 tmp_detected  0]);
events_start_idx =  find(detected_diff > 0);
events_end_idx  = find(detected_diff < 0)-1;

EvtIndiv.startTime = events_start_idx; %start time in fsample
EvtIndiv.endTime = events_end_idx; %end time
EvtIndiv.duration = events_end_idx - events_start_idx; %duration
%-empty event info, kept empty if no ripples are detected
EvtIndiv.maxTime = [];
EvtIndiv.minTime = [];
EvtIndiv.maxAmp = [];
EvtIndiv.minAmp = [];
EvtIndiv.envmaxTime = [];
EvtIndiv.envmaxAmp = [];

for evtnum = 1:length(events_start_idx) %loop through events and extract event info
    curr_event = bp_data(events_start_idx(evtnum):events_end_idx(evtnum));
    %find Max and min of current event
    [minAmp,minIdx] = min(curr_event);
    [maxAmp,maxIdx] = max(curr_event);
    %-find Max and Min time
    EvtIndiv.maxTime(evtnum) = events_start_idx(evtnum)+ maxIdx-1; %time of event max
    EvtIndiv.minTime(evtnum) = events_start_idx(evtnum)+ minIdx-1; %time to event min
    %-find the value of max and min amp
    EvtIndiv.maxAmp(evtnum) = maxAmp;
    EvtIndiv.minAmp(evtnum) = minAmp;
    %find max of bp envolpe
    curr_event_env = env_bp_data(events_start_idx(evtnum):events_end_idx(evtnum));
    [envMaxAmp,envMaxIdx] = max(curr_event_env);
    EvtIndiv.envmaxTime(evtnum) = events_start_idx(evtnum)+ envMaxIdx-1; %time of event envlope max
    EvtIndiv.envmaxAmp(evtnum) = envMaxAmp;
end

%% Save to output
RippleOut.EvtIndiv = EvtIndiv;
fprintf('Ripple detecion complete, %d ripple(s) detected \n', length(events_start_idx));
