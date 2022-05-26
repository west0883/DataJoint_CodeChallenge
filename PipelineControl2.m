% PipelineControl2.m
% Sarah West
% 3/25/22

% A script that controls each step in the analysis pipeline for the
% DataJoint Data Scientist hiring code challenge.

% Changing strategy from first version -- will first make everything into a
% big cell array of everything I need before putting it into the tables.
% Also moving the data conversion code out of the way into its own script.

%% Load data (the provided dataset).
input_directory = 'Z:\DBSdata\Sarah\DataJoint Code Challenge Data\';
load([input_directory 'ret1_data.mat'], 'sessions');

%% Define all stimulation types.
% Write out needed fields.
fields = {'stim_width', 'stim_height', 'x_block_size', 'y_block_size'};

all_stimulations = []; 

% Get lists of possible stimulation types.
for i = 1:numel(sessions)
    
    % For each stimulation
    
    for stimi = 1:numel(sessions(i).stimulations)

        % Assign fields.
        holder = NaN(size(fields));
        for fieldi = 1:numel(fields)
             holder(fieldi) = getfield(sessions(i).stimulations(stimi), fields{fieldi});
        end

        % Concatenate with all_stimulations cell.
        all_stimulations = [all_stimulations; holder]; 
    end

end

% Find unique entries. 
[all_stimulations_unique, rows, ~] = unique(all_stimulations, 'rows', 'stable');

%% Go back and put the stimulation flag back into sessions.

fields = {'stim_width', 'stim_height', 'x_block_size', 'y_block_size'};
for i = 1:numel(sessions)   
    for stimi = 1:numel(sessions(i).stimulations)
        
        % Get stim fields
        field_values = NaN(size(fields));
        for fieldi = 1:numel(fields)
             field_values(fieldi) = getfield(sessions(i).stimulations(stimi), fields{fieldi});
        end
       
        
        % For each potential stim id, 
        for stimidi = 1:size(all_stimulations_unique,1)
            
            % Get stim fields
            stim_values = NaN(size(fields));
            for fieldi = 1:numel(fields)
                 stim_values(fieldi) = all_stimulations_unique(stimidi,fieldi);
            end
          
            % Compare
            if isequal(field_values,stim_values)

                % Define stimulation id
                sessions(i).stimulations(stimi).stimulation_id = stimidi;
                break
            end
        end 
    end 
end

%%  Make cell array. 
% Subject, session date, sample number, stimulation [id, onset,
% frames,movie], neuron [id, firing times]; 

% Grab all iterations with code I've written previously.
loop_list.iterators = {'session', {'[1:size(loop_variables.sessions,2)]'}, 'session_iterator';
                       'stimulation', {'[1:size({loop_variables.sessions(', 'session_iterator', ').stimulations(:).fps},2)]'}, 'stimulation_iterator';
                       'neuron', {'[1:size(loop_variables.sessions(', 'session_iterator', ').stimulations(', 'stimulation_iterator', ').spikes,1)]'}, 'neuron_iterator' };

loop_variables.sessions = sessions; 
[looping_output_list, ~] = LoopGenerator(loop_list, loop_variables);


data_titles = {'subject', 'date', 'sample', 'stimulation id', 'onset', 'frames', 'movie', 'neuron id', 'firing times'};
data = cell(numel(looping_output_list), numel(data_titles));

% For each item in looping_output_list, 
for itemi = 1:size(looping_output_list,1)

    % Get values
    session = getfield(looping_output_list, {itemi}, 'session_iterator');
    stimulation = getfield(looping_output_list, {itemi}, 'stimulation_iterator');
    neuron = getfield(looping_output_list, {itemi}, 'neuron_iterator');
    
    % Subject
    data{itemi, 1} = sessions(session).subject_name;
    
    % Date
    data{itemi, 2} = sessions(session).session_date;

    % Sample 
    data{itemi, 3} = sessions(session).sample_number;

    if ~isempty(stimulation)
      
        % Stimulation id 
        data{itemi, 4} = sessions(session).stimulations(stimulation).stimulation_id;

        % Onset
        data{itemi, 5} = sessions(session).stimulations(stimulation).stimulus_onset;

        % Frames
        data{itemi, 6} = sessions(session).stimulations(stimulation).n_frames;

        % Movie
        data{itemi, 7} = sessions(session).stimulations(stimulation).movie;

        % Neuron id
        data{itemi, 8} = neuron;

        % Spike times
        data{itemi, 9} = sessions(session).stimulations(stimulation).spikes{neuron};
    end 
end 



