 %{
# Delays to calculate spike-triggered average across, adjusted for fps
->slwest382_codechallenge.Delay       # Dependent on entries of Delay, FPS                       # fps of stimulus movie. 
->slwest382_codechallenge.FPS
---
delay_adjusted: double                # Delay (in frames) adjusted from the
                                      # fps of the movie stimulus. Meant to
                                      # be used as an index for finding the
                                      # correct movie frame.
%}

classdef DelayAdjusted< dj.Computed
     
    methods(Access=protected)
        function makeTuples(self,key)
    
            % Default conversion fps. (Should try making this a member of
            % the class later).
            conversion_fps = 60; 

            % Use fps and delay to calculate adjusted delay.
            increment_value = conversion_fps/key.fps;

            % If this delay is not divisible by the increment value 
            % (remainder is not 0), make this adjusted delay an NaN. 
            if rem(key.delay,increment_value) ~= 0
               key.delay_adjusted = NaN; 
            
            else
                % Otherwise, divide the delay value by the increment
                % for the adjusted delay.
                key.delay_adjusted = key.delay/increment_value;

            end

            % Insert keys.
            self.insert(key);
        end
    end
end

       
 