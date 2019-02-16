function [head_trials,FR_plot,std_plot,means_plot] = heading_response_2(path,test_set)

% Sorts heading data into trials and calculates vector tuning mean and SEM
% as well as averaged spike density plots

if test_set ~= 0
    set_no = num2str(test_set);
    set_dir = ['set',set_no,'/'];
else
    set_dir = '';
end

%Load in Data
load(strcat(path,'/heading_tuning/',set_dir,'trial_ev'))
load(strcat(path,'/heading_tuning/',set_dir,'trial_data'))

num_trials = numel(trial_ev);
num_trial_types = trial_data.num_trials;

head_trials = struct;
FR_plot = zeros(1,num_trial_types);
means_plot = nan(7,num_trial_types);
std_plot = zeros(1,num_trial_types);
max_psth = zeros(1,num_trial_types);

for L = 1:num_trial_types  
    % Sort event times by trial type
    counter_a = 1;
    for O = 1:length(trial_ev)
        if trial_ev(O).tr_type == L-1
           head_trials(L).head_az = trial_ev(O).head_az;
           head_trials(L).head_el = trial_ev(O).head_el;
           head_trials(L).ev_times(counter_a,1:length(trial_ev(O).tr_ev_time)) = trial_ev(O).tr_ev_time;
                   
           counter_a = counter_a+1;   % counter here and below increment for each trial rep
        end
    end
    
    % Sort spike times by trial type
    counter_b = 1;
    for O = 1:length(trial_ev)
        if trial_ev(O).tr_type==L-1
           head_trials(L).spikes{counter_b,1} = trial_ev(O).spikes;
                   
           counter_b = counter_b+1;
        end
    end
        
    % Find mean raster plot
    dots_on = round(mean(head_trials(L).ev_times(:,3)),-1);
    trial_end = round(mean(head_trials(L).ev_times(:,5)),-1);
    
    head_trials(L).spike_timevec = (dots_on:1:trial_end);
    q = length(head_trials(L).spike_timevec);   % num timepoints
    s = size(head_trials(L).ev_times,1);    % num repeats
    head_trials(L).spike_vectors = zeros(s,q);
    
    for S = 1:s
        curr_spikes = head_trials(L).spikes{S}-dots_on;
        curr_spikes = curr_spikes(curr_spikes >= 1);    % trim spikes outside of -200:1010 window
        
        head_trials(L).spike_vectors(S,curr_spikes) = 1;
    end
 
    head_trials(L).mean_spikes = mean(head_trials(L).spike_vectors);

%     % Find trial SDP
%     head_trials(L).spike_dens_plot=gauss_conv(head_trials(L).mean_spikes,15);
    
    % Find trial PSTH
    [edges,spks_hist] = psth(head_trials,L,0,15);  % set bin width 15ms
    
    head_trials(L).psth_edges = edges;
    head_trials(L).psth_hist = spks_hist;
    
    if isempty(spks_hist) == 0
        max_psth(1,L) = max(head_trials(L).psth_hist);
    else
        max_psth(1,L) = 0;
    end
    
    %Find mean and SEM for heading tuning
    mean_window_start = -1*dots_on + 50;    % consider only window 50 ms after translation onset
    
    head_trials(L).mean_FR = mean(head_trials(L).mean_spikes(mean_window_start:end))*1000;  % mean over transient and sustained portions
    FR_plot(L) = head_trials(L).mean_FR;
    
    for V = 1:s
    means_plot(V,L) = mean(head_trials(L).spike_vectors(V,mean_window_start:end))*1000;
    end
    
    head_trials(L).FR_std = nanstd(means_plot(:,L));
    std_plot(L) = head_trials(L).FR_std;
    
    groups{1,L} = [num2str(head_trials(L).head_el),', ',num2str(head_trials(L).head_az)];
    
    clear s S V q counter_a counter_b
end

trial_data.maxFR = max(max_psth);

%%% Run tuning statistics %%%

% one-way ANOVA

[p,tbl,stats] = anova1(means_plot,groups,'off');
trial_data.anova_p = p;
trial_data.anova_tbl = tbl;
trial_data.anova_stats = stats;

% Tuning index

r_min = min(FR_plot);
r_max = max(FR_plot);
tun_index = (r_max-r_min)/(r_max+r_min);
trial_data.tuning_index = tun_index;


%%% Get baseline (fixation period) firing rate %%%

trial_starts = nan(1,num_trials);
fix_time_evs = nan(1,num_trials);

counter_c = 1;

for x = 1:num_trials
    trial_starts(1,x) = trial_ev(x).tr_ev_time(1);
    fix_time_evs(1,x) = trial_ev(x).tr_ev_time(2);
    
    offset = length(trial_ev(x).spikes); 
    all_spikes(1,counter_c:counter_c-1+offset) = trial_ev(x).spikes;
    counter_c = counter_c + offset;
end

bl_start = max(trial_starts);     % Only collect spikes from timepoints included in all trials
bl_end = min(fix_time_evs);
bl_length = (bl_end-bl_start)/1000; % Find length of baseline period in sec

num_spikes = numel(all_spikes);
counter_d = 1;

for y = 1:num_spikes
    if all_spikes(y) > bl_start && all_spikes(y) < bl_end
       bl_spikes(counter_d) = all_spikes(y);
       
       counter_d = counter_d + 1;
    end
end

bl_numspikes = numel(bl_spikes);
bl_firing_rate = (bl_numspikes/num_trials)*(1/bl_length);     % Avg spike count divided by 

[bl_edges,bl_spks_hist] = psth(bl_spikes,num_trials,0,10,'array');  % set bin width 15ms
   
baseline_data = struct;
baseline_data.firing_rate = bl_firing_rate;
baseline_data.period_length = bl_length;
baseline_data.spikes = bl_spikes;
baseline_data.starttime = bl_start;
baseline_data.endtime = bl_end;
baseline_data.num_trials = num_trials;
baseline_data.psth_edges = bl_edges;
baseline_data.psth_hist = bl_spks_hist;  

% Save structures

save(strcat(path,'/heading_tuning/',set_dir,'head_trials'),'head_trials');
save(strcat(path,'/heading_tuning/',set_dir,'baseline_data'),'baseline_data');
save(strcat(path,'/heading_tuning/',set_dir,'trial_data'),'trial_data');
end