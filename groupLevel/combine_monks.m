function [comb_params,comb_monks] = combine_monks(monk_dirs,monk_viewparams,sepplots,pars,saveSuppress)
% Combines datasets from multiple animals into overall plot. Input data
% should be popData objects.
%
% Usage: [monk_data,comb_monks] = combine_monks(popData_monk1,popData_monk2,...)

monk_data = struct;
comb_params = struct;

% Load in summary mats from individual animals
for i = 1:numel(monk_dirs)
    % Load in monoc/binoc/comb fit parameters
    tempa = load([monk_dirs{i},monk_viewparams{i},'.mat']);
    tempb = fieldnames(tempa);
    temp = tempa.(tempb{1});
    
    % Reassign monk/binoc/comb fields to monk_data fields
    monk_data(i).cellID = temp.cellID;
    monk_data(i).monkID = ones(numel(temp.cellID),1)*i;
    monk_data(i).lr_index = temp.lr_index;
    monk_data(i).lr_index_blink = temp.lr_index_blink;
    monk_data(i).backforw = temp.backforw;
    monk_data(i).headcents = temp.headcents;
    monk_data(i).elevation = temp.elevation;
    monk_data(i).gain_mat = temp.gain_mat;
    monk_data(i).offset_mat = temp.offset_mat;
    monk_data(i).band_mat = temp.band_mat;
    monk_data(i).tuncent_mat = temp.tuncent_mat;
    monk_data(i).centshift_mat = temp.centshift_mat;
    monk_data(i).viewing_cond = temp.viewing_cond;
    
    monk_data(i).numSacc = temp.numSacc;
    monk_data(i).pursGain = temp.pursGain;
    
    monk_data(i).HVelError = temp.HVelError;
    monk_data(i).VVelError = temp.VVelError;
    
    % Load in spike counts
    load([monk_dirs{i},'all_params.mat']);
    if i == 1
        comb_params = all_params;
    else
        comb_params = [comb_params all_params];
    end
    
    % Load in stabilization replay/simulated pursuit fit params & data
    load([monk_dirs{i},'repSimMat.mat']);
    if i == 1
        combRepMat = repSimMat;
    else
        combRepMat = [combRepMat repSimMat];
    end
    
    % Load in excluded cells
    load([monk_dirs{i},'excluded_cells.mat']);
    if i == 1
        exCells = excluded_cells;
    else
        exCells = [exCells;excluded_cells];
    end
end

num_monks = numel(monk_data);
cells_per_monk = arrayfun(@(x) numel(x.cellID),monk_data);
cell_tot = sum(cells_per_monk);

%% Concatenate fields across monkeys
comb_monks = struct;
fnames = fieldnames(monk_data);

for i = 1:numel(fnames)
    temp = arrayfun(@(x) x.(fnames{i}),monk_data,'UniformOutput',false);
    comb_monks.(fnames{i}) = vertcat(temp{:});
end

%% Replot stats with combined animal data

% Find cells with preferred headings within 45 of directly forward/backward
tempA            = comb_monks.tuncent_mat(:,1);
tempA(tempA>360) = tempA(tempA>360) - 360;
tempA(tempA<0)   = tempA(tempA<0) + 360;

boundSize = 50;

forInds     = or(tempA>=(360-boundSize),tempA<=(0+boundSize));
backInds    = and(tempA>=(180-boundSize),tempA<=(180+boundSize));
forbackInds = or(forInds,backInds);

% Find cells with strong pursuit tuning indices
% tempB   = comb_monks.lr_index;
tempB   = comb_monks.lr_index_blink;
tempB   = abs(tempB);
ptiInds = tempB>0.5;

% Find cells with small pursuit error
tempC = comb_monks.HVelError;
tempC = abs(tempC);
perrorInds = tempC<0.4;

selectInds = [];
% selectInds = ones(numel(comb_monks.cellID),1,'logical');
% selectInds(42:52,1) = false;
% selectInds = comb_monks.viewing_cond == 1;
% selectInds = forbackInds;
% selectInds = ptiInds;
% selectInds = perrorInds;

% pass single cell examples from paper
exampCells = [36 47 94];

if pars(1)
    [normvfix,simvfix,stabvfix,simvnorm,shiftcomp,TCstats] = ...
        tcstatplot(comb_monks,selectInds,'Combined Monkey Data',1,sepplots,exampCells);
end
if pars(2)
    [norm_fix_offset,sim_fix_offset,stab_fix_offset,OffStats] = ...
        offsetstatplot(comb_monks,selectInds,'Combined Monkey Data',1,sepplots);
end
if pars(3)
    [norm_fix_gain,sim_fix_gain,stab_fix_gain,AmpStats] = ...
        gainstatplot(comb_monks,selectInds,'Combined Monkey Data',1,sepplots);
end
if pars(4)
    [norm_fix_band,sim_fix_band,stab_fix_band,BandStats] = ...
        bandstatplot(comb_monks,selectInds,'Combined Monkey Data',1,sepplots);
end

if pars(2) && pars(3) && pars(4)
    [amplrstats,offlrstats,bandlrstats] = lrstats(AmpStats,OffStats,BandStats);
end

%% Pursuit Replay across animals

% [repSimMat,repStats,replayFig,TCfig] = replay_stats(1,combRepMat);


%% Plot heading/pursuit preferences for combined datset

% Pursuit preferences plot
for i = 1:numel(comb_params)
    purs_prefs(i) = comb_params(i).pref_purs;
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

figure;
polarhistogram(purs_prefs*(pi/180),[-22.5 22.5 67.5 112.5 157.5 202.5 247.5 292.5 337.4]*(pi/180));

% Heading preferences plot
heads = zeros(5,8);
for i = 1:numel(comb_params)
    heads(3 + -1*comb_params(i).pref_head(2)./45,1 + comb_params(i).pref_head(1)./45) = ...
        heads(3 + -1*comb_params(i).pref_head(2)./45,1 + comb_params(i).pref_head(1)./45) + 1;
end

reorg = [5 6 7 8 1 2 3 4 5];
for i = 1:9
    y(:,i) = heads(:,reorg(i));
end

% y(1,:) = ones(1,9).*max(y(1,:));
% y(5,:) = ones(1,9).*max(y(5,:));

azvec = [-180 -135 -90 -45 0 45 90 135 180];
elvec = [90 45 0 -45 -90];

[az,el] = meshgrid(azvec,elvec);

headfig = figure;
hold on;
set(gcf,'Position',[100 100 1300 600],'Renderer','painters');
% imagesc(azvec,elvec,y);
scatterbar3(az,el,y,45);
title('Heading Preference Distribution');
set(gca,'XLim',[-200 200],'YLim',[-110 110],'XTick',-180:45:180,...
    'YTick',-90:45:90,'FontSize',20,'view',[0 90]);

% Define greyscale colormap
cmap = [[0 linspace(0.25,0.9,max(max(y)) + 1)]' ...
        [0 linspace(0.25,0.9,max(max(y)) + 1)]' ...
        [0 linspace(0.25,0.9,max(max(y)) + 1)]'];
colormap(headfig,cmap);

cbar = colorbar('Ticks',0:1:max(max(y)));
cbar.Label.String = 'Number of Cells';

%% Save combined structure and figures
if ~saveSuppress
    datpath = '/home/tyler/matlab/data/combined_monks/';
    if ~exist(datpath,'dir')
        mkdir(datpath);
    end
    
    save([datpath,'comb_monks'],'comb_monks');
    save([datpath,'comb_params'],'comb_params');
    save([datpath,'exCells'],'exCells');
    
    hgsave(purs,[datpath,'purs_tuning_dist']);
    hgsave(headfig,[datpath,'head_tuning_dist']);
    
    
    if pars(1)
        % Main effects (preferred heading)
        if ~exist([datpath,'tuning_center'],'dir')
            mkdir([datpath,'tuning_center']);
        end
        hgsave(normvfix,[datpath,'tuning_center/normvfix']);
        hgsave(simvfix,[datpath,'tuning_center/simvfix']);
        hgsave(stabvfix,[datpath,'tuning_center/stabvfix']);
        hgsave(simvnorm,[datpath,'tuning_center/simvnorm']);
        hgsave(shiftcomp,[datpath,'tuning_center/shiftcomp']);
        
        save([datpath,'tuning_center/TCstats'],'TCstats');
    end
    if pars(2)
        % Main effects (offset)
        if ~exist([datpath,'offset'],'dir')
            mkdir([datpath,'offset']);
        end
        hgsave(norm_fix_offset,[datpath,'offset/norm_fix_offset']);
        hgsave(sim_fix_offset,[datpath,'offset/sim_fix_offset']);
        hgsave(stab_fix_offset,[datpath,'offset/stab_fix_offset']);
        save([datpath,'offset/OffStats'],'OffStats');
    end
    if pars(3)
        % Main effects (amp)
        if ~exist([datpath,'amplitude'],'dir')
            mkdir([datpath,'amplitude']);
        end
        hgsave(norm_fix_gain,[datpath,'amplitude/norm_fix_amp']);
        hgsave(sim_fix_gain,[datpath,'amplitude/sim_fix_amp']);
        hgsave(stab_fix_gain,[datpath,'amplitude/stab_fix_amp']);
        save([datpath,'amplitude/AmpStats'],'AmpStats');
    end
    if pars(4)
        % Main effects (bandwidth)
        if ~exist([datpath,'bandwidth'],'dir')
            mkdir([datpath,'bandwidth']);
        end
        hgsave(norm_fix_band,[datpath,'bandwidth/norm_fix_band']);
        hgsave(sim_fix_band,[datpath,'bandwidth/sim_fix_band']);
        hgsave(stab_fix_band,[datpath,'bandwidth/stab_fix_band']);
        save([datpath,'bandwidth/BandStats'],'BandStats');
    end
    % Pursuit Replay vs. Simulated Pursuit
%     hgsave(replayFig,[datpath,'replayFig']);
%     hgsave(TCfig,[datpath,'TCfig']);
%     save([datpath,'repStats'],'repStats');
%     save([datpath,'repSimMat'],'repSimMat');
end
end
