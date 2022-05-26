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
            
            % If nan, skip
            if isnan(stas{1})
                key.avg_sta = NaN;
                key.avg_std = NaN;

            elseif numel(stas) == 1
                 key.avg_sta = stas{1};
                 key.avg_std = stds{1};
            else  
               % Concatenate 
               stas_together = cat(3, stas{:});
               stds_together = cat(3, stds{:});

               % Take mean. 
               key.avg_sta = mean(stas_together, 3, 'omitnan');
               key.avg_std = std(stds_together, [], 3, 'omitnan');

            end
            self.insert(key);
        end
    end
end