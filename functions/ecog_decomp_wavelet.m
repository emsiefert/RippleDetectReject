function [decomp_signal] = ecog_decomp_wavelet(data, freqs, srate, wave_num)
% Function for decomposing time series data into time-frequency
% representation (spectral decomposition) using wavelet transform. Employs 
% Morlet wavelet method (gaussian taper sine wave) to obtain the analytic 
% signal for specified frequencies (via convolution).
% Inputs:
% data - vector of time series to be decomposed
% freqs - vector of center frequencies for decomposition 
% srate - sample rate (in Hz)
% wave_num - desired number of cycles in wavelet (typically 5-10).
%
% Brett Foster, Stanford Memory Lab, Feb. 2015

%% Variables
%sample rate
srate = round(srate);

%wavelet cycles
wavelet_cycles = wave_num; 

%set wavelet window size, using lowest freq, wave number and sample rate
%high-freqs will have greater zero padding
lowest_freq = freqs(1);
max_win_size = (1/lowest_freq)*(wavelet_cycles/2);
max_win_size = max_win_size*1.1; %add 10% length to ensure zero is reached

%wavelet window
wavelet_win = -max_win_size:1/srate:max_win_size; 

%initialize variables
tmp_amplitude = zeros(length(freqs),length(data));
tmp_phase = zeros(length(freqs),length(data));

%% Decompose
% Decomposition iterates through each center frequency (wavelet), with 
% specified width, performing a convolution between the signal and complex 
% wavelet.

%loop through frequencies, build new wavelet, convolve
for fi=1:length(freqs)
    
    %initialize variables
    tmp_freq_analytic = zeros(size(data));
    tmp_sine = zeros(size(wavelet_win));
    tmp_gaus_win = zeros(size(wavelet_win));
    tmp_wavelet = zeros(size(wavelet_win));
    
        %% create sign wave at center frequency
        tmp_sine = exp(2*1i*pi*freqs(fi).*wavelet_win);
        %make gaussian window, with a width/sd = cycles
        tmp_gaus_win = exp(-wavelet_win.^2./(2*(wavelet_cycles/(2*pi*freqs(fi)))^2));
        %make wavelet as dot-product of sine wave and gaussian window
        tmp_wavelet = tmp_sine.*tmp_gaus_win;
              
        %convolve data with wavelet - remove zero padding ('same' length as input)
        %BF - pre-flip kernel, to deal with flip in conv, keeps phase ok?
        tmp_freq_analytic = conv(data,tmp_wavelet(end:-1:1), 'same'); 
            
    %extract amplitude and phase data
    %BF: apply amplitude normalization in function?    
    tmp_amplitude(fi,:) = abs(tmp_freq_analytic); 
    tmp_phase(fi,:) = angle(tmp_freq_analytic); %phase  
    
    
end %end frequency loop

%% collect data
decomp_signal.amplitude = single(tmp_amplitude);
decomp_signal.phase = tmp_phase;

%finish
