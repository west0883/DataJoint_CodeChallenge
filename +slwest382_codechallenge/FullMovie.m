%{
 # FullMovie
 -> slwest382_codechallenge.Recording
 ---
 full_movie: longblob
 %}
classdef FullMovie < dj.Computed
      methods(Access=protected)
        function makeTuples(self,key)

            % Pull out info for this key
            this_data = slwest382_codechallenge.Recording * slwest382_codechallenge.Stimulation & key; 

            % Fetch each needed attribute.
            [x_block_size, y_block_size, movie] = this_data.fetchn('x_block_size','y_block_size', 'movie');
 
            % Calculate full movie;
            key.full_movie = repmat(movie{1}, x_block_size, y_block_size, 1);
     
            % Insert keys.
            self.insert(key);
        end
      end
end