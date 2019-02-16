function [trial_ev] = heading_response(path,test_set)

% Extracts event and spike times from sorted data and zeros timepoints to 
% start of translation stimulus

if test_set~=0
    set_no=num2str(test_set);
    set_dir=['set',set_no,'/'];
else
    set_dir='';
end

% Load in Data

load([path,'/heading_tuning/',set_dir,'trials_ecad'])
load([path,'/heading_tuning/',set_dir,'trials'])
load([path,'/heading_tuning/',set_dir,'spikes'])
load([path,'/heading_tuning/',set_dir,'ecad'])

% Find number of unique trials and trial parameters

[values,index,~]=unique(trials(:,2));
num_trials=length(values);
for i=1:num_trials
    trial_az(i,1)=trials(index(i),3);
    trial_el(i,1)=trials(index(i),4);
end
trial_data=struct;
trial_data.trial_az=trial_az;
trial_data.trial_el=trial_el;
trial_data.num_trials=num_trials;
trial_data.heading_speed=trials(1,5)*(120/10);   %  Heading speed in cm/sec for 120Hz

% Extract event times for heading

% Event Codes:
% 1560  D   Dots on
% 1561  S   Translation start
% 1166  T   Trial Start
% 1184  F   Fixation
% 1181  Y   Trial completed successfully

codes={'T','F','D','S','Y'};
trial_ev=struct;

for M=1:length(trials_ecad)
    trial_ev(M).codes=codes;
    trial_ev(M).head_el=trials(M,4);
    trial_ev(M).head_az=trials(M,3);
    trial_ev(M).tr_type=trials(M,2);
    
    for N=1:length(codes)
        %find specific events within string
        trial_ev(M).indpos(N)=strfind(trials_ecad(1,M).Str,codes{N});
        %find event indices
        trial_ev(M).ev_ind(N)=trials_ecad(1,M).Strind(trial_ev(M).indpos(N));
        %find event trial-wise times in ms
        trial_ev(M).ev_time(N)=double(ecad.Times(trial_ev(M).ev_ind(N)));
    end
    
    %find ev times relative to translation start
    trial_ev(M).tr_ev_time=trial_ev(M).ev_time-trial_ev(M).ev_time(4);
    
    %find spike times relative to translation start
    counter=1;
    trial_ev(M).spikes=[];
    for p=1:length(spikes)
        if spikes(p)>trial_ev(M).ev_time(1) && spikes(p)<trial_ev(M).ev_time(5)
            trial_ev(M).spikes(counter)=spikes(p);
            counter=counter+1;
        end
    end
    if isempty(trial_ev(M).spikes)~=1
    trial_ev(M).spikes=trial_ev(M).spikes-trial_ev(M).ev_time(4);
    end
end

save([path,'/heading_tuning/',set_dir,'trial_ev'],'trial_ev');
save([path,'/heading_tuning/',set_dir,'trial_data'],'trial_data');
end