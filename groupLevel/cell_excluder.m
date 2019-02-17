function [included_cells,cell_stats,excluded_cells,reasons] = cell_excluder(path,monkey,thresh)

% Searches monkey's directory for cell directories and excludes cells based
% heading tuning during test trials, fit of von Mises function, number of
% trial repeats, and isolation quality

cell_dirs = dir([path,'/',monkey,'*']);
cells = cell(numel(cell_dirs),1);
for i = 1:numel(cell_dirs)
    cells{i} = cell_dirs(i).name;
end

anova_thresh = thresh(1);
r_sqr_thresh = thresh(2);
num_reps_thresh = thresh(3);
lockout_thresh = thresh(4);
num_subreps = thresh(5);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cell_sort1 = struct;
count = 1;
count2 = 1;
excluded_cells1 = [];

% Select only cells with completed BH single cell analysis
for i = 1:numel(cells)
    if exist([path,'/',cells{i},'/bh_tests/set_merge_monoc/bh_trials.mat'],'file') ~= 0 || ...
       exist([path,'/',cells{i},'/bh_tests/set_merge_binoc/bh_trials.mat'],'file') ~= 0 && ...
       exist([path,'/',cells{i},'/heading_tuning'],'dir') ~= 0 && ...
       exist([path,'/',cells{i},'/pursuit_tuning'],'dir') ~= 0
        
        cell_sort1(count).name = cells{i};
        
        % Check for monocular tests and collect data
        if exist([path,'/',cells{i},'/bh_tests/set_merge_monoc'],'dir') ~= 0
            cell_sort1(count).monoc_tests = 1;
        else
            cell_sort1(count).monoc_tests = 0;
        end
        
        % Check for binocular tests and collect data
        if exist([path,'/',cells{i},'/bh_tests/set_merge_binoc'],'dir') ~= 0
            cell_sort1(count).binoc_tests = 1;  
        else
            cell_sort1(count).binoc_tests = 0;
        end
        
        count = count + 1;
    else
        % Collect excluded cells
        excluded_cells1{count2,1} = cells{i};
        excluded_cells1{count2,2} = 'Incomplete dataset';
        
        count2 = count2 + 1;
    end
end

num_cells1 = numel(cell_sort1); % Number of cells with complete datasets

% Collect neuron stats
cell_stats = struct;
type = {'monoc','binoc'};

wait_handle = waitbar(0,[0,num2str(num_cells1)],'Name','Running Cell:');
set(findall(wait_handle,'type','text'),'Interpreter','none'); % Turn off TeX interpreter for underscore

for i = 1:numel(cell_sort1)
    waitbar(i/num_cells1,wait_handle,[num2str(i),'/',num2str(num_cells1),' (',cell_sort1(i).name,')'])
    
    cell_stats(i).name = cell_sort1(i).name;
    
    if cell_sort1(i).monoc_tests  == 1 && cell_sort1(i).binoc_tests == 1
        num_eyes = [1 2];
    elseif cell_sort1(i).monoc_tests == 1 && cell_sort1(i).binoc_tests == 0
        num_eyes = 1;
    elseif cell_sort1(i).binoc_tests == 1 && cell_sort1(i).monoc_tests == 0
        num_eyes = 2;
    end
    
    for f = 1:numel(num_eyes)
        monobino = num_eyes(f);
        
        % Load in data
        k = load([path,'/',cell_sort1(i).name,'/bh_tests/set_merge_',type{monobino},'/bh_trials.mat']);
        bh_trials = k.bh_trials;
        
        k = load([path,'/',cell_sort1(i).name,'/bh_tests/set_merge_',type{monobino},'/trial_data.mat']);
        trial_data = k.trial_data;
        
        k = load([path,'/',cell_sort1(i).name,'/bh_tests/set_merge_',type{monobino},'/data_fits/data_table.mat']);
        data_table = k.data_table;
        
        % Find number of original sets, collect autocorr data
        set_total = trial_data.original_sets;
        
        lockouts = nan(1,numel(set_total));
        
        for h = 1:numel(lockouts)
            if exist([set_total{h},'/neuron_statistics.mat'],'file') ~= 0
                k = load([set_total{h},'/neuron_statistics.mat']);
                lockouts(1,h) = k.neuron_statistics.autoCorr(1,200);   % Collect correlations at 1ms
            else
                error(['Neuron stats not found at: ',set_total{h},'/neuron_statistics.mat']);
            end
        end
        
        % Run Welch's ANOVA on fixation heading tuning (i.e. find Sig modulation by
        % heading direction changes)
        count = 1;
        x = [];
        
        % Build mn x 2 matrix where m is number of angles and n is num repeats
        % Column 1: FR values, Column 2: Heading direction ID
        for j = 1:trial_data.num_trials/7 % num angles
            x(count:count+numel(bh_trials(1+(j-1)*7).rep_means)-1,1:2) = ...
                [bh_trials(1+(j-1)*7).rep_means j*ones(numel(bh_trials(1+(j-1)*7).rep_means),1)];
            
            count = count+numel(bh_trials(1+(j-1)*7).rep_means); % advance count by num repeats
        end
        p = welchanova(x);
        
        if monobino == 1
            % Get largest lockout period (1ms) autocorrelation value in all
            % trials
            cell_stats(i).monoc.lockout = max(lockouts);
            
            % Get trial type with min number of repeats
            cell_stats(i).monoc.repeats = min(trial_data.reps);
            cell_stats(i).monoc.num_subthresh_reps = ...
                sum(trial_data.reps<num_reps_thresh);
            
            % Get minimum coefficient of determination (r^2)
            % cell_stats(i).monoc.rsqr=min(cell2mat(data_table(2:8,6)));
            % use r_sqr of fixation trials instead...
            cell_stats(i).monoc.rsqr = cell2mat(data_table(2,6));
            
            % Get p-value for Welch ANOVA
            cell_stats(i).monoc.welch_anova = p;
            
        elseif monobino == 2
            % Get autocorrelation lockout
            cell_stats(i).binoc.lockout = max(lockouts);
            
            % Get trial type with min number of repeats
            cell_stats(i).binoc.repeats = min(trial_data.reps);
            cell_stats(i).binoc.num_subthresh_reps = ...
                sum(trial_data.reps<num_reps_thresh);
            
            % Get minimum coefficient of determination (r^2)
            cell_stats(i).binoc.rsqr = cell2mat(data_table(2,6));
            
            % Get p-value for Welch ANOVA
            cell_stats(i).binoc.welch_anova = p;
        end
    end
end

delete(wait_handle);

% Output cells that pass all inclusion criteria

thresholding_results = zeros(numel(cell_sort1),2);
reasons = nan(numel(cell_sort1),8);

for i = 1:numel(cell_sort1)
    if cell_sort1(i).monoc_tests  == 1 && cell_sort1(i).binoc_tests == 1
        num_eyes = [1 2];
    elseif cell_sort1(i).monoc_tests == 1 && cell_sort1(i).binoc_tests == 0
        num_eyes = 1;
    elseif cell_sort1(i).binoc_tests == 1 && cell_sort1(i).monoc_tests == 0
        num_eyes = 2;
    end
    
    for f = 1:numel(num_eyes)
        monobino = num_eyes(f);
        
        if monobino == 1
            a = 0;
            b = 0;
            c = 0;
            d = 0;
            reasons(i,1:4)=0;
            
            if cell_stats(i).monoc.welch_anova <= anova_thresh
                a = 1;
                reasons(i,1) = 1;
            end
            if cell_stats(i).monoc.rsqr >= r_sqr_thresh
                b = 1;
                reasons(i,2) = 1;
            end
%             if cell_stats(i).monoc.repeats >= num_reps_thresh
%                 c = 1;
%                 reasons(i,3) = 1;
%             end
            if cell_stats(i).monoc.num_subthresh_reps <= num_subreps
                c = 1;
                reasons(i,3) = 1;
            end
            if cell_stats(i).monoc.lockout <= lockout_thresh
                d = 1;
                reasons(i,4) = 1;
            end
            thresholding_results(i,1) = a*b*c*d;
        elseif monobino == 2
            a2 = 0;
            b2 = 0;
            c2 = 0;
            d2 = 0;
            reasons(i,5:8) = 0;
            
            if cell_stats(i).binoc.welch_anova <= anova_thresh
                a2 = 1;
                reasons(i,5) = 1;
            end
            if cell_stats(i).binoc.rsqr >= r_sqr_thresh
                b2 = 1;
                reasons(i,6) = 1;
            end
%             if cell_stats(i).binoc.repeats >= num_reps_thresh
%                 c2 = 1;
%                 reasons(i,7) = 1;
%             end
            if cell_stats(i).binoc.num_subthresh_reps <= num_subreps
                c2 = 1;
                reasons(i,7) = 1;
            end
            if cell_stats(i).binoc.lockout <= lockout_thresh
                d2 = 1;
                reasons(i,8) = 1;
            end
            thresholding_results(i,2) = a2*b2*c2*d2;
        end
    end
end

% Summary plots
counter = 1;
for i = 1:numel(cell_stats)
    if ~isempty(cell_stats(i).binoc)
        all_lockouts(counter) = cell_stats(i).binoc.lockout;
        all_repeats(counter) = cell_stats(i).binoc.repeats;
        all_rsqrs(counter) = cell_stats(i).binoc.rsqr;
        all_anova(counter) = cell_stats(i).binoc.welch_anova;
        
        counter = counter + 1;
    end
    if ~isempty(cell_stats(i).monoc)
        all_lockouts(counter) = cell_stats(i).monoc.lockout;
        all_repeats(counter) = cell_stats(i).monoc.repeats;
        all_rsqrs(counter) = cell_stats(i).monoc.rsqr;
        all_anova(counter) = cell_stats(i).monoc.welch_anova;
                
        counter = counter + 1;
    end
end

lockplot = figure; hold on;
set(gcf,'Position',[130 540 560 420]);
h1 = histogram(round(all_lockouts,5),15);
plot([lockout_thresh lockout_thresh],[0 1.05*max(h1.Values)],'--k');
set(gca,'YLim',[0 1.05*max(h1.Values)]);
title('Spiketrain Autocorrelation at 1ms');
ylabel('Number of Occurences');
xlabel('Correlation');

repplot = figure; hold on;
set(gcf,'Position',[130 15 560 420]);
h2 = histogram(all_repeats,'BinMethod','integers');
plot([num_reps_thresh num_reps_thresh],[0 1.05*max(h2.Values)],'--k');
set(gca,'YLim',[0 1.05*max(h2.Values)]);
title('Minimum Number of Repeats per Condition');
ylabel('Number of Occurences');
xlabel('Number of Repeats');

rsqrplot = figure; hold on;
set(gcf,'Position',[700 540 560 420]);
h3 = histogram(round(all_rsqrs,5),15);
plot([r_sqr_thresh r_sqr_thresh],[0 1.05*max(h3.Values)],'--k');
set(gca,'YLim',[0 1.05*max(h3.Values)]);
title('Von Mises Fit Coefficient of Determination');
ylabel('Number of Occurences');
xlabel('R^2 Value');

anovaplot = figure; hold on;
set(gcf,'Position',[700 15 560 420]);
h4 = histogram(round(all_anova,5),15);
plot([anova_thresh anova_thresh],[0 1.05*max(h4.Values)],'--k');
set(gca,'YLim',[0 1.05*max(h4.Values)]);
title('Welch ANOVA Significance for Fixation Condition');
ylabel('Number of Occurences');
xlabel('p Value');

if ~exist([path,'population_data/summary_stats'],'dir')
    mkdir([path,'population_data/summary_stats']);
end

hgsave(lockplot,[path,'population_data/summary_stats/autocorr_lockout']);
hgsave(repplot,[path,'population_data/summary_stats/num_repeats']);
hgsave(rsqrplot,[path,'population_data/summary_stats/fit_rsqr']);
hgsave(anovaplot,[path,'population_data/summary_stats/anova_stats']);

% Collect all included cells into cell array
cell_sort2 = sum(thresholding_results');

included_inds = find(cell_sort2>0);

included_cells = cell(numel(included_inds),3);

for i = 1:numel(included_inds)
    included_cells{i,1} = cell_sort1(included_inds(i)).name;
    if thresholding_results(included_inds(i),2)
        included_cells{i,2} = 'binocular';
    end
    if thresholding_results(included_inds(i),1)
        included_cells{i,3} = 'monocular';
    end
end

% Collect all reasons why cells were excluded and assemble into cell array
exclusion_reasons = {'ANOVA failure','Poor gaussian fit','Too few trials','Poor isolation'};

excluded_inds = find(cell_sort2 == 0);

excluded_cells2 = cell(numel(excluded_inds),3);
excluded_cells2{1,1} = 'Cell';
excluded_cells2{1,2} = 'Monoc';
excluded_cells2{1,3} = 'Binoc';

for i = 1:numel(excluded_inds)
    excluded_cells2{i+1,1} = cell_sort1(excluded_inds(i)).name;
    
    exc_reas_mon = find(reasons(excluded_inds(i),1:4)  ==  0);
    exc_reas_bin = find(reasons(excluded_inds(i),5:end)  ==  0);
    
    if ~isempty(exc_reas_mon)
        % Monoc
        excluded_cells2{i+1,2} = exclusion_reasons{exc_reas_mon(1)};
        
        if numel(exc_reas_mon>1)
            for j = 2:numel(exc_reas_mon)
                excluded_cells2{i+1,2} = [excluded_cells2{i+1,2},', ',exclusion_reasons{exc_reas_mon(j)}];
            end
        end
    end
    
    if ~isempty(exc_reas_bin)
        % Binoc
        excluded_cells2{i+1,3} = exclusion_reasons{exc_reas_bin(1)};
        
        if numel(exc_reas_bin>1)
            for j = 2:numel(exc_reas_bin)
                excluded_cells2{i+1,3} = [excluded_cells2{i+1,3},', ',exclusion_reasons{exc_reas_bin(j)}];
            end
        end
    end
end

% Combine cells excluded due to incomplete datasets and those due to not
% passing threshold criteria
excluded_cells1 = [excluded_cells1 cell(size(excluded_cells1,1),1)];
excluded_cells = [excluded_cells2;excluded_cells1];

% Gotta figure out way to sort by strings
% excluded_cells=[excluded_cells(1,:);sortrows(excluded_cells(2:end,:))];

save([path,'/population_data/excluded_cells'],'excluded_cells');
save([path,'/population_data/included_cells'],'included_cells');
save([path,'/population_data/cell_stats'],'cell_stats');

keyboard;

end
