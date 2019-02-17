function [combfig,pvals,stats,t] = monkParamConcat(condInd,paramInd,saveSuppress)
% Generate figures showing tuning curve parameter fits individually for
% each monkey. Also runs a 3-way ANOVA to test if monkeys vary
% significantly. 
% 
% Usage: [] = monkParamConcat(condInd,paramInd)
%        [] = monkParamConcat(1,1)
%        cond = {'norm','sim','stab'};
%        param = {'center','gain','offset','band'};

% Define directories of interest
monkDirs = {'/home/tyler/matlab/data/qbh/population_data/',...
            '/home/tyler/matlab/data/pbh/population_data/',...
            '/home/tyler/matlab/data/rbh/population_data/'};

parNames = {'tuning_center','amplitude','offset','band'};

combDir = '/home/tyler/matlab/data/combined_monks/';

monks = {'qbh','pbh','rbh'};

% Run one-way ANOVA to test for significant effect differences between
% animals
load([combDir,'comb_monks.mat'])

monkVec = 1*strncmpi('qbh*',comb_monks.cellID,3)+...
          3*strncmpi('rbh*',comb_monks.cellID,3)+...
          2*strncmpi('pbh*',comb_monks.cellID,3);
monkVecLR = [monkVec;monkVec];

monkIDs = [comb_monks.cellID;comb_monks.cellID];

LRVec = [ones(numel(monkVec),1);2*ones(numel(monkVec),1)];
      
datmat = comb_monks.tuncent_mat;
fixpref = datmat(:,1);

back = and(fixpref>90,fixpref<270);
forw = ~back;
backforw = -1*back + forw;
backforwLR = [backforw;backforw];

datmat = datmat(:,2:end) - datmat(:,1);

normdat = [-1*datmat(:,1);datmat(:,4)].*backforwLR;
simdat = [-1*datmat(:,2);datmat(:,5)].*backforwLR;
stabdat = [-1*datmat(:,3);datmat(:,6)].*backforwLR;

% Find biggest outlier in simulated pursuit dataset across monkeys and NaN
% it out - check FX on stats
% [~,maxind] = max(abs(simdat));
% simdat(maxind) = nan;
% fprintf(['kicking following outlier: ',monkIDs{maxind},'\n']);

% pNorm = anova1(normdat,monkVecLR,'off');
% pSim = anova1(simdat,monkVecLR,'off');
% pStab = anova1(stabdat,monkVecLR,'off');

[pNorm,tbl1,statsNorm] = anovan(normdat,{monkVecLR LRVec backforwLR},...
    'model','interaction','varnames',{'Monkey','Pursuit Dir. (L-R)','Heading Dir. (Forw-Back)'});
[pSim,tbl2,statsSim] = anovan(simdat,{monkVecLR LRVec backforwLR},...
    'model','interaction','varnames',{'Monkey','Pursuit Dir. (L-R)','Heading Dir. (Forw-Back)'});
[pStab,tbl3,statsStab] = anovan(stabdat,{monkVecLR LRVec backforwLR},...
    'model','interaction','varnames',{'Monkey','Pursuit Dir. (L-R)','Heading Dir. (Forw-Back)'});

a = figure(1);
a.Position = [150 700 750 250];
b = figure(2);
b.Position = [150 425 750 250];
c = figure(3);
c.Position = [150 150 750 250];

pvals = round([pNorm pSim pStab],3,'significant');
stats = [statsNorm statsSim statsStab];
t = struct;
t.NoP = tbl1;
t.SiP = tbl2;
t.StP = tbl3;

% Concatenate scatterplots/histograms already plotted
cond = {'norm','sim','stab'};
param = {'center','gain','offset','band'};

qbh.fig = hgload([monkDirs{1},...
    'pop_tuning_',param{paramInd},'/',cond{condInd},'vfix_comb.fig']);
qbhsubfig.ax(1) = subplot(1,2,1);
qbhsubfig.ax(2) = subplot(1,2,2);

pbh.fig = hgload([monkDirs{2},...
    'pop_tuning_',param{paramInd},'/',cond{condInd},'vfix_monoc.fig']);
pbhsubfig.ax(1) = subplot(1,2,1);
pbhsubfig.ax(2) = subplot(1,2,2);

rbh.fig = hgload([monkDirs{3},...
    'pop_tuning_',param{paramInd},'/',cond{condInd},'vfix_comb.fig']);
rbhsubfig.ax(1) = subplot(1,2,1);
rbhsubfig.ax(2) = subplot(1,2,2);

combfig.fig = figure;
set(gcf,'Position',[50 50 950 1000]);
combfig.ax = gobjects(3,2);
subpltInds = [1 3 5 2 4 6];

for i = 1:6
    % Assign subplots to each element of array
    combfig.ax(i) = subplot(3,2,subpltInds(i)); 
end

combfig.ax2 = gobjects(size(combfig.ax));
combfig.ax2(1,1) = copyobj(qbhsubfig.ax(1),combfig.fig);
combfig.ax2(1,2) = copyobj(qbhsubfig.ax(2),combfig.fig);
combfig.ax2(2,1) = copyobj(pbhsubfig.ax(1),combfig.fig);
combfig.ax2(2,2) = copyobj(pbhsubfig.ax(2),combfig.fig);
combfig.ax2(3,1) = copyobj(rbhsubfig.ax(1),combfig.fig);
combfig.ax2(3,2) = copyobj(rbhsubfig.ax(2),combfig.fig);

close(figure(4:6));

for i = 1:6
    combfig.ax2(i).Position = combfig.ax(i).Position;
end

delete(combfig.ax);

% Retitle subplots

for i = 1:6
    x = subplot(3,2,subpltInds(i));
    x.FontSize = 10;
    
    if i < 4
        x.Title.String = monks{i};
        x.Title.FontSize = 20;
    else
        x.Title.String = '';
        
        for j = 1:4
            x.Children(j).FontSize = 10;
        end
    end
    
    if i == 4
        x.Title.String = ['3-way ANOVA: p_{monkey} = ',num2str(pvals(1,condInd))];
    end
    if i == 5
        x.Title.String = ['3-way ANOVA: p_{Purs Dir} = ',num2str(pvals(2,condInd))];
    end
    if i == 6
        x.Title.String = ['3-way ANOVA: p_{Head Dir} = ',num2str(pvals(3,condInd))];
    end
end

if ~saveSuppress
    hgsave(combfig.fig,[combDir,parNames{paramInd},'/monkcomp/',cond{condInd},'_separate.fig']);
end

end





