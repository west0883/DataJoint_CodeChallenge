%{
# Stimulation type
stimulation_id: int               # unique stimulation id, as integer                                     
---
stim_width: int
stim_height: int
x_block_size: int
y_block_size: int
fps: double

%}

classdef Stimulation < dj.Manual
end