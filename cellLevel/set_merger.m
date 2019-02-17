function [trial_ev,trial_data] = set_merger(path,test_sets,num_eyes)

% Merges partially sorted and extracted data into a single dataset
% post-"bighead response" step

% Load in data

for i = 1:numel(test_sets)
    set_no = num2str(test_sets(i));
    set_dir{i} = [path,'/bh_tests/set',set_no];
    load([set_dir{i},'/trial_ev']);
    load([set_dir{i},'/pursQual']);
    
    [~,num_trials(i)] = size(trial_ev);
    
    set(i).trial_ev = trial_ev;
    set(i).pursQual = pursQual;
end

trevFields = fieldnames(set(1).trial_ev);
purFields = fieldnames(set(1).pursQual);

load([set_dir{i},'/trial_data']);
trial_deets = trial_data;

clear trial_data

% Concatenate trial_ev structures

num_trials = [0 num_trials];

clear trial_ev
clear pursQual
trial_ev = struct;
pursQual = struct;

for i = 1:numel(test_sets)          % set offset
    % Concat trial_ev
    for j = 1:num_trials(i+1)       % loop over trials
        for k = 1:numel(trevFields) % loop over fieldnames
            x = trevFields{k};
        
            trial_ev(num_trials(i)+j).(x) = set(i).trial_ev(j).(x);
        end
    end
    
    % Concat purFields
    for l = 1:numel(purFields)
        x = purFields{l};
        
        if ~isfield(pursQual,x)
            pursQual.(x) = set(i).pursQual.(x);
        else
            pursQual.(x) = [pursQual.(x);set(i).pursQual.(x)];
        end
    end
end

%% Generate new trial type IDs for combined data set
% (based on unique combinations of pursuit type, pursuit direction, heading
% azimuth, and heading elevation)

tot_numtrials = numel(trial_ev);

pur_dirs = zeros(1,tot_numtrials);
azimuths = zeros(1,tot_numtrials);
pur_types = zeros(1,tot_numtrials);
elevations = zeros(1,tot_numtrials);

for i = 1:tot_numtrials
   pur_dirs(i) = trial_ev(i).pur_dir; 
   azimuths(i) = trial_ev(i).head_az;
   elevations(i) = trial_ev(i).head_el;
   pur_types(i) = trial_ev(i).pur_type;
end

temp = pur_dirs;
temp(isnan(pur_dirs)) = -1;

trial_params = [azimuths' pur_types' temp' elevations'];

[trialvals,ia,trial_ids] = unique(trial_params,'rows');

trial_params = [azimuths' pur_types' pur_dirs' elevations'];

id_range = 0:1:numel(ia)-1;   % Start ID index from 0 to match rex output

trial_ids = trial_ids-1;
trialvals = [id_range' trialvals];

for i = 1:tot_numtrials
    trial_ev(i).tr_type = trial_ids(i);
    pursQual.tr_type(i,1) = trial_ids(i);
end

%% Make new directory for merged dataset and save structures

trial_data = struct;
trial_data.trial_dir = trialvals(:,4);
trial_data.trial_az = trialvals(:,2);
trial_data.trial_el = trialvals(:,5);
trial_data.purs_type = trialvals(:,3);
trial_data.trial_ids = trial_ids;
trial_data.num_trials = numel(ia);
trial_data.pursuit_speed = trial_deets.pursuit_speed; % assumes speeds were same between trials
trial_data.heading_speed = trial_deets.heading_speed;
trial_data.original_sets = set_dir;
trial_data.single_plane = trial_deets.single_plane;

viewing_opts = {'monoc','binoc'};

if ~exist([path,'/bh_tests/set_merge_',viewing_opts{num_eyes}],'dir')
    mkdir([path,'/bh_tests/set_merge_',viewing_opts{num_eyes}]);
elseif exist([path,'/bh_tests/set_merge_',viewing_opts{num_eyes}],'dir') && ...
       ~exist([path,'/bh_tests/set_merge_',viewing_opts{num_eyes},'.old'],'dir')
    
    warning('Merged set already exists, appending .old suffix to it');
    
    movefile([path,'/bh_tests/set_merge_',viewing_opts{num_eyes}],...
        [path,'/bh_tests/set_merge_',viewing_opts{num_eyes},'.old']);
    mkdir([path,'/bh_tests/set_merge_',viewing_opts{num_eyes}]);
end

save([path,'/bh_tests/set_merge_',viewing_opts{num_eyes},'/trial_ev'],'trial_ev');
save([path,'/bh_tests/set_merge_',viewing_opts{num_eyes},'/pursQual'],'pursQual');
save([path,'/bh_tests/set_merge_',viewing_opts{num_eyes},'/trial_data'],'trial_data');

end