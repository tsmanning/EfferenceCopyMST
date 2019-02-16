function [bh_trials,FR_plot_HP] = bighead_response_2(path,test_set,num_eyes,warnSuppress)

% Sorts all trial data by trial condition, generates means, STDs, PSTHs,
% gaussian-convolved SDPs, and baseline firing rates
%
% Usage: [bh_trials,FR_plot_HP] = bighead_response_2(path,test_set,num_eyes,warnSuppress)

%% Setup viewing condition and data set directory
viewing_opts = {'monoc','binoc'};
setstr = 'set\d';

if ~ischar(test_set)
    if test_set ~= 0 && ischar(test_set) == 0
        set_no = num2str(test_set);
        set_dir = ['set',set_no,'/'];
    elseif test_set == 0
        set_dir = '';
    end
else
    if ~isempty(regexp(test_set,setstr,'once'))    % pass set string directly
        set_dir = [test_set,'/'];
    elseif test_set == 'm'
        set_dir = ['set_merge_',viewing_opts{num_eyes},'/'];
    end
end

%% Load in Data
load(strcat(path,'/bh_tests/',set_dir,'trial_ev'))
load(strcat(path,'/bh_tests/',set_dir,'trial_data'))
num_trial_types = trial_data.num_trials;
num_trials = length(trial_ev);

% types = arrayfun(@(x) x.tr_type,trial_ev);
% uniqTypes = unique(types);
% 
% if uniqTypes<num_trial_types
%    error('All trial types not run.'); 
% end

%% Initialize vars
pur_type = {'no pursuit','pursuit','simulated','retstab'};
bh_trials = struct;
FR_plot_HP = nan(num_trial_types,1);
STD_plot_HP = nan(num_trial_types,1);

wait_handle = waitbar(0,[0,num2str(num_trial_types)],'Name','Running Trial Type:');

for M = 1:num_trial_types
    waitbar(M/num_trial_types,wait_handle,[num2str(M),'/',num2str(num_trial_types)])
    
    %% Get Event and Eye position Data
    counter_A = 1;
    for N = 1:num_trials
        if trial_ev(N).tr_type == M-1
            bh_trials(M).pur_dir = trial_ev(N).pur_dir;
            bh_trials(M).head_el = trial_ev(N).head_el;
            bh_trials(M).head_az = trial_ev(N).head_az;
            bh_trials(M).pur_type = pur_type(trial_ev(N).pur_type+1);
            bh_trials(M).ev_times(counter_A,1:length(trial_ev(N).tr_ev_time)) = ...
                trial_ev(N).tr_ev_time;
            bh_trials(M).posx(counter_A,1:length(trial_ev(N).smooth_posx)) = ...
                trial_ev(N).smooth_posx;
            bh_trials(M).posy(counter_A,1:length(trial_ev(N).smooth_posy)) = ...
                trial_ev(N).smooth_posy;
            bh_trials(M).vel(counter_A,1:length(trial_ev(N).eye_vel(1,:))) = ...
                trial_ev(N).eye_vel(1,:);
            % Trim position vector to match & align with velocity
            bh_trials(M).pos_timing(counter_A,1:length(trial_ev(N).eye_pos(3,1:end-5))) = ...
                trial_ev(N).eye_pos(3,1:end-5);
            bh_trials(M).vel_timing(counter_A,1:length(trial_ev(N).eye_vel(2,:))) = ...
                trial_ev(N).eye_vel(2,:);
            
            if ~isempty(trial_ev(N).evcorr_times)
                bh_trials(M).evcorr_times{counter_A,1} = trial_ev(N).evcorr_times';
                bh_trials(M).az_corr_vals{counter_A,1} = trial_ev(N).az_corr_vals';
                bh_trials(M).el_corr_vals{counter_A,1} = trial_ev(N).el_corr_vals';
            end
            
            counter_A = counter_A+1;
        end
    end
    
    %% Get Spikes from simulated flow and fixation alone epochs
    counter_B = 1;
    for N = 1:num_trials
        if trial_ev(N).tr_type == M-1 && ~isempty(trial_ev(N).spikes)
            bh_trials(M).spikes{counter_B,1} = trial_ev(N).spikes';
            
            bh_trials(M).fix_spikes{counter_B} = trial_ev(N).fix_spikes';
            
            counter_B = counter_B + 1;
        elseif trial_ev(N).tr_type == M-1 && isempty(trial_ev(N).spikes)
            bh_trials(M).spikes{counter_B,1} = nan;
            
            bh_trials(M).fix_spikes{counter_B} = trial_ev(N).fix_spikes;
            
            counter_B = counter_B + 1;
        end
    end
    
    %% Just leave eye data to pur_quality.m?
    % Get velocity traces for saccade detection
    
    [rows,~] = size(bh_trials(M).pos_timing);
    
    % Find latest start time
    t_min = max(bh_trials(M).pos_timing(:,1));
    
    % Find earliest end time
    for a = 1:rows
        maximums(a) = max(bh_trials(M).pos_timing(a,:));
    end
    t_max = min(maximums);
    
    mean_pos_timing = (t_min:1:t_max);   % Time vector with values for all trials
    
    [min_ind,~,~] = find(bh_trials(M).pos_timing' == t_min);   %find t_min indices trials
    [max_ind,~,~] = find(bh_trials(M).pos_timing' == t_max);   %find t_min indices trials
    posx = zeros(rows,length(mean_pos_timing));
    posy = zeros(rows,length(mean_pos_timing));
    vel = zeros(rows,length(mean_pos_timing)-2);
    for er = 1:rows
        posx(er,:) = bh_trials(M).posx(er,min_ind(er):max_ind(er));  %crop position values within bounds
        posy(er,:) = bh_trials(M).posy(er,min_ind(er):max_ind(er));
        vel(er,:) = bh_trials(M).vel(er,min_ind(er):max_ind(er)-2);
    end
    
    bh_trials(M).posx = posx;
    bh_trials(M).posy = posy;
    bh_trials(M).vel = vel;
    bh_trials(M).pos_timing = mean_pos_timing;
    bh_trials(M).vel_timing = mean_pos_timing(1,2:end-1);
%     
%     bh_trials(M).mean_posx = mean(posx);
%     bh_trials(M).std_posx = std(posx);
%     bh_trials(M).mean_posy = mean(posy);
%     bh_trials(M).std_posy = std(posy);
    
    %% Get mean spike spike vector for kernel density est of cell dynamics
    
    % For end time, round to nearest hundred, and add 10 to include jitter
    % in final frame draws
    end_time = round(bh_trials(M).ev_times(1,end),-2) + 10;
    bh_trials(M).spike_timevec = (-600:1:end_time);
    numtpts = length(bh_trials(M).spike_timevec);
    numreps = size(bh_trials(M).spikes,1);
    
    bh_trials(M).spike_vectors = zeros(numreps,numtpts);
    
    for O = 1:numreps
        spikes = bh_trials(M).spikes{O};
        % Trim vector start to -600 and convert to indices
        spikes = spikes(spikes >= -600) + 601;
        bh_trials(M).spike_vectors(O,spikes) = 1;
    end

    bh_trials(M).mean_spikes = mean(bh_trials(M).spike_vectors,1);
    bh_trials(M).std_spikes = std(bh_trials(M).spike_vectors,1);
    
    %% Generate PSTH for trial type
    [edges,spks_hist] = psth(bh_trials,M,0,20);  % set bin width 20ms
    
    bh_trials(M).psth_edges = edges;
    bh_trials(M).psth_hist = spks_hist;
    
    %% Get FR mean and standard deviation for trial types
    
    spikeRates = nan(numreps,1);
    for i = 1:numreps
        epochBeg = bh_trials(M).ev_times(i,end-1);
        epochEnd = bh_trials(M).ev_times(i,end);  % will be longer for fixation trials
        epochDur = epochEnd - epochBeg;
        spikeRates(i,1) = sum(bh_trials(M).spikes{i}>epochBeg)/(epochDur/1000);
    end
    
    bh_trials(M).rep_means = spikeRates;
    bh_trials(M).mean_FR_HP = mean(spikeRates);
    bh_trials(M).FR_std_HP = std(spikeRates);
    
    
%     for i = 1:numreps
%         rep_means(i,1) = mean(bh_trials(M).spike_vectors(i,end-600:end))*1000;
%     end
%     bh_trials(M).rep_means = rep_means;
%     
%     % Get mean FR during simulated heading + pursuit epoch
%     bh_trials(M).mean_FR_HP = mean(bh_trials(M).mean_spikes(end-600:end))*1000;   % epoch starts with ~100ms latency
%     
%     % Get trialwise means for STD
%     for V = 1:numreps   % Loop over trial repetitions
%         means_plot_HP(V) = mean(bh_trials(M).spike_vectors(V,end-600:end))*1000;
%         
%         if means_plot_HP(V) == 0  % ignore zero mean trials
%             means_plot_HP(V) = NaN;
%         end
%     end
%     bh_trials(M).FR_std_HP = nanstd(means_plot_HP);
%     
%     if isnan(bh_trials(M).FR_std_HP) == 1     % If all trials 0 mean, STD set to 0
%         bh_trials(M).FR_std_HP = 0;
%     end
%     
%     clear means_plot_HP
    
    FR_plot_HP(M) = bh_trials(M).mean_FR_HP;
    STD_plot_HP(M) = bh_trials(M).FR_std_HP;
end

delete(wait_handle);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Remove perisaccadic spikes (+/-50ms) and collect means/STDs

if ~isnan(max(cellfun(@max,bh_trials(1).spikes)))          % Only run mean/std if spikes are present in trials (for debugging)
    
    % Remove perisaccadic spikes
    
    fr_plot_desac = nan(1,num_trial_types);
    std_plot_desac = nan(1,num_trial_types);
    
    for i = 1:numel(bh_trials)
        % Outputs:
        % [spikes, ex_spikes, mean_dsv, trial_mean, trial_std] = saccade_spikes(bh_trials,i,0);
        [bh_trials(i).desac_spikes,~,~,fr_plot_desac(i),std_plot_desac(i)] =...
            saccade_spikes(bh_trials,i,0,warnSuppress);
    end
    
    % Reorganize Mean & STD data; assign to trial_data struct to save it
    
    num_az = numel(unique(round(trial_data.trial_az,2)));
    
    for a = 1:7               % Loop over pursuit conditions
        for b = 1:num_az      % Loop over azimuth angles
            trial_data.fr_plot_HP(a,b) = FR_plot_HP(a+7*(b-1));
            trial_data.fr_plot_desac(a,b) = fr_plot_desac(a+7*(b-1));
            trial_data.trial_FRs{a,b} = bh_trials(a+7*(b-1)).rep_means;
            trial_data.std_plot_HP(a,b) = STD_plot_HP(a+7*(b-1));
            trial_data.std_plot_desac(a,b) = std_plot_desac(a+7*(b-1));
        end
    end
    
    % Get max PSTH FR for scaling purposes
    
    for ind = 1:num_trial_types
        if isempty(bh_trials(ind).psth_hist) ~= 1
            max_frs_psth(ind,:) = max(bh_trials(ind).psth_hist);
        else
            max_frs_psth(ind,:) = 0;
        end
    end
    trial_data.max_fr_psth = max(max_frs_psth);
    
    % Get reps for each trial type
    
    trial_data.reps = zeros(1,num_trial_types);
    for i = 1:num_trial_types
        [trial_data.reps(i),~] = size(bh_trials(i).ev_times);
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get baseline (fixation period) firing rate

trial_starts = nan(1,num_trials);
fix_time_evs = nan(1,num_trials);

counter_c = 1;

for x = 1:num_trials
    trial_starts(1,x) = trial_ev(x).tr_ev_time(1);
    fix_time_evs(1,x) = trial_ev(x).tr_ev_time(2);
    
    offset = length(trial_ev(x).spikes);
    all_spikes(1,counter_c:counter_c-1+offset) = trial_ev(x).spikes;
    counter_c = counter_c+offset;
end

bl_start = max(trial_starts);     % Only collect spikes from timepoints included in all trials
bl_end = min(fix_time_evs);
bl_length = (bl_end-bl_start)/1000; % Find length of baseline period in sec

num_spikes = numel(all_spikes);
counter_d = 1;
bl_spikes = [];

for y = 1:num_spikes
    if all_spikes(y)>bl_start && all_spikes(y)<bl_end
        bl_spikes(counter_d) = all_spikes(y);
        
        counter_d = counter_d+1;
    end
end

bl_numspikes = numel(bl_spikes);
bl_firing_rate = (bl_numspikes/num_trials)*(1/bl_length);     % Avg spike count divided by

if isempty(bl_spikes) == 0
    [bl_edges,bl_spks_hist] = psth(bl_spikes,num_trials,0,10,'array');  % set bin width 15ms
else
    bl_edges = [];
    bl_spks_hist = [];
end

baseline_data = struct;
baseline_data.firing_rate = bl_firing_rate;
baseline_data.period_length = bl_length;
baseline_data.spikes = bl_spikes;
baseline_data.starttime = bl_start;
baseline_data.endtime = bl_end;
baseline_data.num_trials = num_trials;
baseline_data.psth_edges = bl_edges;
baseline_data.psth_hist = bl_spks_hist;

%% Save structures

save(strcat(path,'/bh_tests/',set_dir,'bh_trials'),'bh_trials');
save(strcat(path,'/bh_tests/',set_dir,'trial_data'),'trial_data');
save(strcat(path,'/bh_tests/',set_dir,'baseline_data'),'baseline_data');
end