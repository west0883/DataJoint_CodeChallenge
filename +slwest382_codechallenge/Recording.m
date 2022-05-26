%{
 # Recordings
 -> slwest382_codechallenge.Neuron
 -> slwest382_codechallenge.Stimulation 
 ---
 stimulus_onset: double
 fps: double
 n_frames: int
 pixel_size: double
 movie: longblob
 spike_times: longblob
 %}
classdef Recording < dj.Imported
    methods(Access=protected)
        function makeTuples(self, key, sessions)


            sessions
            key.filtered_image = myfilter(img);
            self.insert(key)
        end
    end
end