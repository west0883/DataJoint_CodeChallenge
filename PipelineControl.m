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

%% Create table of subjects.

% Beginning of the actual Code Challenge. Created schema
% +slwest382_codchallenge in DataJoint tutorial database. 

% Thought I could do this with the "import" type class so I don't have to 
% load the data or write out the subject names, but there are no
% keys set up yet so I believe I need to do a "manual" type for this.

% Create table. Not surpressing outputs so I can watch things build.
slwest382_codechallenge.Subject

% Load data (the provided dataset).
input_directory = 'Z:\DBSdata\Sarah\DataJoint Code Challenge Data\';
load([input_directory 'ret1_data.mat'], 'sessions');

% Grab all subject_names from "sessions". Have to make a cell array 
% (instead of normal array) or else matlab puts all the strings into one 
% massive string. Flip so all entries are put in as own row. 
subject_names = {sessions(:).subject_name}';

% Remove duplicated subjects.

% Insert into table. 
insert(slwest382_codechallenge.Subject, subject_names);

%% Create table of samples.

%% Create table of stimulations

%% Create table of spikes? 
