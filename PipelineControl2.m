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
% frames,movie], neuron [id, firing times], also fps and pixel size (they 
% don't seem to change, but chould in theory; they are dependent on each 
% recording).

% Grab all iterations with code I've written previously.
loop_list.iterators = {'session', {'[1:size(loop_variables.sessions,2)]'}, 'session_iterator';
                       'stimulation', {'[1:size({loop_variables.sessions(', 'session_iterator', ').stimulations(:).fps},2)]'}, 'stimulation_iterator';
                       'neuron', {'[1:size(loop_variables.sessions(', 'session_iterator', ').stimulations(', 'stimulation_iterator', ').spikes,1)]'}, 'neuron_iterator' };

loop_variables.sessions = sessions; 
[looping_output_list, ~] = LoopGenerator(loop_list, loop_variables);


data_titles = {'subject', 'date', 'sample', 'stimulation id', 'onset', ...
    'frames', 'movie', 'neuron id', 'firing times', 'fps', 'pixel size'};
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

        % Frames per second.
        data{itemi, 10} = sessions(session).stimulations(stimulation).fps;

        % Pixel size.
        data{itemi, 11} = sessions(session).stimulations(stimulation).pixel_size;

    end 
end 

%% Create table of subjects.
% Create table. Not surpressing outputs so I can watch things build.
slwest382_codechallenge.Subject

% Grab all subject_names from "sessions". Have to make a cell array 
% (instead of normal array) or else matlab puts all the strings into one 
% massive string. 
subject_names = data(:,1);

% Remove duplicated subjects, which throw an error when populating keys.
subject_names_unique = unique(subject_names);

% Insert into table. 
insert(slwest382_codechallenge.Subject, subject_names_unique)

%% Create table of sessions.
% Create table
slwest382_codechallenge.Session

% Assume data is already loaded & don't need to spend time loading it
% again. Grab subjects ands dates.
session_dates = data(:, 1:2);

% Find unique entries. Have to
% convert to a table & back because 'rows' doesn't work on cell arrays.
session_dates_unique = table2cell(unique(cell2table(session_dates), 'stable'));

% Insert dates along with subject names from above. 
insert(slwest382_codechallenge.Session, session_dates_unique);
slwest382_codechallenge.Session

%% Create table of samples.

% Create table
slwest382_codechallenge.Sample

%Grab sample ID numbers from sessions structure, as above.
sample_numbers = data(:, 1:3);

%Remove any empty entries. (Have to do with a for loop because of the way cells work) 
empty_indices = [];
for i =  1:size(data,1)
    if isempty(data{i,3})
        empty_indices = [empty_indices; i];
    end
end
sample_numbers(empty_indices, :) = [];
%Sample numbers don't repeat, but for completeness I'll make sure
% everything's unique. 
holder = table2cell(unique(cell2table(sample_numbers)));

% Insert 
insert(slwest382_codechallenge.Sample, holder);
slwest382_codechallenge.Sample

%% Create table of stimulation types.
% Might want to group these across animals, days, neurons. Not dependent on
% previous tables. 

% Create table
slwest382_codechallenge.Stimulation

% Place from unique stimulation types calculated above.
holder = num2cell([[1:5]' all_stimulations_unique]);

% Insert 
insert(slwest382_codechallenge.Stimulation, holder);
slwest382_codechallenge.Stimulation

%% Create table of Neurons.
% Dependent on session, sample, but not stimulation type.
slwest382_codechallenge.Neuron

%Grab sample ID numbers from sessions structure, as above.
holder = data(:, [1:3 8]);

%Remove any empty entries. (Have to do with a for loop because of the way cells work) 
empty_indices = [];
for i =  1:size(data,1)
    if isempty(data{i,8})
        empty_indices = [empty_indices; i];
    end
end
holder(empty_indices, :) = [];

% Remove repeats
holder = table2cell(unique(cell2table(holder)));

% Insert 
insert(slwest382_codechallenge.Neuron, holder);
slwest382_codechallenge.Neuron

%% Create table of Recordings
% Dependent on neuron, stimulations
slwest382_codechallenge.Recording

%Grab sample ID numbers from sessions structure, as above.
holder = data(:, [1:3 8 4:7 9:11]);

%Remove any empty entries. (Have to do with a for loop because of the way cells work) 
empty_indices = [];
for i =  1:size(data,1)
    if isempty(data{i,9})
        empty_indices = [empty_indices; i];
    end
end
holder(empty_indices, :) = [];

% Don't need to look for unique entries here.

% Insert.
% This tends to take a long time, to the point I was afraid I'd crashed
% Matlab. 
insert(slwest382_codechallenge.Recording, holder);
slwest382_codechallenge.Recording