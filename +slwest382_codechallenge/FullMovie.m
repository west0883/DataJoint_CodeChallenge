%{
 # FullMovie
 -> slwest382_codechallenge.Sample
 movie_id: int          # ID of movie played for each stim per
                        # session/sample
 ---
 full_movie: longblob
 %}
classdef FullMovie < dj.Computed
      methods(Access=protected)
        function makeTuples(self,key)

            % Pull out info for this key
            this_data = slwest382_codechallenge.Session * slwest382_codechallenge.Stimulation & key; 

            % Fetch each needed attribute.
            [x_block_size, y_block_size, movie] = this_data.fetch1('x_block_size','y_block_size', 'movie');
 
            % Calculate full movie;
            key.full_movie = repmat(movie, x_block_size, y_block_size, 1);
     
            % Insert keys.
            self.insert(key);
        end
      end
end