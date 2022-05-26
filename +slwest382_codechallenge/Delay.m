%{
# Delays to calculate spike-triggered average across
delay: double      # Use the delay itself as its own unique id, in frames. Negative
                   # values correspond to spikes firing BEFORE the
                   # stimulus, as a control.
---
%}

classdef Delay < dj.Lookup
end
