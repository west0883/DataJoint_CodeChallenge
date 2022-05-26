% PipelineControl.m
% Sarah West
% 3/24/22

% A script that controls each step in the analysis pipeline for the
% DataJoint Data Scientist hiring code challenge.

%% Convert pickle data to Matlab-readable format.
% Keeping the following sections to show that I did, indeed, accomplish
% something on Thursday--although I'll use the provided .mat data now that
% I have access to it to avoid running into any conversion issues I didn't
% see.
clear all;
py.importlib.import_module('numpy');
py.importlib.import_module('pickle');

% Read-in data file to a buffered reader format. 
input_directory = 'Z:\DBSdata\Sarah\DataJoint Code Challenge Data\';
fid=py.open([input_directory 'ret1_data.pkl'],'rb');

% Load from buffered reader structure, convert to cell array.
data=cell (py.pickle.load(fid));

% Save as .mat file -- Not possible yet (doesn't load back up).
%([input_directory 'ret1_data.mat'],'data');

%% Convert each element to Matlab datatype. 
% Weird things start to happen if I try to work with Python data types
% here, so I will convert to Matlab data types right away. 

% I don't know the maximum value of each possible data category, so will
% convert numbers to double as a default. 

% If I had more time, I'd make this recursive instead of assuming a set number
% of nests.

% For each cell (each dictionary in the list)
data_out = data;
for celli = 1:numel(data)
   
    % Convert dictionary to structure
    data_out{celli} = struct(data{celli});

    % Get the field names (all keys in the dictionary. 
    entries = fieldnames(data_out{celli});
    
    % For each field (each key in the dictionary)
    for fieldi = 1:numel(entries)

        % Get the value of the field
        value =  getfield(data_out{celli}, entries{fieldi});

        % Get the data type of the value
        datatype = class(value);

        % Depending on the datatype, convert to appropriate Matlab type
        switch datatype 
            case 'py.int'
                value = double(value);

            case 'py.str'
                value = string(value);

            case 'py.list'
                
                % Convert to cell. 
                value = cell(value);
                
                % Clear stimulation structure so you don't overwrite it
                % each time. 
                clear stimulation_structure; 

                % For each cell element in values (for each
                % stimulation),
                for stimulationi = 1: numel(value)
                    
                    % Convert to structure with each stimulation as
                    % different entry. 
                    stimulation_structure(stimulationi) = struct(value{stimulationi}); 

                    % Now go through each of those fields 
                    stimfields = fieldnames(stimulation_structure);
                    for stimfieldsi = 1:numel(stimfields)

                        % Repeat type check 
                        value2 = getfield(stimulation_structure, {stimulationi}, stimfields{stimfieldsi});
                        datatype = class(value2);

                        switch datatype 
                            case 'py.int'
                                value2 = double(value2);
                
                            case 'py.str'
                                value2 = string(value2);

                            case 'py.numpy.ndarray'
                                 value2 = double(value2);

                            case 'py.list'
                                % At this level ('Spikes'), should only be
                                % an array.
                                value2 = cell(value2);

                                % Convert each to an array. 
                                for ii = 1:numel(value2)
                                    value2{ii} = double(value2{ii});
                                end
                                        
                        end 

                        % Put value2 where it belongs.
                        stimulation_structure = setfield(stimulation_structure,{stimulationi}, stimfields{stimfieldsi}, value2);

                    end
                end
                 % Make value equal to the stimulation structure.
                 if numel(value) == 0
                     value = [];
                 else
                    value = stimulation_structure;
                 end
            end

            % Put value back into appropriate place. 
            data_out{celli}= setfield(data_out{celli}, entries{fieldi}, value); 
    end 
end 

%% Rename and save data_out
clear data;
data = data_out; 
save([input_directory 'ret1_data_selfConversion.mat'], 'data');

%% Load data (the provided dataset).
input_directory = 'Z:\DBSdata\Sarah\DataJoint Code Challenge Data\';
load([input_directory 'ret1_data.mat'], 'sessions');

%% Create table of subjects.

% Beginning of the actual Code Challenge. Created schema
% +slwest382_codchallenge in DataJoint tutorial database. 

% Thought I could do this with the "import" type class so I don't have to 
% load the data or write out the subject names, but there are no
% keys set up yet so I believe I need to do a "manual" type for this.

% Create table. Not surpressing outputs so I can watch things build.
slwest382_codechallenge.Subject

% Grab all subject_names from "sessions". Have to make a cell array 
% (instead of normal array) or else matlab puts all the strings into one 
% massive string. Flip so all entries are put in as own row. 
subject_names = {sessions(:).subject_name}';

% Remove duplicated subjects, which throw an error when populating keys.
subject_names_unique = unique(subject_names);

% Insert into table. Watch output.
insert(slwest382_codechallenge.Subject, subject_names_unique)

%% Create table of sessions.
% Create table
slwest382_codechallenge.Session

% Assume data is already loaded & don't need to spend time loading it
% again. Grab session dates from sessions structure, as above.
session_dates = {sessions(:).session_date}';

% Find unique entries. Have to
% convert to a table & back because 'rows' doesn't work on cell arrays.
holder = table2cell(unique(cell2table([subject_names session_dates]), 'stable'));

% Insert dates along with subject names from above. 
insert(slwest382_codechallenge.Session, holder);

%% Create table of samples.

% Create table
slwest382_codechallenge.Sample

%Grab sample ID numbers from sessions structure, as above.
sample_numbers = {sessions(:).sample_number}';

% Sample numbers don't repeat, but for completeness I'll make sure
% everything's unique. 
holder = table2cell(unique(cell2table([subject_names session_dates sample_numbers])));

% Insert 
insert(slwest382_codechallenge.Sample, holder);


%% Create table of stimulation types.
% Might want to group these across animals, days, neurons. Not dependent on
% previous tables. 

% Create table
slwest382_codechallenge.Stimulation

% Write out needed fields.
fields = {'stim_width', 'stim_height', 'x_block_size', 'y_block_size'};

% Creat empty structure for holding stim parameters.
holding_structure = struct(); 
for fieldi = 1:numel(fields)
    holding_structure = setfield(holding_structure, fields{fieldi}, []);
end 

% Get lists of possible stimulation types.
for i = 1:numel(sessions)
    
    % For each stimulation
    
    for stimi = 1:numel(sessions(i).stimulations)

        % Assign fields.
        temp_structure = struct();
        for fieldi = 1:numel(fields)
             temp_structure = setfield(temp_structure, fields{fieldi}, getfield(sessions(i).stimulations(stimi), fields{fieldi}));
        end

        % Concatenate with holding structure.
        holding_structure = [holding_structure; temp_structure]; 
    end

end

% Remove the empty first entry of holding_structure
holding_structure = holding_structure(2:end); 

% Find unique entries. Convert it to a table and back because eveything in
% Matlab is hard.
[holding_structure_unique, rows, ~] = unique(struct2table(holding_structure), 'rows', 'stable');
holding_structure_unique = table2struct(holding_structure_unique);

% Add the stimulation id to structure;
for stimi = 1: numel(holding_structure_unique)
    holding_structure_unique(stimi).stimulation_id = stimi;
end

% Insert into Stimulation table. 
insert(slwest382_codechallenge.Stimulation, holding_structure_unique);

%% Create a recordings table.
% Dependent on neuron, stimulation type. Will have other, non-primary key
% attributes. 
% Looking for ways to not have to repeatedly loop through things...not finding it. 

% Create table
slwest382_codechallenge.Recording

% Go back and put the stimulation flag back with the neurons. 
for i = 1:numel(sessions)   
    for ii = 1:numel(sessions(i).stimulations)
        
        % Get stim fields
        stim_height = sessions(i).stimulations(ii).stim_height;
        x_block_size = sessions(i).stimulations(ii).x_block_size;
        y_block_size = sessions(i).stimulations(ii).y_block_size;

        % For each potential stim id, 
        for iii = 1:numel(holding_structure_unique)
            % Get stim fields
            stim_stim_height = holding_structure_unique(iii).stim_height;
            stim_x_block_size = holding_structure_unique(iii).x_block_size;
            stim_y_block_size = holding_structure_unique(iii).y_block_size;

            if isequal([stim_height, x_block_size, y_block_size], [stim_stim_height, stim_x_block_size, stim_y_block_size])
                sessions(i).stimulations(ii).stimulation_id = holding_structure_unique(iii).stimulation_id;
            end
        end 
    end 
end

%% Create table of neurons
% Neurons depend on the session, sample id, but not the stimulations. 
% Originally had this before the "Stimulation" section, but moved it so I
% could include a concatenation of the stim ids. 

% Create table
slwest382_codechallenge.Neuron

% I thought about using the Server-side inserts for these tables, but it
% looks like you can't add fields to each tuple.
% Adding neuron ids in the structure way, to try it out.
holding_structure = fetch(slwest382_codechallenge.Sample, '*');

% Make a new holding structure for structure with neuron ids added.
f = [fieldnames(holding_structure)' {'neuron_id'} {'stimulation_id'}];
f{2,1} = {};
holding_structure_new= struct(f{:});

% All stim ids 
all_stim_ids  = []; 
neuron_stim_ids = [];
% Grab neuron id numbers.
for i = 1:numel(sessions)
    
    % Only if stimulations isn't empty. Can skip if no stimulations.
    if ~isempty(sessions(i).stimulations)
        
        % Just use the first entry of stimulations, because number of
        % neurons won't change between stims.
        number_of_neurons = size(sessions(i).stimulations(1).spikes, 1);
    
        % Make 
        temp_structure = repmat(holding_structure(i), number_of_neurons*numel(sessions(i).stimulations) , 1);
        counter = 0; 
        % For each neuron, insert neuron ID
        for neuroni = 1:number_of_neurons
            temp_structure(neuroni).neuron_id = neuroni; 
       
            % For each stimulation,
            for ii = 1:numel(sessions(i).stimulations)
                temp_stims = repmat(sessions(i).stimulations(ii).stimulation_id, number_of_neurons,1);
                
                temp_neurons = [1:number_of_neurons]';
                all_stim_ids = [all_stim_ids; temp_stims];
                neuron_stim_ids = [neuron_stim_ids; temp_neurons ];
            end
            % Concatenate temp structure into holding_structure_new.
            holding_structure_new = [holding_structure_new; temp_structure];
        end 
    else 

    end
    
end 

% Insert into Neuron table. 
insert(slwest382_codechallenge.Neuron, holding_structure_new);
