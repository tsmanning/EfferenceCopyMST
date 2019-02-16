function [normvfix,simvfix,stabvfix,simvnorm,shiftcomp,stats] = tcstatplot(data,cellinds,titlestr,ploton,sepplots,exampCells)
% Analyze heading preference changes between fixation and pursuit
% conditions in bighead
%
% Usage: [normvfix,simvfix,stabvfix,stats] = tcstatplot(data,cellinds,titlestr,ploton,sepplots)
%        [normvfix,simvfix,stabvfix,stats] = tcstatplot([structure or matrix],[1 3 32 88 ...],'Combined Monkeys',1,0)

% Select cells of interest
if ~isempty(cellinds) && or(isa(data,'struct'),isa(data,'popData'))
    % Select only indicated cell indices for structure subfields
    datfields = fieldnames(data);
    for i = 1:numel(datfields)
        data.(datfields{i}) = data.(datfields{i})(cellinds,:);
    end
    tcmat = data.tuncent_mat;
    backforw = data.backforw;
elseif isempty(cellinds) && or(isa(data,'struct'),isa(data,'popData'))
    tcmat = data.tuncent_mat;
    backforw = data.backforw;
elseif isa(data,'double')   % allow tuncent mat to be passed directly
    backforw = data(:,1);   % backforw tags appended to front of mat
    tcmat = data(:,2:end);
end

l_color = [0 0 0;...
           0 0 0.65;...
           0.65 0 0
           0 0 0.65];
r_color = [0.5 0.5 0.5;...
           0 0 1;...
           1 0 0
           0 0 1];
condColors = {[0 0 0],[0 0 0.55],[0.55 0 0]};
condColorsR = {[0.65 0.65 0.65],[0 0 1],[1 0 0]};
purs_cond = {'Normal','Simulated','Stabilized'};

numcells = size(tcmat,1);

pvals = nan(3,1);
med = nan(3,1);
vals = nan(2*numcells,3);
purdir = [-ones(numcells,1);ones(numcells,1)];
figs = zeros(3,1);
figs2 = zeros(3,1);

% Conditions: 1 - Normal, 2 - Simulated, 3 - Stabilized
for con = 1:3
    condition = con;
    datmat = tcmat;
    
    paramind_l = condition + 1;
    paramind_r = condition + 4;
    
    %%%% Compare Pursuit Conditions vs fixation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Flip sign of tuning curve shifts for leftwards pursuit
    % (so simulated pursuit shifts CCW)
    paramDiffL = -1*(datmat(:,paramind_l)-datmat(:,1));
    paramDiffR = datmat(:,paramind_r)-datmat(:,1);
    
    % Number of cells used
    numcellsl = find(~isnan(paramDiffL));
    numcellsr = find(~isnan(paramDiffR));
    numCellsTot = numel(unique([numcellsl;numcellsr]));
    numScatterPoints = numel([numcellsl;numcellsr]);
    
    % Flip sign of tuning curve shifts for backwards headings (so right purs
    % always shifts tuning curve/CoM to right)
    paramDiffR = paramDiffR.*backforw;
    paramDiffL = paramDiffL.*backforw;
    
    % Sign-rank test for tuning differences between fixation and pursuit
    rawp = signrank([paramDiffR;paramDiffL]);
    p = round(rawp,3,'significant');
    param_med = median([paramDiffR;paramDiffL],'omitnan');
    
    values = [paramDiffR;paramDiffL];
    indepMat = datmat(:,1);
    depMatR = datmat(:,paramind_r);
    depMatL = datmat(:,paramind_l);
    
    if ploton        
        % Params for plots
        xmin = 1.05*min(indepMat,[],'omitnan');
        xmax = 1.05*max(indepMat,[],'omitnan');
        ymin = 1.05*min([depMatR;depMatL],[],'omitnan');
        ymax = 1.05*max([depMatR;depMatL],[],'omitnan');
        
        if xmin>0
            xmin = 0;
        end
        if ymin>0
            ymin = 0;
        end
        
        unitmin = min([ymin xmin]);
        unitmax = min([ymax xmax]);
        
        %% Plot Pursuit-Fixation scatterplot
        figs(con) = figure;
        
        if ~sepplots
            set(gcf,'Position',[50 50 1800 700]);
            subplot(1,2,1);
        else
            set(gcf,'Position',[50 50 750 700]);
        end
        
        hold on;
        % Slight fill for backwards headings
        fill([unitmin unitmin unitmax unitmax],...
            [90 270 270 90],...
            [0.95 0.95 0.95],...
            'EdgeColor',[0.95 0.95 0.95],'Clipping','off');
        fill([90 270 270 90],...
            [unitmin unitmin unitmax unitmax],...
            [0.95 0.95 0.95],...
            'EdgeColor',[0.95 0.95 0.95],'Clipping','off');
        fill([270 270 90 90],...
            [90 270 270 90],...
            [0.9 0.9 0.9],...
            'EdgeColor',[0.95 0.95 0.95],'Clipping','off');
        
        if isempty(exampCells)
            scatter(indepMat,depMatR,100,'filled',...
                'MarkerFaceColor',condColorsR{con},...
                'MarkerEdgeColor',condColorsR{con},...
                'MarkerFaceAlpha',0.7,...
                'MarkerEdgeAlpha',1);
            %             'MarkerFaceColor',r_color(condition,:));
            scatter(indepMat,depMatL,100,'filled',...
                'MarkerFaceColor',condColors{con},...
                'MarkerEdgeColor',condColors{con});
            %             'MarkerFaceColor',l_color(condition,:));
        else
            temp = ones(numcells,1,'logical');
            temp(exampCells) = false;
            
            scatter(indepMat(temp),depMatR(temp),100,'filled',...
                'MarkerFaceColor',condColorsR{con},...
                'MarkerEdgeColor',condColorsR{con},...
                'MarkerFaceAlpha',0.7,...
                'MarkerEdgeAlpha',1);
            scatter(indepMat(temp),depMatL(temp),100,'filled',...
                'MarkerFaceColor',condColors{con},...
                'MarkerEdgeColor',condColors{con});
            % Mark example cells with different symbol
            s1 = scatter(indepMat(exampCells),depMatR(exampCells),120,'filled',...
                'MarkerFaceColor',condColorsR{con},...
                'MarkerEdgeColor',[1 1 1],...
                'MarkerFaceAlpha',0.7,...
                'MarkerEdgeAlpha',1);
            s2 = scatter(indepMat(exampCells),depMatL(exampCells),120,'filled',...
                'MarkerFaceColor',condColors{con},...
                'MarkerEdgeColor',[1 1 1]);
            s1.Marker = "*";
            s2.Marker = "*";
        end
        
        plot([unitmin unitmax],[unitmin unitmax],'--k','LineWidth',3);  % fix to max shift
        set(gca,'XLim',[unitmin,unitmax],'YLim',[unitmin,unitmax],...
            'XTick',[0:90:360],'YTick',[0:90:360],...
            'FontSize',20,'Layer','top',...
            'FontName','Arial');
        ax = gca;
        ax.XAxis.MinorTick = 'on';
        ax.XAxis.MinorTickValues = 0:30:420;
        ax.YAxis.MinorTick = 'on';
        ax.YAxis.MinorTickValues = 0:30:420;
        
        xlabel('Preferred Heading (Fixation, \circ)','FontSize',20);
        ylabel(['Preferred Heading (',purs_cond{condition},' Pursuit, \circ)'],'FontSize',20);
        title(titlestr);
        text(290,50,['n=',num2str(numCellsTot)],'FontSize',30,'FontName','Arial');
        
        %% Plot Pursuit-Fixation shift histogram
        if ~sepplots
            subplot(1,2,2);
        else
            figs2(con) = figure;
            set(gcf,'Position',[50 50 750 700]);
        end
        
        hold on;
        h = histogram([paramDiffR;paramDiffL],...
            'BinWidth',5,...
            'FaceColor',condColorsR{con});
        h2 = histogram(paramDiffL,...
            'BinWidth',5,...
            'FaceColor',condColors{con});
        h.FaceAlpha = 0.7;
        h2.FaceAlpha = 1;
        xmaxlim = 90;
        ymaxlim = 2*floor(max(h.Values)/2)+4;
        ylabel('Number of Shifts','FontSize',20);
        xlabel('\Delta Preferred Heading (\circ Az)','FontSize',20);
        title([purs_cond{condition},' Pursuit vs. Fixation']);
        
        max_data = max([h.Values]) + 3;
        set(gca,'YTick',0:2:ymaxlim,'YMinorTick','On','YLim',[0 max_data],'FontSize',20);
        set(gca,'XLim',[-xmaxlim,xmaxlim],...
            'XTick',-xmaxlim:20:xmaxlim,'FontSize',20,'FontName','Arial');
        a = gca;
        a.YAxis.MinorTickValues = 0:1:max_data;
        a.Clipping = 'on';
        
        plot([0 0],[0 max_data],'--k','LineWidth',3);
        plot([param_med param_med],[max_data-2.5 max_data-1],'k','LineWidth',3);
        scatter(param_med,max_data-2.5,100,'k','filled','v');
        
        text(-70,ymaxlim*0.8,'Left Pursuit','FontSize',18,...
            'Color',l_color(condition,:),'FontName','Arial');
        text(-70,ymaxlim*0.75,'Right Pursuit','FontSize',18,...
            'Color',r_color(condition,:),'FontName','Arial');
        text(20,ymaxlim*0.8,['Median=',num2str(param_med)],...
            'FontSize',18,'Color',[0 0 0],'FontName','Arial');
        text(20,ymaxlim*0.75,['p=',num2str(p)],...
            'FontSize',18,'Color',[0 0 0],'FontName','Arial');
        
        set(a,'Layer','top');
    end
    
    pvals(con) = rawp;
    med(con) = param_med;
    vals(:,con) = values;
end

%% Simulated vs Normal Comparison

valNorm = vals(:,1);
valSim = vals(:,2);
% valDiff = valSim - valNorm;
valDiff = valNorm - valSim;

% Sign-rank test for tuning differences between normal and
% simulated pursuit
pvals(4) = signrank(valNorm,valSim);
p = round(pvals(4),3,'significant');
med(4) = median(valDiff,'omitnan');

if ploton
    paramDiffR = valDiff(1:numcells,1);
    paramDiffL = valDiff(numcells+1:end,1);
    
    % Number of cells used
    numcellsl = find(~isnan(paramDiffL));
    numcellsr = find(~isnan(paramDiffR));
    numCellsTot = numel(unique([numcellsl;numcellsr]));
    numScatterPoints = numel([numcellsl;numcellsr]);
    
    indepMatR = valNorm(1:numcells,1);
    indepMatL = valNorm(numcells+1:end,1);
    
    depMatR = valSim(1:numcells,1);
    depMatL = valSim(numcells+1:end,1);
    
    %% Plot Sim vs Norm scatterplot
    figs(4) = figure;
    
    if ~sepplots
        set(gcf,'Position',[50 50 1800 700]);
        subplot(1,2,1);
    else
        set(gcf,'Position',[50 50 750 700]);
    end
    
    hold on;
    scatter(indepMatL,depMatL,100,'filled','Marker','s',...
        'MarkerEdgeColor',[0 0 0],...
        'MarkerFaceColor',[0 0 0],...
        'LineWidth',3.5);
    scatter(indepMatR,depMatR,100,...
        'MarkerEdgeColor',[0 0 0],...
        'LineWidth',2.5);
    
    xmaxlim = 90;
    plot([-xmaxlim xmaxlim],[-xmaxlim xmaxlim],'--k','LineWidth',3);
    a = gca;
    a.YTick = -xmaxlim:20:xmaxlim;
    a.XTick = -xmaxlim:20:xmaxlim;
    a.XLim = [-xmaxlim,xmaxlim];
    a.YLim = [-xmaxlim,xmaxlim];
    
    set(gca,'FontSize',20);
    
    xlabel('\Delta Preferred Heading (Normal - Fixation, \circ Az)','FontSize',20);
    ylabel('\Delta Preferred Heading (Simulated - Fixation, \circ Az)','FontSize',20);
    
    title(titlestr);
    text(30,-70,['n=',num2str(numCellsTot)],'FontSize',30);
    text(-70,70,'Left Pursuit (  )','FontSize',18,...
        'Color',[0 0 0]);
    text(-70,60,'Right Pursuit (  )','FontSize',18,...
        'Color',[0 0 0]);
    
    %% Plot Pursuit-Fixation shift histogram
    if ~sepplots
        subplot(1,2,2);
    else
        figs2(con) = figure;
        set(gcf,'Position',[50 50 750 700]);
    end
    
    hold on;
    h = histogram([paramDiffR;paramDiffL],'BinWidth',5,...
        'FaceColor',[1 1 1],...
        'EdgeColor',[0 0 0],...
        'LineWidth',2);
    h2 = histogram(paramDiffL,'BinWidth',5,...
        'FaceColor',[0 0 0],...
        'EdgeColor',[0 0 0],...
        'LineWidth',2);
    
    h.FaceAlpha = 1;
    h2.FaceAlpha = 1;
    xmaxlim = 90;
    ymaxlim = 2*floor(max(h.Values)/2)+4;
    ylabel('Number of Shifts','FontSize',20);
    xlabel('Heading Shift Difference (\circ Az)','FontSize',20);
    title('Normal - Simulated Pursuit');
    
    max_data = max([h.Values]) + 3;
    set(gca,'YTick',0:2:ymaxlim,'YMinorTick','On','YLim',[0 max_data],'FontSize',20);
    set(gca,'XLim',[-xmaxlim,xmaxlim],...
        'XTick',-xmaxlim:20:xmaxlim,'FontSize',20);
    a = gca;
    a.YAxis.MinorTickValues = 0:1:max_data;
    a.Clipping = 'on';
    
    plot([0 0],[0 max_data],'--k','LineWidth',3);
    plot([med(4) med(4)],[max_data-2.5 max_data-1],'k','LineWidth',3);
    scatter(med(4),max_data-2.5,100,'k','filled','v');
    
    text(20,ymaxlim*0.8,['Median=',num2str(med(4))],...
        'FontSize',18,'Color',[0 0 0]);
    text(20,ymaxlim*0.75,['p=',num2str(p)],...
        'FontSize',18,'Color',[0 0 0]);
    
    set(a,'Layer','top');
end

%% Simulated-Normal vs Stabilized-Fixation

valStab = vals(:,3);
nonNanPairs = and(~isnan(valStab),~isnan(valDiff));

% Calculate Spearman's ranked correlation & significance
[stats.shiftCorr,pvals(5)] = corr(valDiff(nonNanPairs),valStab(nonNanPairs),'Type','Spearman');

% Calculate best fit slope (simple least squares or Theil-Sen)

% m = valDiff(nonNanPairs)\valStab(nonNanPairs);
% [m,b] = TheilSen([valDiff(nonNanPairs) valStab(nonNanPairs)]);
% covfefe = pca([valDiff(nonNanPairs) valStab(nonNanPairs)]);
% m = covfefe(2,1)/covfefe(1,1);
% b = mean(valDiff(nonNanPairs));
[m,b] = lsqbisec(valDiff(nonNanPairs),valStab(nonNanPairs));
% [m,b] = lsqfitma(valDiff(nonNanPairs),valStab(nonNanPairs));
% [m,b] = lsqfitgm(valDiff(nonNanPairs),valStab(nonNanPairs));

if ploton
    shiftcomp = figure;
    shiftcomp.Position = [100 100 750 700];
    
    hold on;
    scatter(valDiff,valStab,100,'filled','k');
%     plotLims = max(abs([valStab;valDiff]));
    plotLims = xmaxlim;
    cax = gca;
    cax.XLim = [-plotLims plotLims];
    cax.YLim = [-plotLims plotLims];
    set(gca,'FontSize',20);
    a = gca;
    a.YTick = -xmaxlim:20:xmaxlim;
    a.XTick = -xmaxlim:20:xmaxlim;
    a.XLim = [-xmaxlim,xmaxlim];
    a.YLim = [-xmaxlim,xmaxlim];
    
    plot([-plotLims plotLims],[-plotLims plotLims],'--k');
    plot([-plotLims plotLims],[-plotLims*m plotLims*m],'--r');
%     plot([-plotLims plotLims],[-plotLims*m plotLims*m]+b,'--r');
    xlabel('\Delta Preferred Heading (Normal - Simulated, \circ Az)','FontSize',20);
    ylabel('\Delta Preferred Heading (Stabilized - Fixation, \circ Az)','FontSize',20);
    text(0.9*-plotLims,0.9*plotLims,...
        ['r = ',num2str(round(stats.shiftCorr,3,'significant'))],...
        'FontSize',20);
    text(0.9*-plotLims,0.8*plotLims,...
        ['p = ',num2str(round(pvals(5),3,'significant'))],...
        'FontSize',20);
    text(0.9*-plotLims,0.7*plotLims,...
        ['m = ',num2str(round(m,3,'significant'))],...
        'FontSize',20,'Color','r');
end

%% Collect results
if ploton && ~sepplots
    normvfix = figs(1);
    simvfix = figs(2);
    stabvfix = figs(3);
    simvnorm = figs(4);
else
    normvfix = [];
    simvfix = [];
    stabvfix = [];
    simvnorm = [];
    shiftcomp = [];
end

stats.purdir = purdir;
stats.vals = vals;
stats.p = pvals;
stats.medians = med;
end