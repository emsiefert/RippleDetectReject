# RippleDetectReject

MATLAB pipeline for detecting hippocampal ripples in intracranial (macro electrode) recordings and rejecting false positives based on each event's power spectrum. It processes one recording block at a time. Channels are notch filtered, referenced to a white matter contact and downsampled. Ripples are then detected in the 80–120 Hz band, and each detected event is kept or rejected based on its spectrum.

The example used throughout is an eyes open / eyes closed (`EOEC`) task block, but nothing in the pipeline depends on the task.

## Requirements

- MATLAB R2018b or newer (R2019b or newer for `visualize_individual_ripples.m`)
- Signal Processing Toolbox: `fir1`, `filtfilt`, `envelope`, `decimate`, `findpeaks`
- Statistics and Machine Learning Toolbox: `nanmean`, `nanmedian`, `nanstd`

## Folder layout

```
PAV_ecog_make_master.m          1. set up folders and master file for a block
Ripple_preprocess.m             2. notch filter, white matter reference, time-frequency decomposition
Ripple_process_inspect.m        3. ripple detection, spectral rejection, summary figures
visualize_individual_ripples.m  (optional) plot individual and average kept/rejected ripples
functions/                      helper functions used by the scripts above
```

## Setup

Each script has a **User paths** section at the top. Set these once for your machine:

| Variable | Used in | What it points to |
|---|---|---|
| `raw_root` | `PAV_ecog_make_master.m` | raw data |
| `data_root` | all scripts | processed data and master files |
| `result_root` | `PAV_ecog_make_master.m` | figures |

`data_root` must be the same in every script.

### Expected raw data

```
<raw_root>/<sbj>/iEEGData/macro/<block>/<sbj>_Datafile_<block>_ch001.mat
                                       .../<sbj>_Datafile_<block>_ch002.mat
                                       ...
```

Each file holds one channel as a row vector named `datafile`, sampled at 2000 Hz by default. For example, `PAV038/iEEGData/macro/007/PAV038_Datafile_007_ch001.mat`.

## Running the pipeline

All three scripts prompt for their inputs in the command window.

**1. `PAV_ecog_make_master.m`**: run once per block.
Enter the subject code (e.g. `PAV038`), project (e.g. `EOEC`), block number (zero padded, e.g. `007`) and number of channels. The defaults are 2000 Hz sampling with 2x downsampling, giving 1000 Hz for the time-frequency and ripple epochs. The script creates the block's folders and saves `master_vars` to `<data_root>/originalData/<sbj>/master_<project>_<sbj>_<block>.mat`.

**2. `Ripple_preprocess.m`**: enter the subject, project and blocks, then the white matter reference layout.
Each depth probe channel is referenced to **one** white matter contact. For example, if contact 2 is the reference for 4, 5 and 6, and contact 10 is the reference for 11, 12 and 13, enter 2 reference channels: `2` → `[4 5 6]`, then `10` → `[11 12 13]`. For each block, the script:
- notch filters 60, 120 and 180 Hz on all channels
- subtracts the white matter channel from each channel referenced to it
- computes a Morlet wavelet decomposition (7 cycles, 2–201 Hz) of the referenced channels at 1000 Hz

**3. `Ripple_process_inspect.m`**: enter the subject, project and blocks.
This runs detection, extracts epochs, runs spectral rejection and saves one summary figure per channel.

**Optional: `visualize_individual_ripples.m`**: average (and, with `if_plot = 1`, individual) time-frequency plots of kept vs. rejected ripples for chosen blocks and channels.

## Method

### Detection (`ripple_detection.m`, `Ripple_Detect.m`)
Detection runs on the white-matter-referenced signal at the full sampling rate:
1. Band-pass filter at 80–120 Hz: FIR (`fir1`, order `3*fix(srate/80)+1`), zero phase (`filtfilt`).
2. RMS envelope with a 20 ms window, then smoothed with a 20 ms moving mean.
3. Threshold at mean + 2.5 SD of the envelope. Samples above mean + 9 SD are excluded before the mean and SD are recomputed, and are never counted as ripples.
4. Remove events shorter than 3 cycles of the lowest ripple frequency (38 ms for 80 Hz, minimum 25 ms).
5. Merge events separated by less than `Mergedur` (0.5 s; see the note in `ripple_detection.m`).

### Epochs (`ripple_signal_extract.m`, `eventSignalEpoch.m`)
For each event, ±200 ms around the band-pass peak is extracted at 1000 Hz. This gives the raw LFP, the ripple band signal and the time-frequency power as % change from that channel's mean power over the whole block. The event's **spectrum** is the mean % power change across the event's duration.

### Spectral rejection (`ripple_rejection.m`, `ripple_spec_reject.m`)
Peaks are found in each event's spectrum. An event is kept (code 0) only if it passes every check:

| Code | Rejected because |
|---|---|
| 1 | any spectral peak is above 10000% change (noise) |
| 2 | not exactly one peak in the ripple band |
| 3 | the ripple peak is not the highest and most prominent peak above 30 Hz |
| 4 | more than one peak above the ripple band, and one of them is above 50% of the ripple peak height (likely epileptic spikes) |
| 5 | a peak outside the ripple band (above 30 Hz) is as high as the ripple peak |

## Outputs

| Folder (`master_vars` field) | Files |
|---|---|
| `Filt_dir` | `fiEEG<block>_<chan>.mat`: notch filtered channels |
| `WM_dir` | `WMBPiEEG<block>_<chan>.mat`: white matter referenced channels |
| `Spec_dir` | `TF_decomp_WM_<sbj>_<block>_<chan>.mat`: wavelet amplitude and phase (`band`) |
| `SWR_dir` | `outRipple_<sbj>_<block>_WM_<chan>_80-120.mat`: detection output (`detect_output`) |
| | `ripple_LFP_TF_DS_<block>_WM_<chan>_80-120.mat`: event epochs (`eventEpoch`: `LFP`, `BPFil`, `TF`, `SD`) |
| | `ripple_rej_info_<block>_WM_<chan>_80-120.mat`: rejection results (`event_pk_rej_info`, column 2 = reject code) |
| `SWR_result_dir` | `<sbj><block>_ripple_attri_WM_<chan>_80-120.png`: kept vs. rejected averages per channel |

`ripple_inspect_plot` also returns `channel_event_attr` with one row per channel: the ripple rate, recording length, counts of kept and rejected ripples, and the timing, duration, amplitude and peak frequency of each kept ripple.

## Credits

This code builds on several labs' work, credited in each file's header:

- Ripple detection, spectral rejection and white matter referencing: Yvonne Chen
- Master file, time-frequency wrapper and wavelet decomposition: Brett Foster, with updates from Yvonne Chen and Eleonora Bartoli
- `notch.m`: Robert Knight lab (Adeen Flinker)
- `noiseFiltData.m`: based on code by Mohammad Dastjerdi (Parvizi lab, Stanford), modified by Brett Foster and Yvonne Chen
- Finalization of rejection parameters and cleanup for sharing: Liz Siefert

## Citation

If you use this code, please cite:

- Chen et al., 2021. *Cell Reports*. [doi:10.1016/j.celrep.2021.109304](https://doi.org/10.1016/j.celrep.2021.109304)
- Siefert et al., 2026. [doi:10.64898/2026.06.26.734578](https://doi.org/10.64898/2026.06.26.734578)

## License

Copyright (C) 2026 Foster Lab, University of Pennsylvania

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 of the License. See [LICENSE](LICENSE) for the full text.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

**Additional term (GPL-3.0 Section 7(d)):** The names of the Foster Lab, the University of Pennsylvania, and the authors and contributors listed above may not be used to endorse or promote products or work derived from this software without specific prior written permission.
