function [trial_ev,trialvals] = trial_ID_harmony(trial_ev)

% Sort out combined trial_data structure (trial IDs and parameters)

tot_numtrials = numel(trial_ev);

pur_dirs = zeros(1,tot_numtrials);
azimuths = zeros(1,tot_numtrials);
pur_types = zeros(1,tot_numtrials);
elevations = zeros(1,tot_numtrials);

for i = 1:tot_numtrials;
    if isnan(trial_ev(i).pur_dir)
        pur_dirs(i) = 0;
    else
        pur_dirs(i) = trial_ev(i).pur_dir;
    end
    azimuths(i) = trial_ev(i).head_az;
    elevations(i) = trial_ev(i).head_el;
    pur_types(i) = trial_ev(i).pur_type;
end

trial_params = [azimuths' pur_types' pur_dirs' elevations'];

[trialvals,ia,trial_ids] = unique(trial_params,'rows'); % unique fails for nans

id_range = 0:1:numel(ia)-1;   % Start ID index from 0 to match rex output

trial_ids = trial_ids-1;
trialvals = [id_range' trialvals];

for i = 1:tot_numtrials
    trial_ev(i).tr_type = trial_ids(i);
end

end