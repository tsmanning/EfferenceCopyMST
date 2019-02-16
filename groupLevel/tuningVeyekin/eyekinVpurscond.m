function [resGain,resSacc,f1,f2,f3,f4,tbl1,tbl2,p1,p2] = eyekinVpurscond(comb_monks,inds)

% Run test for pursuit quality differences between conditions aross cell
% sample

close all
close all hidden

numSacc = comb_monks.numSacc(inds,:);
gain = comb_monks.pursGain(inds,:);
headHoriz = sind(comb_monks.headcents(inds,:))<sind(45);

% % one-way ANOVA
% [p1,tbl1,stats1] = anova1(numSacc,{'Fixation','Normal (L)','Normal (R)',...
%     'Simulated (L)','Simulated (R)','Stabilized (L)','Stabilized (R)'},'off');
% 
% [p2,tbl2,stats2] = anova1(gain(:,[2 3 6 7]),{'Normal (L)','Normal (R)',...
%     'Stabilized (L)','Stabilized (R)'},'off');

% three-way ANOVA (pursuit type, direction, and heading laterality as factors)
pursCond = repelem({'Fixation','Normal','Normal','Simulated','Simulated','Stabilized','Stabilized'}',length(gain));
pursDir = repelem({'none','left','right','left','right','left','right'}',length(gain));
headHoriz1 = repmat(headHoriz,[7,1]);
numSacc2 = reshape(numSacc,[numel(numSacc),1]);

[p1,tbl1,stats1] = anovan(numSacc2,{pursCond,pursDir,headHoriz1});

pursCond2 = repelem({'Normal','Normal','Stabilized','Stabilized'}',length(gain));
pursDir2 = repelem({'left','right','left','right'},length(gain));
headHoriz2 = repmat(headHoriz,[4,1]);
gain2 = reshape(gain(:,[2 3 6 7]),[numel(gain(:,[2 3 6 7])),1]);

[p2,tbl2,stats2] = anovan(gain2,{pursCond2,pursDir2,headHoriz2});

% t-tests
resGain = [];
resSacc = [];
diffmeanGain = [];
diffmeanSacc = [];
f1=[];
f2=[];

if p1 < 0.05
    [resSacc,diffmeanSacc,f1] = multcompare(stats1);
end

if p2 < 0.05
    [resGain,diffmeanGain,f2] = multcompare(stats2);
end

% Trialwise scatterplots

f3 = figure;
f3.Position = [300 300 605 650];
hold on;
% reshape to vector
x1 = repmat([1 2 3 4 5 6 7],length(numSacc),1);
x1 = reshape(x1,[numel(x1),1]);
y1 = reshape(numSacc,[numel(numSacc),1]);
scatter(x1,y1,70,'k','filled');
scatter([1 2 3 4 5 6 7],median(numSacc,'omitnan'),70,'r','filled');
set(gca,'xtick',1:7,'xticklabel',{'Fixation','Normal (L)','Normal (R)','Simulated (L)','Simulated (R)','Stabilized (L)','Stabilized (R)'},...
    'fontsize',20,'ylim',[0 4]);
xtickangle(gca,45);
% text(1,0.2,['p = ',num2str(round(p2,3,'significant'))],'FontSize',20);
ylabel('Mean Saccades per Trial');

f4 = figure;
f4.Position = [950 300 605 650];
hold on;
% reshape to vector
x2 = repmat([1 2 3 4],length(gain),1);
x2 = reshape(x2,[numel(x2),1]);
y2 = reshape(gain(:,[2 3 6 7]),[numel(gain(:,[2 3 6 7])),1]);
scatter(x2,y2,70,'k','filled');
scatter([1 2 3 4],median(gain(:,[2 3 6 7]),'omitnan'),70,'r','filled');
plot([1 4],[1 1],'--k','linewidth',2);
set(gca,'xtick',1:7,'xticklabel',{'Normal (L)','Normal (R)','Stabilized (L)','Stabilized (R)'},...
    'fontsize',20,'ylim',[0 1.5]);
% text(1,4.5,['p = ',num2str(round(p1,3,'significant'))],'FontSize',20);
xtickangle(gca,45);
ylabel('Pursuit Gain');

% % Construct t-test trees
% l12 = [];

keyboard






end