function [all_params,monoc,binoc,monobino] = bh_grouptune(path,plot_on,fit_cutoff)

% Collects fit parameters from single cells, plots distribution of heading
% and pursuit preferences across sample of neurons
%
% Usage: [all_params,monoc,binoc] = bh_grouptune(included_cells,plot_on)
% where plot_on controls plotter for heading/pursuit preference
% distribution in sample of included cells

%% Load in data
load([path,'population_data/included_cells'])

num_cells = size(included_cells,1);

%% Collect relevant single cell responses & parameter fits 
all_params = struct;
counter = 1;
counter2 = 1;
pairedcount = 1;

% data_table is a 7x7 matrix organized as follows
%     [No pursuit(angles 1:7);
%      Normal pursuit L (angles 1:7);
%      Simulated pursuit L (angles 1:7);
%      Stabilized Pursuit L (angles 1:7);
%      Normal Pursuit R (angles 1:7);
%      Simulated Pursuit R (angles 1:7);
%      Stabilized Pursuit R (angles 1:7)]

anymon = 0; % for next loops, see if any cells are monoc
anybin = 0;

for i = 1:num_cells
    monoculo = 0;
    binoculo = 0;
    
    %% Check for binocular dataset
    if ~isempty(included_cells{i,2})
        binoculo = 1;
        anybin = 1;
        binoc_inds(1,counter) = i;
        counter = counter + 1;
        
        % Fitting results
        k = load([path,'/',included_cells{i,1},'/bh_tests/set_merge_binoc/data_fits/data_table']);
        dat_tab = k.data_table;
        
        % Bighead results
        k3 = load([path,'/',included_cells{i,1},'/bh_tests/set_merge_binoc/trial_data']);
        dat_tab3 = k3.trial_data;
        trial_FRs_bino = k3.trial_data.trial_FRs;
        trialElBino = k3.trial_data.trial_el(1);
        trialAzBino = unique(k3.trial_data.trial_az);
        
        kpur = load([path,'/',included_cells{i,1},'/bh_tests/set_merge_binoc/pursQual']);
        purTabBino = kpur.pursQual;
        
        % Pursuit tuning data
        %%%%% should make this (and heading) so it takes heading set number from
        %%%%% full_group_analysis instad of autoselecting 2nd set
        if numel(dir([path,'/',included_cells{i,1},'/pursuit_tuning/set*']))>0
            k2 = load([path,'/',included_cells{i,1},'/pursuit_tuning/set2/trial_data']);  
            dat_tab2 = k2.trial_data;
        else
            k2 = load([path,'/',included_cells{i,1},'/pursuit_tuning/trial_data']);
            dat_tab2 = k2.trial_data;
        end
        
        % Get Heading Results/check for multiple sets
        if numel(dir([path,'/',included_cells{i,1},'/heading_tuning/set*']))>0
            k4 = load([path,'/',included_cells{i,1},'/heading_tuning/set2/head_trials']);
            dat_tab4 = k4.head_trials;
        else
            k4 = load([path,'/',included_cells{i,1},'/heading_tuning/head_trials']);
            dat_tab4 = k4.head_trials;
        end
    end
    
    %% Check for monocular dataset
    if ~isempty(included_cells{i,3})
        monoculo = 1;
        anymon = 1;
        monoc_inds(1,counter2) = i;
        counter2 = counter2 + 1;
        
        % Fitting results
        k5 = load([path,'/',included_cells{i,1},'/bh_tests/set_merge_monoc/data_fits/data_table']);
        dat_tab5 = k5.data_table;
        
        % Bighead results
        k6 = load([path,'/',included_cells{i,1},'/bh_tests/set_merge_monoc/trial_data']);
        dat_tab6 = k6.trial_data;
        trial_FRs_mono = k6.trial_data.trial_FRs;
        trialElMono = k6.trial_data.trial_el(1);
        trialAzMono = unique(k6.trial_data.trial_az);
        
        kpur2 = load([path,'/',included_cells{i,1},'/bh_tests/set_merge_monoc/pursQual']);
        purTabMono = kpur2.pursQual;
        
        if isempty(included_cells{i,2}) == 1  % Get PT/HT data if no binoc dataset
            % Pursuit tuning data
            if numel(dir([path,'/',included_cells{i,1},'/pursuit_tuning/set*']))>0
                k2 = load([path,'/',included_cells{i,1},'/pursuit_tuning/set2/trial_data']);
                dat_tab2 = k2.trial_data;
            else
                k2 = load([path,'/',included_cells{i,1},'/pursuit_tuning/trial_data']);
                dat_tab2 = k2.trial_data;
            end
            
            % Get Heading Results/check for multiple sets
            if numel(dir([path,'/',included_cells{i,1},'/heading_tuning/set*']))>0
                k4 = load([path,'/',included_cells{i,1},'/heading_tuning/set2/head_trials']);
                dat_tab4 = k4.head_trials;
            else
                k4 = load([path,'/',included_cells{i,1},'/heading_tuning/head_trials']);
                dat_tab4 = k4.head_trials;
            end
        end
    end
    
    if isempty(included_cells{i,2}) == 1 && isempty(included_cells{i,3}) == 1
        error(['No curve fit parameters found for cell ',included_cells{i}]);
    end
    
    if isempty(included_cells{i,2}) == 0 && isempty(included_cells{i,3}) == 0
        paired_cell_inds(1,pairedcount) = i;
        pairedcount = pairedcount + 1;
    end
    
    %% Collect data into big 'ol structure
    all_params(i).cellID          = included_cells{i};
    [~,max_ang]                 = max(dat_tab2.FR_plot);
    [~,min_ang]                 = min(dat_tab2.FR_plot);
    all_params(i).pref_purs     = dat_tab2.trial_dir(max_ang);
    all_params(i).null_purs     = dat_tab2.trial_dir(min_ang);
    all_params(i).tuning_index  = dat_tab2.tuning_index;
    
    % lr_index = (left - right pursuit)/(left + right pursuit)
    all_params(i).lr_index = (dat_tab2.FR_plot(5)-dat_tab2.FR_plot(1))/...
        (dat_tab2.FR_plot(5) + dat_tab2.FR_plot(1));
    all_params(i).lr_index_blink = (dat_tab2.FR_plot_blink(5)-dat_tab2.FR_plot_blink(1))/...
        (dat_tab2.FR_plot_blink(5) + dat_tab2.FR_plot_blink(1));
    
    % Collect monocular data if it exists
    if monoculo
        all_params(i).monoc.gains(1:7,1)     = cell2mat(dat_tab5(2:8,2));
        all_params(i).monoc.offsets(1:7,1)   = cell2mat(dat_tab5(2:8,3));
        all_params(i).monoc.az_tuning(1:7,1) = cell2mat(dat_tab5(2:8,4));
        all_params(i).monoc.bandwidth(1:7,1) = cell2mat(dat_tab5(2:8,5));
        all_params(i).monoc.r_squared(1:7,1) = cell2mat(dat_tab5(2:8,6));
        all_params(i).monoc.mean_dirFRs      = dat_tab6.fr_plot_HP;
        all_params(i).monoc.std_dirFRs       = dat_tab6.std_plot_HP;
        all_params(i).monoc.trial_FRs        = trial_FRs_mono;
        all_params(i).monoc.elevation        = trialElMono;
        all_params(i).monoc.azimuth          = trialAzMono;
        
        % NaN out params from bad fits
        poorfits = find(all_params(i).monoc.r_squared < fit_cutoff);
        all_params(i).monoc.gains(poorfits)     = nan;
        all_params(i).monoc.offsets(poorfits)   = nan;
        all_params(i).monoc.az_tuning(poorfits) = nan;
        all_params(i).monoc.bandwidth(poorfits) = nan;
        
        % Collect summary data about pursuit quality
        types = purTabMono.tr_type;
        numTypes = max(types)+1;
        
        matoSacs = nan(7,7);
        matoGains = nan(7,7);
        
        for fi = 1:numTypes
            typeInds = types == fi-1;
            
            matoSacs(fi) = mean(purTabMono.numSaccades(typeInds));
            matoGains(fi) = mean(purTabMono.gain(typeInds));
        end
        
        matoSacs = matoSacs([1 3 2 5 4 7 6],:);
        matoGains = matoGains([1 3 2 5 4 7 6],:);
        
        saccMeans = mean(matoSacs,2);
        all_params(i).monoc.meanNumSacc = saccMeans';
        
        gainMeans = mean(matoGains,2);
        all_params(i).monoc.meanGain = gainMeans';
        
        all_params(i).monoc.meanHVelError   = mean(purTabMono.signedVelError(:,1));
        all_params(i).monoc.meanVVelError   = mean(purTabMono.signedVelError(:,2));
    end
    
    % Collect binocular data if it exists
    if binoculo
        all_params(i).binoc.gains(1:7,1)        = cell2mat(dat_tab(2:8,2));
        all_params(i).binoc.offsets(1:7,1)      = cell2mat(dat_tab(2:8,3));
        all_params(i).binoc.az_tuning(1:7,1)    = cell2mat(dat_tab(2:8,4));
        all_params(i).binoc.bandwidth(1:7,1)    = cell2mat(dat_tab(2:8,5));
        all_params(i).binoc.r_squared(1:7,1)    = cell2mat(dat_tab(2:8,6));
        all_params(i).binoc.mean_dirFRs         = dat_tab3.fr_plot_HP;
        all_params(i).binoc.std_dirFRs          = dat_tab3.std_plot_HP;
        all_params(i).binoc.trial_FRs           = trial_FRs_bino;
        all_params(i).binoc.elevation           = trialElBino;
        all_params(i).binoc.azimuth             = trialAzBino;
        
        % NaN out params from bad fits
        poorfits = find(all_params(i).binoc.r_squared < fit_cutoff);
        all_params(i).binoc.gains(poorfits)     = nan;
        all_params(i).binoc.offsets(poorfits)   = nan;
        all_params(i).binoc.az_tuning(poorfits) = nan;
        all_params(i).binoc.bandwidth(poorfits) = nan;
        
        % Collect summary data about pursuit quality
        types = purTabBino.tr_type;
        numTypes = max(types)+1;
        numHeads = numTypes/7;
        
        matoSacs = nan(7,numHeads);
        matoGains = nan(7,numHeads);
        
        for fi = 1:numTypes
            typeInds = types == fi-1;
            
            matoSacs(fi) = mean(purTabBino.numSaccades(typeInds));
            matoGains(fi) = mean(purTabBino.gain(typeInds));
        end
        
        matoSacs = matoSacs([1 3 2 5 4 7 6],:);
        matoGains = matoGains([1 3 2 5 4 7 6],:);
        
        saccMeans = mean(matoSacs,2);
        all_params(i).binoc.meanNumSacc = saccMeans';
        
        gainMeans = mean(matoGains,2);
        all_params(i).binoc.meanGain = gainMeans';
        
        all_params(i).binoc.meanHVelError   = mean(purTabBino.signedVelError(:,1));
        all_params(i).binoc.meanVVelError   = mean(purTabBino.signedVelError(:,2));
    end
    
    % Find cell's preferred heading
    headFRs = nan(1,26);
    for j = 1:26
        headFRs(1,j) = dat_tab4(j).mean_FR;
    end
    
    [~,headindex] = max(headFRs);
    all_params(i).pref_head = [dat_tab4(headindex).head_az dat_tab4(headindex).head_el];
    
    % Define whether cell prefers backwards or forwards headings 
    % (forward = 1; backward = -1)
    if binoculo
        x = 'binoc';
    else
        x = 'monoc';    % should be the same for both, grab monoc if it exists
    end
    
    if all_params(i).(x).az_tuning(1)<90 || all_params(i).(x).az_tuning(1)>270
        all_params(i).backforw = 1;
    elseif all_params(i).(x).az_tuning(1)>90 && all_params(i).(x).az_tuning(1)<270
        all_params(i).backforw = -1;
    elseif all_params(i).(x).az_tuning(1)==90 || all_params(i).(x).az_tuning(1)==270
        all_params(i).backforw = 0;
    end
    
    % Define whether cell prefers leftwards or rightwards headings
    % (rightwards = 1; leftwards = 2; neither = 0)
    
    if all_params(i).(x).az_tuning(1)>0 && all_params(i).(x).az_tuning(1)<180
        all_params(i).rightleft = 1;
    elseif all_params(i).(x).az_tuning(1)==0 || all_params(i).(x).az_tuning(1)==180
        all_params(i).rightleft = 0;
    elseif all_params(i).(x).az_tuning(1)>180 && all_params(i).(x).az_tuning(1)<360
        all_params(i).rightleft = 2;
    elseif all_params(i).(x).az_tuning(1)>360 && all_params(i).(x).az_tuning(1)<540
        all_params(i).rightleft = 1;
    end
end

%% Create objects that hold monoc/binoc trial parameter fits
mEl = [];
bEl = [];

if anymon
    monoc = popData(all_params,monoc_inds,1);
end

if anybin
    binoc = popData(all_params,binoc_inds,2);
end

if anymon && anybin
    %% Create monoc/binoc paired comparison struct
    monobino = struct;
    num_paired_cells = numel(paired_cell_inds);
    binds = zeros(1,num_paired_cells);
    minds = zeros(1,num_paired_cells);
    
    for i = 1:num_paired_cells
        binds(i) = find(binoc_inds == paired_cell_inds(i));
        minds(i) = find(monoc_inds == paired_cell_inds(i));
    end
    
    for i = 1:num_paired_cells
        monobino.cellID{i,1}            = all_params(paired_cell_inds(i)).cellID;
        monobino.bin_gain_mat(i,:)      = binoc.gain_mat(binds(i),:);
        monobino.bin_offset_mat(i,:)    = binoc.offset_mat(binds(i),:);
        monobino.bin_band_mat(i,:)      = binoc.band_mat(binds(i),:);
        monobino.mon_gain_mat(i,:)      = monoc.gain_mat(minds(i),:);
        monobino.mon_offset_mat(i,:)    = monoc.offset_mat(minds(i),:);
        monobino.mon_band_mat(i,:)      = monoc.band_mat(minds(i),:);
        monobino.lr_index(i,1)          = monoc.lr_index(minds(i));
        monobino.lr_index_blink(i,1)    = monoc.lr_index_blink(minds(i));
        monobino.backforw(i,1)          = monoc.backforw(minds(i));
        
        monobino.bin_tuncent_mat(i,:)   = binoc.tuncent_mat(binds(i),:);
        monobino.bin_centshift_mat(i,:) = binoc.centshift_mat(binds(i),:);
        monobino.mon_tuncent_mat(i,:)   = monoc.tuncent_mat(minds(i),:);
        monobino.mon_centshift_mat(i,:) = monoc.centshift_mat(minds(i),:);
        
        % Create figure comparing responses in monocular and binocular
        % viewing conditions
%         bhfigureconcat([path,'/',monobino.cellID{i,1}]);
        close all
    end
    
    %% Combine unique cells from binoc and monoc viewing conditions 
    %  (preference for monoc in cells with both, assuming no statistical 
    %   difference in parameter fits between the two)
    
    % Find cells with binocular only data sets
    noMonocInds = arrayfun(@(x) isempty(x.monoc),all_params);
    binocCells = arrayfun(@(x) x.cellID,all_params,'UniformOutput',false)';
    
    incBinocCells = binocCells(noMonocInds);
    
    if ~isempty(incBinocCells)
        binocOnlyInds = nan(length(incBinocCells),1);
        
        for i = 1:length(incBinocCells)
            for j = 1:length(binoc.cellID)
                if strcmp(incBinocCells{i},binoc.cellID(j))
                    binocOnlyInds(i) = j;
                end
            end
        end
        
        clear i j
        
        num_binoconly   = length(binocOnlyInds);
        num_monoc       = numel(monoc.cellID);
        cell_tot        = num_monoc + num_binoconly;
        
        % Collect cells with only binocular datasets
        cellID          = cell(length(binocOnlyInds),1);
        lr_index        = nan(length(binocOnlyInds),1);
        lr_index_blink  = nan(length(binocOnlyInds),1);
        backforw        = nan(length(binocOnlyInds),1);
        headcents       = nan(length(binocOnlyInds),1);
        elevation       = nan(length(binocOnlyInds),1);
        gain_mat        = nan(length(binocOnlyInds),7);
        offset_mat      = nan(length(binocOnlyInds),7);
        band_mat        = nan(length(binocOnlyInds),7);
        tuncent_mat     = nan(length(binocOnlyInds),7);
        centshift_mat   = nan(length(binocOnlyInds),6);
        viewing_cond    = 2*ones(length(binocOnlyInds),1);
        numSacc         = nan(length(binocOnlyInds),7);
        pursGain        = nan(length(binocOnlyInds),7);
        HVelError       = nan(length(binocOnlyInds),1);
        VVelError       = nan(length(binocOnlyInds),1);
        
        for j = 1:length(binocOnlyInds)
            i = binocOnlyInds(j);
            
            cellID{j}           = binoc.cellID{i};
            lr_index(j)         = binoc.lr_index(i);
            lr_index_blink(j)   = binoc.lr_index_blink(i);
            backforw(j)         = binoc.backforw(i);
            headcents(j)        = binoc.headcents(i);
            elevation(j)        = binoc.elevation(i);
            gain_mat(j,:)       = binoc.gain_mat(i,:);
            offset_mat(j,:)     = binoc.offset_mat(i,:);
            band_mat(j,:)       = binoc.band_mat(i,:);
            tuncent_mat(j,:)    = binoc.tuncent_mat(i,:);
            centshift_mat(j,:)  = binoc.centshift_mat(i,:);
            
            numSacc(j,:)        = binoc.numSacc(i,:);
            pursGain(j,:)       = binoc.pursGain(i,:);
            HVelError(j,1)      = binoc.HVelError(i);
            VVelError(j,1)      = binoc.VVelError(i);
        end
        
        % Concatenate binoc only and monoc cell data
        comb                = monoc;
        comb.cellID         = [comb.cellID;cellID];
        comb.lr_index       = [comb.lr_index;lr_index];
        comb.lr_index_blink = [comb.lr_index_blink;lr_index_blink];
        comb.backforw       = [comb.backforw;backforw];
        comb.headcents      = [comb.headcents;headcents];
        comb.elevation      = [comb.elevation;elevation];
        comb.gain_mat       = [comb.gain_mat;gain_mat];
        comb.offset_mat     = [comb.offset_mat;offset_mat];
        comb.band_mat       = [comb.band_mat;band_mat];
        comb.tuncent_mat    = [comb.tuncent_mat;tuncent_mat];
        comb.centshift_mat  = [comb.centshift_mat;centshift_mat];
        comb.viewing_cond   = [ones(numel(monoc.cellID),1);viewing_cond];
        
        comb.numSacc        = [comb.numSacc;numSacc];
        comb.pursGain       = [comb.pursGain;pursGain];
        comb.HVelError      = [comb.HVelError;HVelError];
        comb.VVelError      = [comb.VVelError;VVelError];
        
        % Combine means
        comb.mean_gain = binoc.mean_gain.*(num_binoconly/cell_tot) + ...
                         monoc.mean_gain.*(num_monoc/cell_tot);
        comb.mean_offset = binoc.mean_offset.*(num_binoconly/cell_tot) + ...
                           monoc.mean_offset.*(num_monoc/cell_tot);
        comb.mean_band = binoc.mean_band.*(num_binoconly/cell_tot) + ...
                         monoc.mean_band.*(num_monoc/cell_tot);
        comb.mean_tuncent = binoc.mean_tuncent.*(num_binoconly/cell_tot) + ...
                            monoc.mean_tuncent.*(num_monoc/cell_tot);
    end
end

%% Plot population heading/pursuit preference distributions 
if plot_on
    % Pursuit preferences plot (cludgy because polar is shit)
    for i = 1:numel(all_params)
        purs_prefs(i) = all_params(i).pref_purs;
    end
    
    edges = [0 45 90 135 180 225 270 315 360];
    f = histcounts(purs_prefs,edges);
    purs_angs = [0 45 90 135 180 225 270 315].*(pi/180);
    
    purs = figure;
    polar([0 0],[0 max(f)],'k');
    newpolartix(8,purs);
    title('Pursuit Preferences');
    set(findall(gcf,'type','text'),'visible','on');
    t = findall(gca,'type','text');
    set(t,'FontSize',15);
    set(gca,'FontSize',15);
    hold on;
    
    for i = 1:8
        h(i) = polar([purs_angs(i) purs_angs(i)],[0 f(i)],'k');
    end
    set(h,'LineWidth',3);
    
    % Heading preferences plot
    heads = zeros(5,8);
    for i = 1:numel(all_params)
        heads(3 + -1*all_params(i).pref_head(2)./45,1 + all_params(i).pref_head(1)./45) = ...
            heads(3 + -1*all_params(i).pref_head(2)./45,1 + all_params(i).pref_head(1)./45) + 1;
    end
    
    reorg = [5 6 7 8 1 2 3 4 5];
    for i = 1:9
        y(:,i) = heads(:,reorg(i));
    end
    
    y(1,:) = ones(1,9).*max(y(1,:));
    y(5,:) = ones(1,9).*max(y(5,:));
    
    azvec = [-180 -135 -90 -45 0 45 90 135 180];
    elvec = [90 45 0 -45 -90];
    
    headfig = figure;
    hold on;
    set(gcf,'Position',[100 100 1300 600]);
    imagesc(azvec,elvec,y);
    title('Heading Preference Distribution');
    set(gca,'XLim',[-200 200],'YLim',[-110 110],'XTick',-180:45:180,...
        'YTick',-90:45:90,'FontSize',20);
    cmap = [linspace(0,1,max(max(y)) + 1)' ...
        linspace(0,1,max(max(y)) + 1)' linspace(0,1,max(max(y)) + 1)'];
    colormap(headfig,cmap);
    
    cbar = colorbar('Ticks',0:1:max(max(y)));
    cbar.Label.String = 'Number of Cells';
    
    hgsave(purs,[path,'/population_data/purs_tuning_dist']);
    hgsave(headfig,[path,'/population_data/head_tuning_dist']);
end

%% Save data tables
save([path,'/population_data/all_params'],'all_params');

if monoculo
    save([path,'/population_data/monoc'],'monoc');
end

if binoculo
    save([path,'/population_data/binoc'],'binoc');
end

if anymon && anybin
    save([path,'/population_data/monobino'],'monobino');
    
    if ~isempty(incBinocCells)
        save([path,'/population_data/comb'],'comb');
    end
end

end
