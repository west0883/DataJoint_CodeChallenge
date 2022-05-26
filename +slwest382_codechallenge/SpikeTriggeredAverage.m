%{
  # Spike-triggered averages
  -> slwest382_codechallenge.Recording
  -> slwest382_codechallenge.Delay
  ---
  STA: longblob                 # The calculated spike triggered averages
                                # (will be an averaged movie frame of the 
                                # frames that trigger a spike)
  std: longblob                 # Standard deviation of the frames that
                                # trigger a spike (will be a movie frame)
  
%}

classdef SpikeTriggeredAverage < dj.Computed

    methods(Access=protected)
        function makeTuples(self,key)
            
            % fetch spike times as Matlab array. (I don't like that I'm
            % fetching into the not-database side, as I understand it, but
            % I'm not sure yet if there's a way to avoid that).
            spike_times = fetch1(+slwest382_codechallenge.Recording & key,'spike_times');   

            % Fetch movie as Matlab array. 
            movie = fetch1(+slwest382_codechallenge.Recording & key,'movie');  

            % Fetch fps of stimulation, which will determine which delays to use. First get stim ID key. 


            % compute various statistics on activity
            key.STA = mean(activity); % compute mean
            key.stdev = std(activity); % compute standard deviation
     
            self.insert(key);
            sprintf('Computed statistics for for %d experiment on %s',key.mouse_id,key.session_date)

        end
    end
end