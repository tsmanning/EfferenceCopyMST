function [f1,f2,r,p] = gainVshift(comb_monks)

% Check for significant correlation between pursuit gain and magnitude of
% tuning shift

a = comb_monks.centshift_mat(:,[1 2 5 6]);
b = comb_monks.pursGain(:,[2 3 6 7]);

close all

r = nan(4,1);
p = nan(4,1);

f1 = figure;
f1.Position = [100 100 750 650];
f1.Renderer = 'painters';
hold on;
% Normal
inds1 = and(~isnan(b(:,1)),~isnan(a(:,1)));
scatter(b(:,1),a(:,1),80,'filled',...
    'MarkerFaceColor',[0 0 0],...
    'MarkerEdgeColor',[0 0 0]);
[r(1),p(1)] = corr(b(inds1,1),a(inds1,1),'Type','Spearman');

inds2 = and(~isnan(b(:,2)),~isnan(a(:,2)));
scatter(b(:,2),a(:,2),80,'filled',...
    'MarkerFaceColor',[0.7 0.7 0.7],...
    'MarkerEdgeColor',[0.7 0.7 0.7]);
[r(2),p(2)] = corr(b(inds2,2),a(inds2,2),'Type','Spearman');
set(gca,'ylim',[-100 100],'xlim',[0.5 1.2],'fontsize',20);
xlabel('Pursuit Gain');
ylabel('Heading Preference Shift');
title('Normal Pursuit');
text(0.55,75,['Left Pursuit'],'color',[0 0 0],'fontsize',20);
text(0.55,65,['Right Pursuit'],'color',[0.5 0.5 0.5],'fontsize',20);
text(0.55,-50,['r = ',num2str(round(r(2),3,'significant'))],'fontsize',20);
text(0.55,-60,['p = ',num2str(round(p(2),3,'significant'))],'fontsize',20);

[r(5),p(5)] = corr([b(inds1,1);b(inds2,2)],[-a(inds1,1);a(inds2,2)],'Type','Spearman');

f2 = figure;
f2.Position = [900 100 750 650];
f2.Renderer = 'painters';
hold on;
% Stabilized
inds3 = and(~isnan(b(:,3)),~isnan(a(:,3)));
scatter(b(:,3),a(:,3),80,'filled',...
    'MarkerFaceColor',[0.7 0 0],...
    'MarkerEdgeColor',[0.7 0 0]);
[r(3),p(3)] = corr(b(inds3,3),a(inds3,3),'Type','Spearman');

inds4 = and(~isnan(b(:,4)),~isnan(a(:,4)));
scatter(b(:,4),a(:,4),80,'filled',...
    'MarkerFaceColor',[1 0 0],...
    'MarkerEdgeColor',[1 0 0]);
[r(4),p(4)] = corr(b(inds4,4),a(inds4,4),'Type','Spearman');
set(gca,'ylim',[-100 100],'xlim',[0.5 1.2],'fontsize',20);
xlabel('Pursuit Gain');
ylabel('Heading Preference Shift');
title('Stabilized Pursuit');
text(0.55,75,['Left Pursuit'],'color',[0.5 0 0],'fontsize',20);
text(0.55,65,['Right Pursuit'],'color',[1 0 0],'fontsize',20);
text(0.55,-50,['r = ',num2str(round(r(4),3,'significant'))],'fontsize',20);
text(0.55,-60,['p = ',num2str(round(p(4),3,'significant'))],'fontsize',20);

[r(6),p(6)] = corr([b(inds3,3);b(inds4,4)],[-a(inds3,3);a(inds4,4)],'Type','Spearman');
end