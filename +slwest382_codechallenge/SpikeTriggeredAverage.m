%{
  # Spike-triggered averages
  -> slwest382_codechallenge.Recording
  -> slwest382_codechallenge.Stimulation # Probably don't need this.
  -> slwest382_codechallenge.Delay
  ---
  sta = NULL : longblob                 # The calculated spike triggered averages
                                # (will be an averaged movie frame of the 
                                # frames that trigger a spike)
  std = NULL: longblob                 # Standard deviation of the frames that
                                # trigger a spike (will be a movie frame)
  
%}

classdef SpikeTriggeredAverage < dj.Computed

    methods(Access=protected)
        function makeTuples(self,key)
     
            % Get the fps.
            [fps] = fetch1(slwest382_codechallenge.Recording * slwest382_codechallenge.Stimulation & key, 'fps');

            % Round the fps for acting like a primary key in the look-up
            % table.
            fps = round(fps);

            % Set up fetch queries as strings, I guess. I haven't found a
            % better way to do this. 
            querystring1 = sprintf('delay = %d', key.delay);
            querystring2 = sprintf('fps = %d', fps);

            % Find relevent delay from look-up table.
            delay_adjusted = fetch1(slwest382_codechallenge.DelayAdjusted & {querystring1, querystring2},'delay_adjusted');
            
            % If adjusted delay is NaN, make computations NaN as well.
            if isnan(delay_adjusted)
               key.sta = NaN; 
               key.std = NaN;
            else
                
                % Fetch spike times, movie, movie sizes, n_frames
                [spike_times, movie, x_block_size, y_block_size, n_frames] ...
                    = fetch1(slwest382_codechallenge.Recording * slwest382_codechallenge.Stimulation ... 
                     & key, 'spike_times', 'movie', 'x_block_size', 'y_block_size', 'n_frames');

                % Convert spike times to frames, using the default fps
                % (default fps should be a property of DelayAdjusted, but I
                % haven't gotten to that yet).
                default_fps = 60; 

                % Convert spike times to frames. Have to round. (If I had more time, I'd
                % also adjust this to take into account the slightly off
                % movie fps). 
                % I think it's fair to count the same frame more than once
                % if it results in more than one firing of the cell. 
                spike_times = round(spike_times * default_fps); 
                
                % Get the list of frames to calulate with. 
                stimulus_frame_times = spike_times - key.delay;

                % Remove frames that go below 1 or abover n_frames. 
                stimulus_frame_times(stimulus_frame_times < 1) = [];
                stimulus_frame_times(stimulus_frame_times > n_frames) = [];
               
                % Get only relevent movie frames.
                stimulus_frames = movie(:,:, stimulus_frame_times);

                % Calculate full movie (hate that I'm doing this for every
                % neuron & delay, I'd change that with a movie ID if I had more time.
                % Although mabye it's okay because the spike times are pretty sparse.)
                stimulus_frames_full = repmat(stimulus_frames, x_block_size, y_block_size, 1);

                % compute various statistics on activity
                key.sta = mean(stimulus_frames_full, 3, 'omitnan'); % compute mean
                key.std = std(stimulus_frames_full, [], 3, 'omitnan'); % compute standard deviation
            
            end 
            self.insert(key);

        end
    end
end