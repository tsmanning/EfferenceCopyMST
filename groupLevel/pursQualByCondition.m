% Run test for pursuit quality differences between conditions aross cell
% sample

close all
close all hidden

numSacc = comb_monks.numSacc;
gain = comb_monks.pursGain;

[p1,tbl1] = anova1(numSacc,{'Fixation','Normal (L)','Normal (R)','Simulated (L)','Simulated (R)','Stabilized (L)','Stabilized (R)'});
f1 = figure(2);
f1.Position = [300 300 605 650];
a1 = f1.Children(1);
set(a1,'FontSize',20,'ylim',[0 5]);
ylabel('Number of Saccades');
xtickangle(a1,45);
text(1,4.5,['p = ',num2str(round(p1,3,'significant'))],'FontSize',20);

[p2,tbl2] = anova1(gain(:,[2 3 6 7]),{'Normal (L)','Normal (R)','Stabilized (L)','Stabilized (R)'});
f2 = figure(4);
f2.Position = [950 300 605 650];
a2 = f2.Children(1);
set(a2,'FontSize',20,'ylim',[0 1.2]);
ylabel('Pursuit Gain');
xtickangle(a2,45);
text(1,0.2,['p = ',num2str(round(p2,3,'significant'))],'FontSize',20);

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
ylabel('Number of Saccades per Trial');

f4 = figure;
f4.Position = [950 300 605 650];
hold on;
% reshape to vector
x2 = repmat([1 2 3 4],length(numSacc),1);
x2 = reshape(x2,[numel(x2),1]);
y2 = reshape(gain(:,[2 3 6 7]),[numel(gain(:,[2 3 6 7])),1]);
scatter(x2,y2,70,'k','filled');
scatter([1 2 3 4],median(gain(:,[2 3 6 7]),'omitnan'),70,'r','filled');
plot([1 4],[1 1],'--k','linewidth',2);
set(gca,'xtick',1:7,'xticklabel',{'Normal (L)','Normal (R)','Stabilized (L)','Stabilized (R)'},...
    'fontsize',20,'ylim',[0 1.5]);
xtickangle(gca,45);
ylabel('Pursuit Gain');