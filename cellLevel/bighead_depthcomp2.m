function [compstr,fits,heads,nonverts,daxmin,daxmax] = bighead_depthcomp2(datpath,monkey,param)
% Run stats/display figures for volume vs. single plane comparison
%
% Usage: [] = bighead_depthcomp2(monkey(e.g. 'qbh' or 'pbh'),param(1:4))
%        1: Preferred Az Dir, 2: Amplitude,3: Offset,4: Bandwidth
% output plots circle data pairs for cells that don't prefer vertical
% headings

% Load in data
depthDatpath = [datpath,'/depth_comps/'];

cellmat = dir([depthDatpath,monkey,'*']);
cells = arrayfun(@(x) x.name,cellmat,'UniformOutput',false);
% mask = ones(11,1,'logical');
% mask([2 6 9]) = 0;
% cells = cells(mask);
numcells = numel(cells);

compstr = struct;

for i = 1:numcells
    load([depthDatpath,cells{i}]);
    
    compstr(i).cell = depthcomp.cell;
    compstr(i).prefhead = depthcomp.prefhead;
    compstr(i).sets = depthcomp.sets;
    compstr(i).depth_conds = depthcomp.depth_conds;
    compstr(i).pursuit_conds = depthcomp.pursuit_conds;
    compstr(i).dirtun_diff = depthcomp.dirtun_diff;
    compstr(i).dirtuning = depthcomp.dirtuning;
    compstr(i).bandwidth = depthcomp.bandwidth;
    compstr(i).offset = depthcomp.offset;
    compstr(i).amp = depthcomp.amp;
end
% ----------------------------------------------------------------------- %
% Plots

% Preferred Headings
prefaz = arrayfun(@(x) x.prefhead(1),compstr);
prefel = arrayfun(@(x) x.prefhead(2),compstr);
nonverts = abs(prefel) < 90;

heads = zeros(5,8);
for i = 1:numel(prefaz)     % Get 2D histogram of heading prefs
    heads(3 + -1*prefel(i)./45,1 + prefaz(i)./45) = ...
        heads(3 + -1*prefel(i)./45,1 + prefaz(i)./45) + 1;
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
set(gcf,'Position',[50 200 500 240]);
imagesc(azvec,elvec,y);
title('Heading Preference Distribution');
set(gca,'XLim',[-200 200],'YLim',[-110 110],'XTick',-180:45:180,...
    'YTick',-90:45:90,'FontSize',10);
cmap = [linspace(0,1,max(max(y)) + 1)' ...
    linspace(0,1,max(max(y)) + 1)' linspace(0,1,max(max(y)) + 1)'];
colormap(headfig,cmap);

cbar = colorbar('Ticks',0:1:max(max(y)));
cbar.Label.String = 'Number of Cells';

%%%% Parameter fit comparisons
p = param;

condnames = {'Normal Pursuit','Simulated Pursuit','Stabilized Pursuit'};
paramnames = {'Preferred Az Dir','Amplitude','Offset','Bandwidth'};
paramvars = {'dirtuning','amp','offset','bandwidth'};
pursconds = {'(L)','(R)'};
colors = [0 0 0; 0 0 0.7; 0.7 0 0];
sp_pos = [1 3 5 2 4 6];

axmax = max(arrayfun(@(x) max(max(x.(paramvars{p}))),compstr))*1.1;
axmin = min(arrayfun(@(x) min(min(x.(paramvars{p}))),compstr))*1.1;

if axmax < 360  && p == 1
    axmax = 360;
end
if axmin > 0 && p == 1
    axmin = 0;
end

daxmax = max([arrayfun(@(x) max(x.(paramvars{p})(2:end,1) - x.(paramvars{p})(1,1)),compstr)...
    arrayfun(@(x) max(x.(paramvars{p})(2:end,2) - x.(paramvars{p})(1,2)),compstr)])*1.1;
daxmin = min([arrayfun(@(x) min(x.(paramvars{p})(2:end,1) - x.(paramvars{p})(1,1)),compstr)...
    arrayfun(@(x) min(x.(paramvars{p})(2:end,2) - x.(paramvars{p})(1,2)),compstr)])*1.1;

% Fixation
volfix = arrayfun(@(x) x.(paramvars{p})(1,1),compstr);
spfix = arrayfun(@(x) x.(paramvars{p})(1,2),compstr);

fixfig = figure;
set(gcf,'Position',[50 525 380 320]);
hold on;
title('Fixation');
scatter(volfix,spfix,50,'filled',...
    'MarkerFaceColor',[0 0.7 0]);
scatter(volfix(nonverts),spfix(nonverts),120,'k');
plot([axmin axmax],[axmin axmax],'--k');
xlabel([paramnames{p},' (Volume)']);
ylabel([paramnames{p},' (SDP)']);
set(gca,'XLim',[axmin axmax],'YLim',[axmin axmax]);

% Pursuit conditions
paramfig = figure;
set(gcf,'Position',[590 50 650 950]);
for i = 1:3
    for j = 0:1
        vol = arrayfun(@(x) x.(paramvars{p})(i+1+j*3,1),compstr);
        sp = arrayfun(@(x) x.(paramvars{p})(i+1+j*3,2),compstr);
        
        subplot(3,2,sp_pos(i + j*3));
        hold on;
        title([condnames{i},' ',pursconds{j+1}]);
        scatter(vol,sp,50,'filled',...
            'MarkerFaceColor',colors(i,:));
        scatter(vol(nonverts),sp(nonverts),120,'k');
        plot([axmin axmax],[axmin axmax],'--k');
        xlabel([paramnames{p},' (Volume)']);
        ylabel([paramnames{p},' (SDP)']);
        set(gca,'XLim',[axmin axmax],'YLim',[axmin axmax]);
    end
end

fits = cell(3,2);

paramdifffig = figure;
set(gcf,'Position',[1260 50 650 950]);
for i = 1:3
    for j = 0:1
        vol = arrayfun(@(x) x.(paramvars{p})(i+1+j*3,1),compstr) - ...
            arrayfun(@(x) x.(paramvars{p})(1,1),compstr);
        sp = arrayfun(@(x) x.(paramvars{p})(i+1+j*3,2),compstr) - ...
            arrayfun(@(x) x.(paramvars{p})(1,2),compstr);
        
        % Get linear regression (b = [intercept,slope]) & r^2
        volpad = [ones(numel(vol),1) vol'];
        b = volpad\(sp)';
        
        spfit = volpad*b;
        rsqr = 1 - sum((sp - spfit').^2)/sum((sp - mean(sp)).^2);
        rsqr = round(rsqr,4);
        
        fits{i + j*3} = b;
        
        subplot(3,2,sp_pos(i + j*3));
        hold on;
        title([condnames{i},' ',pursconds{j+1}]);
        scatter(vol,sp,50,'filled',...
            'MarkerFaceColor',colors(i,:));
        scatter(vol(nonverts),sp(nonverts),120,'k');
        plot([daxmin daxmax],[daxmin daxmax],'--k');
        plot([daxmin daxmax],[daxmin*b(2)+b(1) daxmax*b(2)+b(1)],'Color',colors(i,:));
        xlabel(['\Delta ',paramnames{p},' (Volume)']);
        ylabel(['\Delta ',paramnames{p},' (SDP)']);
        set(gca,'XLim',[daxmin daxmax],'YLim',[daxmin daxmax]);
        text(15,1.4*(daxmin)/3,['r^2 = ',num2str(rsqr),],'FontSize',10);
        text(15,2.2*(daxmin)/3,['m = ',num2str(round(b(2),4)),],'FontSize',10);
    end
end

% Save
hgsave(headfig,[depthDatpath,'heading_hist']);
hgsave(fixfig,[depthDatpath,'fixation_',paramvars{param}]);
hgsave(paramfig,[depthDatpath,'param_comp_',paramvars{param}]);
hgsave(paramdifffig,[depthDatpath,'param_diff_comp_',paramvars{param}]);

end