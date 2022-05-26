%{
 # Recordings
 -> slwest382_codechallenge.Neuron
 -> slwest382_codechallenge.Stimulation 
 ---
 stimulus_onset: double
 n_frames: int
 movie: longblob
 spike_times: longblob
 fps: double
 pixel_size: double
 %}
classdef Recording < dj.Manual
  
end