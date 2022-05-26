%{
  # Spike-triggered averages
  -> slwest382_codechallenge.Recording
  -> slwest382_codechallenge.Stimulation
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
            
            % fetch spike times as Matlab array. (I don't like that I'm
            % fetching into the not-database side, as I understand it, but
            % I'm not sure yet if there's a way to avoid that).
            [spike_times, movie] = fetch1(slwest382_codechallenge.Recording & key,'spike_times', 'movie');   

     
            % First get stim ID key. Also get the sizes of the
            % movie, fps.
            [x_block_size, y_block_size, fps] = fetch1(slwest382_codechallenge.Recording * slwest382_codechallenge.Stimulation & key, 'x_block_size', 'y_block_size', 'fps'); 

            % Round the fps for acting like a primary key in the look-up
            % table.
            fps = round(fps);

            % Calculate full movie 
            full_movie = repmat(movie, x_block_size, y_block_size, 1);

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
                
                
                % compute various statistics on activity
                key.sta = mean(activity); % compute mean
                key.stdev = std(activity); % compute standard deviation
            
            end 
            self.insert(key);

        end
    end
end