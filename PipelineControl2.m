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
% Went back to add fps; adds a 6th unique stimulation type, but only
% because of rounding, which shouldn't matter for most analysis steps but
% user might still want to have that information. I'll put in a rounding step. 
fields = {'stim_width', 'stim_height', 'x_block_size', 'y_block_size', 'fps'};

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
[all_stimulations_unique, ~, ~] = unique(all_stimulations, 'rows', 'stable');

% Check that they're still unique with rounding. 
[all_stimulations_unique_rounded, rows, ~] = unique(round(all_stimulations_unique), 'rows', 'stable');

% Keep only the entries that were unique with rounding, but keep unrounded
% values.
all_stimulations_unique = all_stimulations_unique(rows,:);

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

% Realized fps is of the stimulation movie, not the sampling rate of
% recording, and it does change. So now I'll go back and add that to stim
% types. Don't need fps in this cell array now because fps is in the stim
% type.

% [I'm realizing now (the next day) that manual tables seem to be meant for
% primary keys only, and I can import the non-primary keys separatly,
% likely in the "Recordings" table I called below. That would give all the
% benefits of the upstreadm/downstream connection that the tables use.
% Since the cell array approach I use here works *okay*, I'll leave it like
% this because of time constraints.]

% Grab all iterations with code I've written previously.
loop_list.iterators = {'session', {'[1:size(loop_variables.sessions,2)]'}, 'session_iterator';
                       'stimulation', {'[1:size({loop_variables.sessions(', 'session_iterator', ').stimulations(:).fps},2)]'}, 'stimulation_iterator';
                       'neuron', {'[1:size(loop_variables.sessions(', 'session_iterator', ').stimulations(', 'stimulation_iterator', ').spikes,1)]'}, 'neuron_iterator' };

loop_variables.sessions = sessions; 
[looping_output_list, ~] = LoopGenerator(loop_list, loop_variables);


data_titles = {'subject', 'date', 'sample', 'stimulation id', 'onset', ...
    'frames', 'movie', 'neuron id', 'firing times', 'pixel size'};
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

    if ~isempty(stimulation) && ~any(isnan(stimulation))
      
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

        % Pixel size.
        data{itemi, 10} = sessions(session).stimulations(stimulation).pixel_size;

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
session_dates_unique = table2cell(unique(cell2table(session_dates),'rows', 'stable'));

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

%Grab sample ID numbers from sessions structure, as above. Don't need fps
% because that's in the stim ID.
holder = data(:, [1:3 8 4:7 9:10]);

%Remove any empty entries. (Have to do with a for loop because of the way cells work) 
empty_indices = [];
for i =  1:size(data,1)
    if isempty(data{i,9})
        empty_indices = [empty_indices; i];
    end
end
holder(empty_indices, :) = [];

% Don't need to look for unique entries here. Throws an error because
% unique can't handle looking at the different arrays in movie and spike
% times.

% Insert.
% This tends to take a long time, to the point I was afraid I'd crashed
% Matlab. 

% [I'm realizing now (the next day) that I could've entered the timeseries 
% and movies as different tables, but I'm not sure if that would remove the
% benefits of making sure you don't have "orphaned" data where there's a
% spike timeseries or a movie but not the other.

insert(slwest382_codechallenge.Recording, holder);
slwest382_codechallenge.Recording

%% Beginning of analysis steps within DataJoint framework.
% Can delete all other variables in workspace. 
clear all;

%% Create look-up table of delays to calculate spike-triggered average across. 
% Will put in values in here instead of in table script to make changes
% easier. Negative delay = neuron fires before stimulus, as
% a control. Finest resolution I have is up to 60 fps in the movie (~16.67 ms), 
% but some fps are closer to 30 fps (~33.33 ms). For entering in ranges,
% it's more practical to enter movie frames, then convert to ms later, so
% all delays will be in units of frames. 
% 
% I'll adjust for stim IDs of lower fps in the calculation steps, so I don't 
% need to include all the possible fps rates here in the look up table 
% (although this LUT does assume a highest or at least most common rate of 60 fps).

% Actually, now I think I'll make this dependent on the unique frames per
% second. That means I WON'T enter values here, I don't think. (Actually,
% that doesn't work, because that means using calculations, so I'll make a
% separate, computed class for including each delay per fps).

% Off the top of my head, I don't know the reaction time of most retinal
% cells, but one article (Cao et al, 2007 DOI:
% 10.1016/j.visres.2006.11.027) says it's as high as 500 ms (!) in poor
% contrast conditions. So I'll go up to 500 ms (about 30 frames in the 60
% fps condition). I'll do only about 5 negative frames as the control-- don't
% want to overload my computation times. 

% Will increment by 1 frame for now, may make incrementation larger if 1
% frame do
%delays = [-5:30];
% Greatly reducing the delays because this computation is taking way too
% much time.
delays = [-4:4:16];
delays = num2cell(delays)';

% Create Delay look up table.
slwest382_codechallenge.Delay

% Insert delays.
insert(slwest382_codechallenge.Delay, delays);


%%  Make a look-up table of unique fps. 
% Fetch fps values from stimulation table.
fps_array = fetchn(slwest382_codechallenge.Stimulation, 'fps');

% Round fps values & find unique ones.
fps_unique = num2cell(unique(round(fps_array)));
    
% Create FPS look up table.
slwest382_codechallenge.FPS

% Insert fps.
insert(slwest382_codechallenge.FPS, fps_unique);

%% Make a calculated table of adjusted delays.
% Create & populate. 
% I'm a bit concerned with how slow this populating is, not sure what's
% causing that since it's a quick calculation. Might just be communication
% time to the server.
slwest382_codechallenge.DelayAdjusted
populate(slwest382_codechallenge.DelayAdjusted)

%% Make a calculated table of full-size movies 
% So you can calculate spike-triggered averages across stimulation type. 
% Will be dependent on Recordings table. 
% [Not sure how granular calculated tables should be, or the pros and cons
% of making a new table class for each step versus just making new ojects
% called from a class-- new objects may just work well for querying witihn
% a table/projecting and aggregating?]
% I don't think this counts as an aggregation function, because it's not a
% summary statistic. But I guess I'll try it. 

% [This didn't work. Didn't throw an error, but didn't create the new
% attribute. Trying to do it on slwest382_codechallenge.Recording directly
% threw an error.]
% calculation = 'repmat(movie, x_block_size, y_block_size)->full_movie';
% all_recordings = slwest382_codechallenge.Recording; 
% all_recordings.aggr(all_recordings * slwest382_codechallenge.Stimulation, calculation);

% I guess I do need a new class type?
%slwest382_codechallenge.FullMovie

% This takes awhile, but I guess that's to be expected when you're
% transferring around large-ish arrays. [I stopped the calculation only a
% few iterations in]
%populate(slwest382_codechallenge.FullMovie)

%[ Actually, it might make more sense to just calculate this at the STA
% step, so I don't need large full videos. ]
%[Well, maybe would be beneficial to not have to calculate these for every
%delay-- but I don't necessarily want to take up a ton of space on their
%server... especially because right now I'm doing it for every neuron. The best 
% idea would be to do something like calculate the full movie for each sample/stimulation, 
% but that might mean going back and making a video ID for each neuron, which I'd do if I had more time.]

%% Create & run spike-triggered average computed table (per recording?)
% Dependent on each recording, adjusted delays. 
% Retinal cells are supposed to be contrast-oriented with place
% preferences, so don't need to account for changes in the video over time
% for right now.
 slwest382_codechallenge.SpikeTriggeredAverage;
 populate(slwest382_codechallenge.SpikeTriggeredAverage);

 % Was using parpopulate to see if it started a parallel pool, but I don't
 % think it did. I'm concerned with how slow this is going. Hopefully
 % there's just something I don't know that will make this go much faster.

%% Create & run compute table that computes spike-triggered average across different queries?
% Not sure yet if this needs its own table separate from the one above, or
% if it can handle query combinations inside it. I think the best way is by
% using aggr -- needs a new table type, I think.  

% [This didn't work, maybe because Neuron isn't a calculated table type]
% slwest382_codechallenge.Neuron.aggr(slwest382_codechallenge.SpikeTriggeredAverage, 'avg(sta)->avg_sta')
% slwest382_codechallenge.Neuron.aggr(slwest382_codechallenge.SpikeTriggeredAverage, 'avg(std)->avg_std')

% This didn't work, either. I thought aggr was something built-in? 
% slwest382_codechallenge.NeuronComputations
%populate(slwest382_codechallenge.NeuronComputations)
% slwest382_codechallenge.NeuronComputations.aggr(slwest382_codechallenge.SpikeTriggeredAverage, 'avg(sta)->avg_sta')
% slwest382_codechallenge.NeuronComputations.aggr(slwest382_codechallenge.SpikeTriggeredAverage, 'avg(std)->avg_std')

slwest382_codechallenge.NeuronComputations
populate(slwest382_codechallenge.NeuronComputations)

%% In an ideal world, I'd do something like caculate firing rates per stimulus type 
% as a supplementary experiement. But that's not a part of the challenge. 

%% Draw ERD
% That's neat. 
draw(dj.ERD(slwest382_codechallenge.getSchema))

%% Create & run a compute table that produces figures.
% Would include the figure obejct in the table? Then call the plotting of the
% figure here. Can include average STAs and average stds

% [Havent tried this yet]
% No, wait, nevermind, I'm seeing in the documentation that DJ only
% supports specific dataypes, not including figure objects. 
% % Something like: 
% slwest382_codechallenge.STAFigure
% slwest382_codechallenge.STAFigure

% So, instead, I'll query then send send the query result through a more
% standard function

% query_result needs to be a single value to properly plot the STA. 
attribute = 'avg_sta'; 
restrictions = {'subject_name = "KO (chx10)"', 'session_date = "2008-06-06"', ...
       'sample_number = 2', 'neuron_id = 6', 'delay = 4'}';
query = slwest382_codechallenge.NeuronComputations & restrictions;
query_result = fetch1(query,attribute);

% Call plotting function. 
fig_handle = PlotSTAs(query_result, restrictions);

function [fig_handle] = PlotSTAs(query_result, restrictions)
    
    fig_handle = figure; 
    imagesc(query_result); 
    colorbar; %caxis([-1 1]);
    title(strjoin(restrictions,', ')); % An unwieldly title, but good enough for now.

    % Could add saving instructions here, if I wanted. 
end 


