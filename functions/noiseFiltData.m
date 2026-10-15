function []=noiseFiltData(master_vars)
% Filtering 60 Hz line noise (+ 2nd and 3rd harmonics) from macro channels
% Loads  <raw_dir>/<sbj>_Datafile_<block>_chNNN.mat (variable 'datafile')
% Saves  <Filt_dir>/fiEEG<block>_<chan>.mat (variable 'analogTraces')
% Dependencies:notch.m
% Writen by Mohammad Dastjerdi, Parvizi Lab, Stanford
% Revision date SEP,2009
% Modifications, Brett Foster, BCM.
% [now use channel_filt.m function for notch]
% Modified for microwire analysis and sleep analysis - YYChen 2024

block_name= master_vars.block_num;
fileDir = master_vars.raw_dir;
filename = sprintf('%s_Datafile_%s',master_vars.sbj_name,block_name);
save_dir = master_vars.Filt_dir;

%- all channels except the reference
elecs = setxor(1:master_vars.nchan,master_vars.refchan);
elecs = elecs(:)'; %row vector for looping

%-loop electrodes
for ci= elecs
    load(sprintf('%s/%s_ch%.3d.mat',fileDir,filename,ci));
     %OLD -  filtering 60 Hz
    [analogTraces]= notch(datafile, master_vars.ecog_srate, 59, 61,1);
    [analogTraces]= notch(analogTraces, master_vars.ecog_srate, 118,122,1); % Second harmonic of 60
    [analogTraces]= notch(analogTraces, master_vars.ecog_srate, 178,182,1); % Third harmonic of 60
    save(sprintf('%s/fiEEG%s_%.d.mat',save_dir,block_name,ci),'analogTraces')
    fprintf('%.2d of %.3d channels\n',ci,master_vars.nchan)

    clear analogTraces
end %end of electrodes

    fprintf('Filtering is done and saved \n')
end
