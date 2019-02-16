function [trial_ev] = pursuit_response(path,test_set)

% Smooths eye position data, calculates eye velocity, extracts event and
% spike data and aligns trials 

if test_set~=0
    set_no=num2str(test_set);
    set_dir=['set',set_no,'/'];
else
    set_dir='';
end

% Load in Data

load(strcat(path,'/pursuit_tuning/',set_dir,'trials_ecad'))
load(strcat(path,'/pursuit_tuning/',set_dir,'trials'))
load(strcat(path,'/pursuit_tuning/',set_dir,'idata'))
load(strcat(path,'/pursuit_tuning/',set_dir,'spikes'))
load(strcat(path,'/pursuit_tuning/',set_dir,'ecad'))

% Find number of unique trials and trial parameters

[values,index,~]=unique(trials(:,2));
num_trials=length(values);

if num_trials<max(values)
    warning('Not all conditions were run at least once for this paradigm. Exiting.')
    return
end

for i=1:num_trials
    trial_dir(i,1)=trials(index(i),6);
end
trial_data=struct;
trial_data.trial_dir=trial_dir;
trial_data.num_trials=num_trials;
trial_data.pursuit_speed=trials(1,7)*120;   %  Pursuit speed in deg/sec for 120Hz

% Extract event times for pursuit

% Event Codes:
% 1562  A   Pursuit pause
% 1563  C   Pursuit pre-start
% 1564  P   Pursuit start
% 1565  B   Pursuit blink start
% 1566  G   Pursuit blink end
% 1166  T   Trial Start
% 1181  Y   Trial completed successfully
% 1184  F   Fixation
% 1570  I   EVLOOP Wait 
% 1571  J   EVLOOP Fill

codes = {'T','F','A','C','P','B','G','Y'};
% codes = {'T','F','A','C','P','Y'};
numEcodes = numel(codes);
trial_ev = struct;

% Eye position lowpass filter (butterworth FIR,deg=6,cutoff=50Hz)
[b,a] = butter(6,0.1,'low');
gd = grpdelay(b,a);           
D = floor(mean(gd(1:90)));   %best integer delay fit?

for M = 1:length(trials)
    trial_ev(M).codes = codes;
    trial_ev(M).pur_dir = round(trials(M,6)); 
    for N = 1:numEcodes
        % find specific events within string
        trial_ev(M).indpos(N) = strfind(trials_ecad(1,M).Str,codes{N});
        % find event indices
        trial_ev(M).ev_ind(N) = trials_ecad(1,M).Strind(trial_ev(M).indpos(N));
        % find event trial-wise times in ms
        trial_ev(M).ev_time(N) = double(ecad.Times(trial_ev(M).ev_ind(N)));
               
    end
    % find ev times relative to pursuit start
    trial_ev(M).tr_ev_time=trial_ev(M).ev_time-trial_ev(M).ev_time(5);
    
    % Find trialwise spike times relative to pursuit start (allow empty
    % spike vectors)
    if ~isempty(spikes)
        trial_ev(M).spikes = [];
        
        spikeInds = and(spikes > trial_ev(M).ev_time(1),...
                        spikes < trial_ev(M).ev_time(8));
        trial_ev(M).spikes = spikes(spikeInds);
        
        if ~isempty(trial_ev(M).spikes)
            trial_ev(M).spikes = trial_ev(M).spikes - trial_ev(M).ev_time(5);
        end
    else
        trial_ev(M).spikes = [];
    end
    
    % add eye position data
    cut_vars=0;
    trial_ev(M).eye_pos=idata(:,:,M)';
    for w=1:length(trial_ev(M).eye_pos)
        if trial_ev(M).eye_pos(3,w)==0 && trial_ev(M).eye_pos(3,w-1)~=0
            cut_vars=w-1;
            break
        else
            cut_vars=length(trial_ev(M).eye_pos);
        end
    end
    trial_ev(M).eye_pos=trial_ev(M).eye_pos(:,1:cut_vars); %elminate zero entries
    
    % Position signal pre-smoothing for V calculation
    trial_ev(M).smooth_posx=filter(b,a,[trial_ev(M).eye_pos(1,:),zeros(1,D)]);
    trial_ev(M).smooth_posx=trial_ev(M).smooth_posx(1+D:end);
    trial_ev(M).smooth_posy=filter(b,a,[trial_ev(M).eye_pos(2,:),zeros(1,D)]);
    trial_ev(M).smooth_posy=trial_ev(M).smooth_posy(1+D:end);
    
    for x=1:length(trial_ev(M).eye_pos)
        if trial_ev(M).eye_pos(3,x)==trial_ev(M).ev_time(2)
            cut_vars2=x;
            break
        end
    end
    % include only data after fixation + cutoff lowpass filter errors
    trial_ev(M).eye_pos=trial_ev(M).eye_pos(:,cut_vars2:end);
    trial_ev(M).smooth_posx=trial_ev(M).smooth_posx(:,cut_vars2:end-5);
    trial_ev(M).smooth_posy=trial_ev(M).smooth_posy(:,cut_vars2:end-5);
    
    % zero time at pursuit initiation
    trial_ev(M).eye_pos(3,:)=trial_ev(M).eye_pos(3,:)-trial_ev(M).ev_time(5);
        
    % add eye velocity data
    velx=(trial_ev(M).smooth_posx(1,3:end)-trial_ev(M).smooth_posx(1,1:end-2))./2;
    vely=(trial_ev(M).smooth_posy(1,3:end)-trial_ev(M).smooth_posy(1,1:end-2))./2;
    trial_ev(M).eye_vel=sqrt(velx.^2+vely.^2);
    trial_ev(M).eye_vel(2,:)=trial_ev(M).eye_pos(3,2:end-6);
end

save(strcat(path,'/pursuit_tuning/',set_dir,'trial_ev'),'trial_ev');
save(strcat(path,'/pursuit_tuning/',set_dir,'trial_data'),'trial_data');
end