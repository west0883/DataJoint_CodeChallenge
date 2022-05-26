%{
# Delays to calculate spike-triggered average across
delay: double      # Use the delay itself as its own unique id, in frames. Negative
                   # values correspond to spikes firing BEFORE the
                   # stimulus, as a control.
---
%}

% All values are based on the base 60 fps. 

classdef Delay < dj.Lookup
     

end
