% individual_ripple_visualization
% OPTIONAL - not needed for ripple detection or rejection. Plots kept vs.
% rejected ripples to check the detection results.
% Written by Liz Siefert, 11/8/2024
% updated 1/23/2025 to accumulate all ripples in a single array to be able
% to plot the average across everything for an individual
% if you want to plot individual ones too, toggle "if_plot" to 1. Otherwise
% it will just build the accumulated array.
% Run after Ripple_process_inspect.m
%
% Dependencies:
%   MATLAB R2019b or newer (tiledlayout)
%   MATLAB Statistics and Machine Learning Toolbox (nanmean)
%   functions/: spect_cmap.mat
close all
clear all

%% User paths - edit these for your machine
data_root = '~/Documents/MATLAB/ECoG/neuralData'; % same as in PAV_ecog_make_master.m
addpath(fullfile(fileparts(mfilename('fullpath')),'functions'))

RP_band = [80 120];

screenSize = get(0, 'ScreenSize');
figWidth = screenSize(3); 
figHeight = screenSize(4);    

sbj_name = input('Subject code (i.e. PAV038): ','s');
project_name = input('Project name (i.e. EOEC): ','s');
block_nums = input('Block numbers: ');%[1 2 3];
elecs = input('electrode numbers: '); %[13 14 85];
ref_type = 'WM'; % white matter reference, set in Ripple_preprocess.m

load spect_cmap.mat;

TFR_kept_ripples = [];
TFR_rejected_ripples = [];
LFP_kept_ripples = [];
LFP_rejected_ripples = [];
ripple_count = 1;
ripple_rej_count = 1;

if_plot = 0;

for bb = 1:length(block_nums) %loop through blocks
    block_name = sprintf('%03d',block_nums(bb));
    %load master file for the block directories
    load(sprintf('%s/originalData/%s/master_%s_%s_%s.mat'...
            ,data_root,sbj_name, project_name, sbj_name, block_name));
   
    for ee = 1:length(elecs)
        
        %load TF and LFP
        load(sprintf('%s/ripple_LFP_TF_DS_%s_%s_%d_%g-%g.mat',...
            master_vars.SWR_dir,block_name,ref_type,elecs(ee),RP_band(1),RP_band(2)));
        %load rejection information
        load(sprintf('%s/ripple_rej_info_%s_%s_%d_%g-%g.mat',...
            master_vars.SWR_dir,block_name,ref_type,elecs(ee),RP_band(1),RP_band(2)));
        
        reject_index = cell2mat(event_pk_rej_info(:,2))>0; % is this one kept or reject?
        ripple_events_count = length(event_pk_rej_info); % get number of events

        % Create fullscreen figure
        if if_plot
            fig1 = figure('Position', [0, 0, figWidth, figHeight],'Visible','off');
            t1 = tiledlayout(fig1, 'flow'); %tiled layout

            if sum(reject_index)>0
                fig2 = figure('Position', [0, 0, figWidth, figHeight],'Visible','off');
                t2 = tiledlayout(fig2, 'flow'); %tiled layout
            end
        end

        for rr = 1:ripple_events_count

            TFR = eventEpoch.TF(:,:,rr); %get TFR
            LFP = eventEpoch.LFP(rr,:); % get LFP

            % plot individual ripple + LFP overtop
            if reject_index(rr) == 0

                if if_plot
                    nexttile(t1);
                    imagesc(TFR);
                    axis xy
                    colormap(RB_spect_cmap);
                    xlim([0 400]);
                    xticks(0:100:400);
                    xticklabels(-200:100:200);
                    caxis([-300 300]);
                    xlabel ('Time (ms)');
                    ylabel ('Freq (Hz)');
                    hold on
                    yyaxis right;
                    plot(LFP','k','linewidth',1);
                    ylabel('Amp (\muV');
                    hold off
                end
                TFR_kept_ripples(:,:,ripple_count) = TFR;
                LFP_kept_ripples(ripple_count,:)=LFP;

                ripple_count = ripple_count+1;

            elseif reject_index(rr) == 1
                if if_plot
                    nexttile(t2);
                    imagesc(TFR);
                    axis xy
                    colormap(RB_spect_cmap);
                    xlim([0 400]);
                    xticks(0:100:400);
                    xticklabels(-200:100:200);
                    caxis([-300 300]);
                    xlabel ('Time (ms)');
                    ylabel ('Freq (Hz)');
                    hold on
                    yyaxis right;
                    plot(LFP','k','linewidth',1);
                    ylabel('Amp (\muV');
                    hold off
                end
                TFR_rejected_ripples(:,:,ripple_rej_count) = TFR;
                LFP_rejected_ripples(ripple_rej_count,:)=LFP;

                ripple_rej_count = ripple_rej_count+1;

            end

        end

        if if_plot

            title(t1,'Individual ripple events, kept')

            saveas(fig1,sprintf('%s/individual_ripples_%s_%d_kept.png',master_vars.SWR_result_dir,block_name,elecs(ee)))

            if sum(reject_index>0)
                title(t2,'Individual ripple events, rejected')
                saveas(fig2,sprintf('%s/individual_ripples_%s_%d_rejected.png',master_vars.SWR_result_dir,block_name,elecs(ee)))
            end
            close all
        end
    end

end
%% lets plot the average across all, for accumulated arrays

mean_kept = nanmean(TFR_kept_ripples,3);
mean_kept_LFP = nanmean(LFP_kept_ripples);

mean_rejected = nanmean(TFR_rejected_ripples,3);
mean_rejected_LFP = nanmean(LFP_rejected_ripples);

screenSize = get(0, 'ScreenSize');  % Get screen size [left, bottom, width, height]
figWidth = screenSize(3);           % Full screen width
figHeight = screenSize(4) / 2;       % Half screen height

figure('Position', [0, screenSize(4) - figHeight, figWidth, figHeight]);

subplot(1,2,1)
imagesc(mean_kept);
axis xy
colormap(RB_spect_cmap);
xlim([0 400]);
xticks(0:100:400);
xticklabels(-200:100:200);
caxis([-300 300]);
xlabel ('Time (ms)');
ylabel ('Freq (Hz)');
hold on
yyaxis right;
plot(mean_kept_LFP','k','linewidth',1);
ylabel('Amp (\muV');
hold off
title('mean kept ripples, all channels');

subplot(1,2,2)
imagesc(mean_rejected);
axis xy
colormap(RB_spect_cmap);
xlim([0 400]);
xticks(0:100:400);
xticklabels(-200:100:200);
caxis([-300 300]);
xlabel ('Time (ms)');
ylabel ('Freq (Hz)');
hold on
yyaxis right;
plot(mean_rejected_LFP','k','linewidth',1);
ylabel('Amp (\muV');
hold off
title('mean rejected ripples, all channels');
