function [purs_trials,FR_plot,sem_plot]=pursuit_response_2(path,test_set)

% Reads in pursuit directions from data, calculates mean eye position and
% velocity, trial-wise spike density functions, and vector tuning

if test_set~=0
    set_no=num2str(test_set);
    set_dir=['set',set_no,'/'];
else
    set_dir='';
end

%% Load in Data
load(strcat(path,'/pursuit_tuning/',set_dir,'trial_ev'))
load(strcat(path,'/pursuit_tuning/',set_dir,'trial_data'))

codes = trial_ev(1).codes;
trial_start_ind = find(cellfun(@(x) x=='T',codes) == 1);
trial_end_ind = find(cellfun(@(x) x=='Y',codes) == 1);

purs_dirs = trial_data.trial_dir;
num_trial_types = trial_data.num_trials;
num_trials = length(trial_ev);

%% Sort by trial type
purs_trials =       struct;
lengths =           zeros(num_trials,2);
FR_plot =           zeros(1,num_trial_types);
FR_plot_blink=      zeros(1,num_trial_types);
allspikeCnt =       [];
allspikeCntB =      [];
std_plot =          zeros(1,num_trial_types);
std_plot_blink =    zeros(1,num_trial_types);

for N=1:num_trials
    lengths(N,1)=length(trial_ev(N).smooth_posx);
    lengths(N,2)=length(trial_ev(N).eye_vel);
end

for M=1:num_trial_types
    counter=1;
    for N=1:num_trials
        if trial_ev(N).pur_dir==purs_dirs(M)
            purs_trials(M).pur_dir=purs_dirs(M);
            purs_trials(M).posx(counter,1:length(trial_ev(N).smooth_posx))=trial_ev(N).smooth_posx;
            purs_trials(M).posy(counter,1:length(trial_ev(N).smooth_posy))=trial_ev(N).smooth_posy;
            purs_trials(M).vel(counter,1:length(trial_ev(N).eye_vel(1,:)))=trial_ev(N).eye_vel(1,:);
            purs_trials(M).ev_times(counter,1:length(trial_ev(N).tr_ev_time))=trial_ev(N).tr_ev_time;
            purs_trials(M).pos_timing(counter,1:length(trial_ev(N).eye_pos(3,1:end-5)))=trial_ev(N).eye_pos(3,1:end-5);
            purs_trials(M).pos_length(counter,1)=lengths(N,1);
            purs_trials(M).vel_length(counter,1)=lengths(N,2);
            
            counter=counter+1;
        end
    end
    purs_trials(M).vel_timing=purs_trials(M).pos_timing(:,2:end-1);
    
    % Sort spikes into trial types
    counter_B = 1;
    
    for N = 1:num_trials
        if trial_ev(N).pur_dir == purs_dirs(M)
            purs_trials(M).spikes{counter_B,1} = trial_ev(N).spikes;
            
            counter_B = counter_B + 1;
        end
    end
    
    % Find mean eye positions + SEMs
    purs_trials(M).mean_posx = mean(purs_trials(M).posx);
    purs_trials(M).sem_posx  = std(purs_trials(M).posx);
    purs_trials(M).mean_posy = mean(purs_trials(M).posy);
    purs_trials(M).sem_posy  = std(purs_trials(M).posy);
    
    % Generate spike time vectors (allowing for went time jitter)
    pursPreStart = min(purs_trials(M).ev_times(:,2));
    trialEnd = max(purs_trials(M).ev_times(:,end));
    
    purs_trials(M).spike_timevec = pursPreStart:1:trialEnd;
    z = numel(purs_trials(M).spike_timevec);
    s = numel(purs_trials(M).spikes);
    
    purs_trials(M).spike_vectors = zeros(s,z);
    
    for i = 1:s
        spikeInds = purs_trials(M).spikes{i};
        incSpikes = and(spikeInds>=pursPreStart,spikeInds<=trialEnd);
        spikeInds = spikeInds(incSpikes);
        spikeInds = spikeInds + 1 + -1*pursPreStart;
        
        purs_trials(M).spike_vectors(spikeInds) = 1;
    end

    purs_trials(M).mean_spikes = mean(purs_trials(M).spike_vectors);
    purs_trials(M).sem_spikes = std(purs_trials(M).spike_vectors);
    
    %     % Convolve mean raster with gaussian
    %     dt=1;   % size of sampling rate bins - 1ms here for 1kHz sampling rate)
    %     sigma=15;   % set sigma to 15ms
    %     gauss_duration=3*sigma*2;   % captures ~99.8% of area under the kernal
    %     gauss_t=-gauss_duration/2:dt:gauss_duration/2;  % creates time vector for gaussian at same sampling rate, centered at zero
    %
    %     gauss=1/sqrt(2*pi*sigma^2)*exp(-gauss_t.^2/(2*sigma^2));
    %
    %     purs_trials(M).spike_dens_plot=conv(purs_trials(M).mean_spikes,gauss,'same')*1000;
    %     purs_trials(M).spike_dens_plot_sem=conv(purs_trials(M).sem_spikes,gauss,'same')*1000;
    %     % Multiply by 1000 to convert vertical axis to Hz
    
    % Find trial PSTH
    [edges,spks_hist] = psth(purs_trials,M,0,20);
    
    if ~isempty(edges)
        purs_trials(M).psth_edges = edges;
        purs_trials(M).psth_hist = spks_hist;
    else
        purs_trials(M).psth_edges = 0;
        purs_trials(M).psth_hist = 0;
    end
    
    % Find spike rate mean and std for pursuit tuning
    if ~isempty(purs_trials(M).spikes)
        spikeCnt = nan(s,1);
        spikeCntB = nan(s,1);
        
        for i = 1:s
            spikeInds = purs_trials(M).spikes{i};
            % introduce 50ms visual delay for spike count window
            blinkStart = purs_trials(M).ev_times(i,6) + 50;
            blinkEnd = purs_trials(M).ev_times(i,7) + 50;
            
            incSpikes = and(spikeInds>0,spikeInds<=trialEnd);
            incSpikesB = and(spikeInds>blinkStart,spikeInds<=blinkEnd);
            spikeCnt(i) = sum(incSpikes);
            spikeCntB(i) = sum(incSpikesB);
        end
        
        pursEpochDur                  = trialEnd - 0;
        blinkEpochDur                 = blinkEnd - blinkStart;
        purs_trials(M).mean_FR        = mean(spikeCnt)/(pursEpochDur/1000);
        purs_trials(M).std_FR         = std(spikeCnt)/(pursEpochDur/1000);
        purs_trials(M).mean_FR_blink  = mean(spikeCntB)/(blinkEpochDur/1000);
        purs_trials(M).std_FR_blink   = std(spikeCntB)/(blinkEpochDur/1000);
    else
        purs_trials(M).mean_FR       = 0;
        purs_trials(M).mean_FR_blink = 0;
        purs_trials(M).std_FR        = 0;
        purs_trials(M).std_FR_blink  = 0;
    end
    
    FR_plot(M)          = purs_trials(M).mean_FR;
    FR_plot_blink(M)    = purs_trials(M).mean_FR_blink;
    std_plot(M)         = purs_trials(M).std_FR;
    std_plot_blink(M)   = purs_trials(M).std_FR_blink;

    spikeCnt = [spikeCnt purs_trials(M).pur_dir.*ones(numel(spikeCnt),1)];
    spikeCntB = [spikeCntB purs_trials(M).pur_dir.*ones(numel(spikeCntB),1)];
    
    allspikeCnt     = [allspikeCnt;spikeCnt];
    allspikeCntB    = [allspikeCnt;spikeCntB];
end

trial_data.std_plot         = std_plot;
trial_data.FR_plot          = FR_plot;
trial_data.std_plot_blink   = std_plot_blink;
trial_data.FR_plot_blink    = FR_plot_blink;

%% Get max FR for scaling purposes
for ind=1:num_trial_types
    max_frs_psth(ind,:)=max(purs_trials(ind).psth_hist);
end

trial_data.max_fr=max(max_frs_psth);
%% Run tuning statistics

% One-way ANOVA
[trial_data.p,trial_data.anova_tbl,trial_data.anova_stats] = ...
    anova1(allspikeCnt(:,1),allspikeCnt(:,2),'off');
[trial_data.pBlink,trial_data.anova_tblBlink,trial_data.panova_statsBlink] = ...
    anova1(allspikeCntB(:,1),allspikeCntB(:,2),'off');

% Tuning index
r_min = min(FR_plot);
r_max = max(FR_plot);
trial_data.tuning_index = (r_max-r_min)/(r_max+r_min);
clear r_min r_max

r_min = min(FR_plot_blink);
r_max = max(FR_plot_blink);
trial_data.tuning_index_blink = (r_max-r_min)/(r_max+r_min);


%% Get baseline (fixation period) firing rate

trial_starts = nan(1,num_trials);
fix_time_evs = nan(1,num_trials);

counter_c = 1;

for x = 1:num_trials
    trial_starts(1,x) = trial_ev(x).tr_ev_time(1);
    fix_time_evs(1,x) = trial_ev(x).tr_ev_time(2);
    
    offset                                     = length(trial_ev(x).spikes);
    all_spikes(1,counter_c:counter_c-1+offset) = trial_ev(x).spikes;
    counter_c                                  = counter_c+offset;
end

% Only collect spikes from timepoints included in all trials
bl_start    = max(trial_starts);
bl_end      = min(fix_time_evs);
bl_length   = (bl_end-bl_start)/1000; % Duration of baseline period in sec

if ~isempty(all_spikes)     % for debug purposes
    blInds = and(all_spikes>bl_start,all_spikes<bl_end);
    bl_spikes = all_spikes(blInds);
else
    bl_spikes=[];
end

% Get average spike rate
bl_numspikes = numel(bl_spikes);
bl_firing_rate = (bl_numspikes/num_trials)*(1/bl_length);

baseline_data=struct;

if ~isempty(all_spikes)
    [bl_edges,bl_spks_hist] = ...
        psth(bl_spikes,num_trials,0,10,'array');  % set bin width 15ms
    
    baseline_data.psth_edges=bl_edges;
    baseline_data.psth_hist=bl_spks_hist;
end

baseline_data.firing_rate=bl_firing_rate;
baseline_data.period_length=bl_length;
baseline_data.spikes=bl_spikes;
baseline_data.starttime=bl_start;
baseline_data.endtime=bl_end;
baseline_data.num_trials=num_trials;

% Save structures

save(strcat(path,'/pursuit_tuning/',set_dir,'purs_trials'),'purs_trials');
save(strcat(path,'/pursuit_tuning/',set_dir,'trial_data'),'trial_data');
save(strcat(path,'/pursuit_tuning/',set_dir,'baseline_data'),'baseline_data');
end