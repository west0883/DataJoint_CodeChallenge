%{
  # Place to store computations by neuron.
  -> slwest382_codechallenge.Neuron
  -> slwest382_codechallenge.Delay
  ---
  avg_sta = NULL: longblob
  avg_std = NULL: longblob
%}

% This is relevent if you want to compare across multiple stimulations. 
classdef NeuronComputations < dj.Computed
    methods(Access=protected)
        function makeTuples(self,key)

            % Fetch the spike-triggered averages & stds of the neuron
            [stas, stds] = fetchn(slwest382_codechallenge.SpikeTriggeredAverage & key, 'sta', 'std');
            
            % Fetch the number of spikes per stim. 
            spike_times = fetchn(slwest382_codechallenge.Recording & key, 'spike_times'); 

            % If empty. skip (weird, I think it should always give an NaN?)
            if isempty(stas) 
                key.avg_sta = NaN;
                key.avg_std = NaN;

            elseif numel(stas) == 1
                 key.avg_sta = stas{1};
                 key.avg_std = stds{1};

            else  
               % Concatenate 
               stas_together = cat(3, stas{:});
               stds_together = cat(3, stds{:});
               
               % Weight each based on number of spikes.
               spike_numbers = NaN(numel(spike_times),1);
               for i = 1:numel(spike_times)
                     spike_numbers(i) = numel(spike_times{i});
                     stas_together(:,:, i) = stas_together(:,:,i) *spike_numbers(i);
                     stds_together(:,:, i) = stds_together(:,:,i) *spike_numbers(i);
               end 

               % Take weighted mean. 
               key.avg_sta = sum(stas_together,3) ./ sum(spike_numbers);
               key.avg_std = sum(stds_together,3) ./ sum(spike_numbers);

%                key.avg_sta = mean(stas_together, 3, 'omitnan');
%                key.avg_std = mean(stds_together, 3, 'omitnan');

            end
            self.insert(key);
        end
    end
end