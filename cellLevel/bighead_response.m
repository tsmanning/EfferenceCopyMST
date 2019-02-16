function [trial_ev] = bighead_response(path,test_set,num_eyes,single_plane)

% Extracts event and spike times from sorted data and zeros timepoints to
% start of translation stimulus

viewing_opts = {'monoc','binoc'};

if test_set~=0 && ischar(test_set) == 0
    set_no = num2str(test_set);
    set_dir = ['set',set_no,'/'];
elseif test_set == 0
    set_dir = '';
elseif test_set == 'm'
    set_dir = ['set_merge_',viewing_opts{num_eyes},'/'];
end

% Load in Data

load(strcat(path,'/bh_tests/',set_dir,'trials_ecad'))
load(strcat(path,'/bh_tests/',set_dir,'trials'))
load(strcat(path,'/bh_tests/',set_dir,'idata'))
load(strcat(path,'/bh_tests/',set_dir,'spikes'))
load(strcat(path,'/bh_tests/',set_dir,'ecad'))

% Find number of unique trials and trial parameters

[values,index,~] = unique(trials(:,2));
num_trials = length(values);

for i = 1:num_trials
    if trials(index(i),7) == 0
        trial_dir(i,1) = nan;
    else
        trial_dir(i,1) = trials(index(i),6);
    end
    trial_az(i,1) = trials(index(i),3);
    trial_el(i,1) = trials(index(i),4);
    purs_type(i,1) = trials(index(i),9);
end

trial_data = struct;
trial_data.trial_dir = trial_dir;
trial_data.trial_az = trial_az;
trial_data.trial_el = trial_el;
trial_data.purs_type = purs_type;
trial_data.num_trials = num_trials;
trial_data.pursuit_speed = max(trials(:,7))*120;   %  Pursuit speed in deg/sec for 120Hz
trial_data.heading_speed = trials(1,5)*(120/10);   %  Heading speed in cm/sec for 120Hz

if single_plane
    trial_data.single_plane = 1;
else
    trial_data.single_plane = 0;
end

% Extract event times for trial

% Event Codes:
% 1560  D   Dots on
% 1561  S   Translation start
% 1562  A   Pursuit pause
% 1563  C   Pursuit pre-start
% 1564  P   Pursuit start
% 1565  B   Pursuit blink start
% 1566  G   Pursuit blink end
% 1166  T   Trial Start
% 1181  Y   Trial completed successfully
% 1184  F   Fixation
% 1030  R   Reward
% 1570  I   EVLOOP Wait
% 1571  J   EVLOOP Fill
% 1572  K   EVLOOP Saccade
% 1573  L   EVLOOP Delay
% 65537 H   REX Saccade identified - Horizontal
% 65538 V   REX Saccade identified - Vertical
% 34    v   Retinal correction - azimuth
% 35    w   Retinal correction - elevation
% 8     h   pursuit type     (0:None, 1:Pursuit, 2:Simulated, 3:RetStab)

codes = {'T','F','D','S','C','P','Y'};
codes_0purs = {'T','F','D','S','Y'};

trial_ev = struct;

% Setup Eye position lowpass filter (butterworth FIR,deg=6,cutoff=100Hz)
[b,a] = butter(6,0.1,'low');
gd = grpdelay(b,a);
D = floor(mean(gd(1:90)));   %best integer delay fit?

wait_handle = waitbar(0,[0,num2str(length(trials_ecad))],'Name','Running Trial:');

for M = 1:length(trials_ecad)
    waitbar(M/length(trials_ecad),wait_handle,[num2str(M),'/',num2str(length(trials_ecad))])
    
    if trials(M,7) == 0
        trial_ev(M).pur_dir = nan;
    else
        trial_ev(M).pur_dir = trials(M,6);
    end
    trial_ev(M).head_el = trials(M,4);
    trial_ev(M).head_az = trials(M,3);
    trial_ev(M).pur_type = trials(M,9);
    trial_ev(M).tr_type = trials(M,2);
    
    if trial_ev(M).pur_type == 0  % For no pursuit trials
        for N = 1:numel(codes_0purs)
            % Find specific events within string
            trial_ev(M).indpos(N) = strfind(trials_ecad(1,M).Str,codes_0purs{N});
            % Find event indices
            trial_ev(M).ev_ind(N) = trials_ecad(1,M).Strind(trial_ev(M).indpos(N));
            % Find event trial-wise times in ms
            trial_ev(M).ev_time(N) = double(ecad.Times(trial_ev(M).ev_ind(N)));
        end
        trial_ev(M).codes = codes_0purs;
    else
        for N = 1:numel(codes)
            % Find specific events within string
            trial_ev(M).indpos(N) = strfind(trials_ecad(1,M).Str,codes{N});
            % Find event indices
            trial_ev(M).ev_ind(N) = trials_ecad(1,M).Strind(trial_ev(M).indpos(N));
            % Find event trial-wise times in ms
            trial_ev(M).ev_time(N) = double(ecad.Times(trial_ev(M).ev_ind(N)));
        end
        trial_ev(M).codes = codes;
    end
    
    % Find ev times relative to translation start
    trial_ev(M).tr_ev_time = trial_ev(M).ev_time - trial_ev(M).ev_time(4);
    
    % Find spike times relative to translation start (could still optimize - run time is 0.012272 sec)
    vgood1 = spikes>trial_ev(M).ev_time(1);
    vgood2 = spikes<trial_ev(M).ev_time(end);
    vgood = vgood1.*vgood2;
    vecs = find(vgood~=0);
    trial_ev(M).spikes = spikes(vecs);
    
    trial_ev(M).fix_period = trial_ev(M).ev_time(2)-trial_ev(M).ev_time(1);
    fix_centered = trial_ev(M).spikes-trial_ev(M).ev_time(3); % Align to dots on
    
    counter2 = 1;
    for aa = 1:length(fix_centered)
        if fix_centered(aa)<=0
            trial_ev(M).fix_spikes(counter2) = fix_centered(aa);
            counter2 = counter2+1;
        end
    end
    
    if isfield(trial_ev(M),'spikes') == 0     % allow trials without spikes to pass (e.g. for eye position testing)
        trial_ev(M).spikes = [];
    else
        trial_ev(M).spikes = trial_ev(M).spikes-trial_ev(M).ev_time(4);
    end
    
    if isempty(trial_ev(M).spikes)  == 1
        trial_ev(M).fix_spikes = [];
    end
    
    % Add eye position data
    trial_ev(M).eye_pos = idata(:,:,M)';
    
    % Cut off any trailing garbage in eye position vector
    end_ind = find(trial_ev(M).eye_pos(3,:) == trial_ev(M).ev_time(end));
    trial_ev(M).eye_pos = trial_ev(M).eye_pos(:,1:end_ind);
    
    % Position signal pre-smoothing for V calculation
    trial_ev(M).smooth_posx = filter(b,a,[trial_ev(M).eye_pos(1,:),zeros(1,D)]);
    trial_ev(M).smooth_posx = trial_ev(M).smooth_posx(1+D:end);
    trial_ev(M).smooth_posy = filter(b,a,[trial_ev(M).eye_pos(2,:),zeros(1,D)]);
    trial_ev(M).smooth_posy = trial_ev(M).smooth_posy(1+D:end);
    
    fixInd = find(trial_ev(M).eye_pos(3,:) == trial_ev(M).ev_time(2));
    if ~isempty(fixInd)
        cut_vars2 = fixInd;
    end
    
    % Trim data pre-fixation + cutoff lowpass filter padding
    trial_ev(M).eye_pos = trial_ev(M).eye_pos(:,cut_vars2:end);
    trial_ev(M).smooth_posx = trial_ev(M).smooth_posx(:,cut_vars2:end-5);
    trial_ev(M).smooth_posy = trial_ev(M).smooth_posy(:,cut_vars2:end-5);
    
    % Zero time at translation start
    trial_ev(M).eye_pos(3,:) = trial_ev(M).eye_pos(3,:)-trial_ev(M).ev_time(4);
    
    % Calculate eye velocity data (symmetric difference quotient)
    velx = (trial_ev(M).smooth_posx(1,3:end)-trial_ev(M).smooth_posx(1,1:end-2))./2;
    vely = (trial_ev(M).smooth_posy(1,3:end)-trial_ev(M).smooth_posy(1,1:end-2))./2;
    trial_ev(M).eye_vel = sqrt(velx.^2+vely.^2);
    trial_ev(M).eye_vel(2,:) = trial_ev(M).eye_pos(3,2:end-6);
    trial_ev(M).eye_vel = [trial_ev(M).eye_vel(1,:)*1000;trial_ev(M).eye_vel(2,:)];   % Convert to deg/sec
end

% Find trials with retinal stabilization
rs_trials = find(trials(:,9) == 3);

for i = 1:numel(rs_trials)
    a = find(trials_ecad(rs_trials(i)).Str == 'v'); % bcode 34 (Retinal correction - azimuth)
    b = find(trials_ecad(rs_trials(i)).Str == 'w'); % bcode 35 (Retinal correction - elevation)
    
    c = trials_ecad(rs_trials(i)).Strind(a);
    d = trials_ecad(rs_trials(i)).Strind(b);
    
    trial_ev(rs_trials(i)).corr_times_raw = ecad.Times(c);
    
    trial_ev(rs_trials(i)).corr_times = ...
        trial_ev(rs_trials(i)).corr_times_raw - ...
        trial_ev(rs_trials(i)).corr_times_raw(1);
    trial_ev(rs_trials(i)).evcorr_times = ...
        trial_ev(rs_trials(i)).corr_times_raw - ...
        trial_ev(rs_trials(i)).ev_time(4);
    
    trial_ev(rs_trials(i)).az_corr_vals = ecad.Values(c);
    trial_ev(rs_trials(i)).el_corr_vals = ecad.Values(d);
end

delete(wait_handle);

% Resorts trials so they are ordered in number [az_angle pur_type pur_dir elevation]
% rex spits out trials with purs_type ordered 1,2,3,0 - this reorders trial
% index to make it 0,1,2,3 for compatibility with set_merge
[trial_ev] = trial_ID_harmony(trial_ev);

save([path,'/bh_tests/',set_dir,'trial_ev'],'trial_ev');
save([path,'/bh_tests/',set_dir,'trial_data'],'trial_data');
end