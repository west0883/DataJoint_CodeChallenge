%{
  # Figures of spike-triggered averages
  -> slwest382_codechallenge.Recording
  -> slwest382_codechallenge.Delay
  ---
  sta = NULL : longblob                 # The calculated spike triggered averages
                                # (will be an averaged movie frame of the 
                                # frames that trigger a spike)
  std = NULL: longblob                 # Standard deviation of the frames that
                                # trigger a spike (will be a movie frame)
  
%}
