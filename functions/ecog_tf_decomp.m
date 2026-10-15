function []= ecog_tf_decomp(master_vars, elecs, freqs, ref_type)
%% ecog_tf_decomp.m
%
% Wrapper function for wavelet time-frequency decomposition of white
% matter referenced data. Downsamples the data before decomposition, based
% on a compression level (master_vars.compress).
% Inputs:
%   elecs    - channels to decompose
%   freqs    - two column [lo hi] frequency matrix; row means are the wavelet center freqs
%   ref_type - 'WM' (used in the file names)
% Saves <Spec_dir>/TF_decomp_<ref_type>_<sbj>_<block>_<chan>.mat (struct 'band')
%
% Dependencies: master_vars file, ecog_decomp_wavelet
%
% Brett Foster, May 2016 - Department of Neurosurgery, BCM.
% Yvonne Chen, March 2020 - BCM - edited to add WM referencing
% Yvonne Chen, March 2024 - edited to add microwire
%% variables
srate_raw = round(master_vars.ecog_srate);
srate_comp = round(srate_raw/master_vars.compress);
comp = master_vars.compress;
center_freqs = mean(freqs, 2); %this is for wavelet. Single vector of center freqs.

%-Define file dir
block_name= master_vars.block_num;
save_dir = master_vars.Spec_dir;

%% Loop - load data, downsample, and filter/normalize
fprintf('... Decomposing data ...\n');

for ee = 1:length(elecs)
    ci = elecs(ee);
    fprintf('Processing electrode %.d\n',ci);

    %create structure for band info
    band=[];
    band.elec= ci;
    band.block_name= block_name;

    %% load data and downsample
    load(sprintf('%s/WMBPiEEG%s_%.2d.mat',master_vars.WM_dir,block_name,ci));

    %down sample (based on current srate and compression factor (divison))
    signal = double(analogTraces);
    clear analogTraces
    decomp_input = decimate(signal,comp,'FIR');
    clear signal

    %% Time/frequency decomposition
    %wavelet transform; takes center freqs. Currently set for 7
    %cycles.
    band.freq = center_freqs;
    [tf_data] = ecog_decomp_wavelet(decomp_input, center_freqs, srate_comp, 7);

    %add t/f decomp. to band data structure
    %data contains amplitude matrix (phase is optional, see ecog_decomp_wavelet)
    band.tf_data = tf_data;

    %% save band structure
    size_check = whos('band');
    if size_check.bytes > 2e+9 %greater than 2GB
        save(sprintf('%s/TF_decomp_%s_%s_%s_%.d',save_dir,ref_type,master_vars.sbj_name, block_name,ci),'band','-v7.3');
    else
        save(sprintf('%s/TF_decomp_%s_%s_%s_%.d',save_dir,ref_type,master_vars.sbj_name, block_name,ci),'band');
    end
    clear decomp_input
end %end of electrode loop
end
