function [eventRejOut]=ripple_spec_reject(event_sd,rejParam)
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%~~~ Within Channel ripple trial rejection based on event spectrum~~~%
% 0. Reject excess noise trials
% I. keep only trials with the most prominate peak in ripple band
% II.reject trials with high prominence peaks in lower and upper frequency
% III.reject trials with more than 1 peaks in the upper freq range
% IV. reject trials with highest peak outside ripple and sharpwave
% frequency
% rej_code:
%   -0. pass spectrum check
%   -1. excess noise
%   -2. no ripple peak
%   -3. ripple peak is not the prominte peak
%   -4. noise in high frequency
%   -5. highest peak outisde ripple and SW
% Last modified - March 2024 - Yvonne Chen
%% Housekeeping
low_cut_freq =  rejParam.low_cut_freq; % sharp wave frequency cutoff
RP_band= rejParam.RP_band; %ripple band
noise_cut_off = rejParam.noise_cut_off; % noise %change cut off
perc_height_cut_off = rejParam.perc_height_cut_off; % reject other keeps with 50% of the main ripple peak
height_cut_off = rejParam.height_cut_off; 

%% Find spectra peaks
[pks,locs,w,p] = findpeaks(event_sd);
eventRejOut.pk_info = [pks(:) locs(:) w(:) p(:)];
%pks - local maxima of the peak (in %signal change) - Height of the peak
%locs - location of the peak (in frequency Hz)
%w - width of the peak
%p - peak promiance 

%% 0.Noise check 
if max(pks)>noise_cut_off %max signal change less than 10000%
    eventRejOut.event_rej = 1;
    eventRejOut.rej_code = 1;
    eventRejOut.rej_reason = 'excess noise';
    eventRejOut.RPpeak = nan(1,4);% no ripple peak info
    return
end
fprintf('pass noise check...\n')
%% - pass noise check - on to actual SD checks - %%
%pks - local maxima of the peak (in %signal change) - Height of the peak
%locs - location of the peak (in frequency Hz)
%w - width of the peak
%p - peak promiance 
%% Sort SD peak info for rejections
%rank height of the peaks above the low freq cut
%-find the peak index
pk_row = find(locs>=low_cut_freq);

%sort the remaining peaks based on their features: 
%- height from high to low
peak_ht = zeros(length(locs),1);%zero pad the height mat
peak_ht(pk_row,1) = pks(pk_row);
[~, height_rank]=sort(peak_ht,'descend');
%- prominence from high to low
peak_prom = zeros(length(locs),1);
peak_prom(pk_row,1) = p(pk_row);
[~, prom_rank]=sort(peak_prom,'descend');
%- width of the peaks
[~,width_rank]=sort(w,'descend');

%% find peak postion in the ripple band
peak_pos = find(locs>=RP_band(1) & locs<=RP_band(2));
%- and other peak info outside the ripple band
% peaks above ripple band upper bound
pk2_pos_upper = find(locs>RP_band(2));
% peaks between lower cut off and lower ripple band (30/50 - 80 Hz)
pk2_pos_lower = find(locs>=low_cut_freq & locs<=RP_band(1));
% peaks in sharp wave range <30 Hz
pk2_pos_sw = find(locs<low_cut_freq);

%% Check 1 - only single ripple peak with in ripple band 
if ~(length(peak_pos)==1)
    eventRejOut.event_rej = 1;
    eventRejOut.rej_code = 2;
    eventRejOut.rej_reason = 'no ripple peak found';
    eventRejOut.RPpeak = nan(1,4);% no ripple peak info
    return
end
fprintf('pass peak check...\n')

%% CHECK 2 - ripple peak ranks #1 for height and prominate
% when there is a ripple peak found - do additional checks
%-- peak prominence & width info
peak_prom_rank = find(prom_rank==peak_pos);
peak_height_rank = find(height_rank==peak_pos);
peak_width_rank = find(width_rank==peak_pos);

%--- Peak in ripple band prom rank == 1 & height rank == 1  to pass
% (in 30--200 Hz)
if ~(peak_prom_rank==1) || ~(peak_height_rank==1) %if height and prominence do not match
    eventRejOut.event_rej = 1;
    eventRejOut.rej_code = 3;
    eventRejOut.rej_reason = 'ripple peak height/prominence rank is not #1';
    eventRejOut.RPpeak = nan(1,4);% no ripple peak info
    return
end
fprintf('pass height & prom check...\n')
%% Check 3 - reject trials with more than 1 peaks in the upper freq range
%--- Double peaks greater than ripple upper freq. and high enegery 
% - likely epileptic spikes
if ~isempty(pk2_pos_upper) && length(pk2_pos_upper)>1
    [perc_height_diff] = max(pks(pk2_pos_upper)./pks(height_rank(1)));
    if perc_height_diff > perc_height_cut_off
        eventRejOut.event_rej = 1;
        eventRejOut.rej_code = 4;
        eventRejOut.rej_reason = 'high frequency noise';
        eventRejOut.RPpeak = nan(1,4);% no ripple peak info
        return
    end
end
fprintf('pass upper frequency check...\n')
%% CHEKC 4 - check the height of other peaks outside the ripple band
%check height of other peaks - for later channel based checking
other_pks_indx = [pk2_pos_upper pk2_pos_lower];
%find the height of other peaks and compared to ripple peak
%find the largest peak after ripple peak
perc_diff_pk_height = max(pks(other_pks_indx)./pks(height_rank(1)));
if perc_diff_pk_height>=height_cut_off
   eventRejOut.event_rej = 1;
   eventRejOut.rej_code = 5;
   eventRejOut.rej_reason = 'highest peak outisde ripple and SW';
   eventRejOut.RPpeak = nan(1,4);% no ripple peak info
   return
end

%% All checks are complete
eventRejOut.event_rej = 0;
eventRejOut.rej_code = 0;
eventRejOut.rej_reason = 'pass SD check';
%gather ripple info
eventRejOut.RPpeak = eventRejOut.pk_info(peak_pos,:);

fprintf('Individual spectra check complete...\n')





