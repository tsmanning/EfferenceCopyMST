function [normvfix,simvfix,stabvfix,stats] = offsetstatplot(data,cellinds,titlestr,ploton,sepplots)
% Analyze gain changes between fixation and pursuit conditions in bighead
%
% Usage: [normvfix,simvfix,stabvfix,stats] = offsetstatplot(data,cellinds,titlestr,ploton,sepplots)
%        [normvfix,simvfix,stabvfix,stats] = offsetstatplot(data,cellinds,titlestr,ploton,sepplots)

% Select cells of interest
if ~isempty(cellinds) && or(isa(data,'struct'),isa(data,'popData'))
    % Select only indicated cell indices for structure subfields
    datfields = fieldnames(data);
    for i = 1:numel(datfields)
        data.(datfields{i}) = data.(datfields{i})(cellinds,:);
    end
    offmat = data.offset_mat;
    c = -data.lr_index; % why negative?
elseif isempty(cellinds) && or(isa(data,'struct'),isa(data,'popData'))
    offmat = data.offset_mat;
    c = -data.lr_index;
elseif isa(data,'double')   % allow tuncent mat to be passed directly
    %     c = data(:,1);   % lr tags appended to front of mat (need to
    %                        implement this)
    offmat = data(:,2:end);
end

% Set up params
numcells = size(offmat,1);

p_cond = nan(3,1);
cond_med = nan(3,1);
vals = nan(numcells*2,3);
purdir = [-ones(numcells,1);ones(numcells,1)];

normmap = [linspace(0,0.75,10)' linspace(0,0.75,10)' linspace(0,0.75,10)'];
simmap = [zeros(10,1) zeros(10,1) linspace(0,1,10)'];
stabmap = [linspace(0,1,10)' zeros(10,1) zeros(10,1)];

colormaps = {normmap,simmap,stabmap};
condColors = {[0 0 0],[0 0 0.55],[0.55 0 0]};
condColorsR = {[0.65 0.65 0.65],[0 0 1],[1 0 0]};

l_inds = [2 3 4];   % norm, sim, stab
r_inds = [5 6 7];

names = {'Normal','Simulated','Stabilized'};

Rsym = char(9679);%char(9672);%char(9635);
Lsym = char(9679);

% Run Stats & Plot results
for i = 1:3
%     numcellsl = sum(~isnan(offmat(:,l_inds(i))));
%     numcellsr = sum(~isnan(offmat(:,r_inds(i))));
%     cellCount = num2str(min([numcellsl numcellsr]));
    numcellsl = find(~isnan(offmat(:,l_inds(i))));
    numcellsr = find(~isnan(offmat(:,r_inds(i))));
    cellCount = num2str(numel(unique([numcellsl;numcellsr])));
    
    % Run sign-rank tests (wilcoxin performs poorly here, use monte carlo)
%     p_cond(i) = signrank([offmat(:,1);offmat(:,1)],[offmat(:,l_inds(i));offmat(:,r_inds(i))]);
    [p_cond(i),cond_med(i)] = permuteTest([offmat(:,1);offmat(:,1)],[offmat(:,l_inds(i));offmat(:,r_inds(i))],10000,1,0);
    p_plot = round(p_cond(i),4);
    
%     cond_med(i) = median([offmat(:,l_inds(i))-offmat(:,1);offmat(:,r_inds(i))-offmat(:,1)],'omitnan');
    cond_plot = round(cond_med(i),4,'significant');
%     
%     keyboard;
    
    
    maxval = max(max(offmat));
    
    vals(:,i) = [offmat(:,l_inds(i));offmat(:,r_inds(i))] - [offmat(:,1);offmat(:,1)];
    
    % Scatterplot and Histogram
    if ploton
        f(i) = figure;
        set(gcf,'Position',[50 50 1800 700]);
        
        % Scatter
        subplot(1,2,1);
        hold on;
%         scatter(offmat(:,1),offmat(:,l_inds(i)),100,c,'filled','Marker','square');
%         scatter(offmat(:,1),offmat(:,r_inds(i)),100,c,'filled');
        scatter(offmat(:,1),offmat(:,l_inds(i)),100,'filled',...
            'MarkerFaceColor',condColorsR{i},...[1 1 1],...
            'MarkerEdgeColor',condColorsR{i},...
            'MarkerFaceAlpha',0.7,...
            'MarkerEdgeAlpha',0.7);
        scatter(offmat(:,1),offmat(:,r_inds(i)),100,'filled',...
            'MarkerFaceColor',condColors{i},...
            'MarkerEdgeColor',condColors{i});
        
        plot([0 maxval*1.01],[0 maxval*1.01],'--k');  % fix to max shift
        
        maxMinorTickSc = round(maxval,-1);
        
        scax = gca;
        scax.XLabel.String = 'Offset (Fixation)';
        scax.XLim = [0,maxval*1.01];
        scax.XTick = -maxMinorTickSc:20:maxMinorTickSc;
        scax.XAxis.MinorTick = 'on';
        scax.XAxis.MinorTickValues = -maxMinorTickSc:5:maxMinorTickSc;
        scax.YLabel.String = ['Offset (',names{i},' Pursuit)'];
        scax.YLim = [0,maxval*1.01];
        scax.YTick = -maxMinorTickSc:20:maxMinorTickSc;
        scax.YAxis.MinorTick = 'on';
        scax.YAxis.MinorTickValues = -maxMinorTickSc:5:maxMinorTickSc;
        
        set(scax,'FontSize',20);
        title(titlestr);
        
        % Condition labels
        text(0.1*maxMinorTickSc,0.9*maxval*1.01,[Lsym,' Left Pursuit'],...
            'Color',condColors{i},'FontSize',18);
        text(0.1*maxMinorTickSc,0.85*maxval*1.01,[Rsym,' Right Pursuit'],...
            'Color',condColorsR{i},'FontSize',18);
        
%         colormap(gcf,colormaps{i});
%         cbar1 = colorbar;
%         cbar1.Label.String = 'Left-Right PTI';
        
        text(maxMinorTickSc*0.65,maxMinorTickSc*0.15,['n=',cellCount],'FontSize',30);
        
        % Histogram
        subplot(1,2,2);
        hold on;
        % Right
        h = histogram([offmat(:,l_inds(i))-offmat(:,1);offmat(:,r_inds(i))-offmat(:,1)],...
            'BinWidth',5,...
            'FaceColor',condColorsR{i});
        h.FaceAlpha = 0.7;
        % Left
        h2 = histogram(offmat(:,l_inds(i))-offmat(:,1),...
            'BinWidth',5,...
            'FaceColor',condColors{i});
        h2.FaceAlpha = 1;
        uistack(h2,'top');
        
        maxshift = max(abs([h.Data;h2.Data]),[],'omitnan');
        ymaxlim = 2*floor(max(h.Values)/2)+4;
        ylabel('Number of Occurrences','FontSize',20);
        xlabel('Offset Difference (sp/s)','FontSize',20);
        title([names{i},' Pursuit vs. Fixation']);
        max_data = max([h.Values]) + 3;
        
        maxMinorTick = round(maxshift*1.15,-1);
        
        hax = gca;
        hax.YTick = 0:4:ymaxlim;
        hax.YLim = [0 max_data];
        hax.XLim = [-maxshift*1.15,maxshift*1.15];
        hax.XAxis.MinorTick = 'on';
        hax.XAxis.MinorTickValues = -maxMinorTick:5:maxMinorTick;
        hax.YAxis.MinorTick = 'on';
        hax.YAxis.MinorTickValues = 0:1:ymaxlim;
        
        set(hax,'FontSize',20);
        
        plot([0 0],[0 max_data],'--k','LineWidth',3);
        plot([cond_plot cond_plot],[max_data-2.5 max_data-1],'k','LineWidth',3);
        scatter(cond_plot,max_data-2.25,100,'k','filled','v');
  
        % Condition labels and stats
        text(-0.85*maxMinorTick,ymaxlim*0.9,'Left Pursuit',...
            'Color',condColors{i},'FontSize',18);
        text(-0.85*maxMinorTick,ymaxlim*0.85,'Right Pursuit',...
            'Color',condColorsR{i},'FontSize',18);
        
        text(0.25*max_data,ymaxlim*0.9,['Median = ',num2str(cond_plot)],...
            'Color',[0 0 0],'FontSize',18);
        text(0.25*max_data,ymaxlim*0.85,['p = ',num2str(p_plot)],...
            'Color',[0 0 0],'FontSize',18);
    end
end

if ploton && ~sepplots
    normvfix = f(1);
    simvfix = f(2);
    stabvfix = f(3);
else
    normvfix = [];
    simvfix = [];
    stabvfix = [];
end

stats.purdir = purdir;
stats.p = p_cond;
stats.medians = cond_med;
stats.vals = vals;
end