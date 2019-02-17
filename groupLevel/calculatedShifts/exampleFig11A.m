% example fig for 11A
Z = 50:150;

[comPref] = comFinder([0 10 0],[0 0 50],50,0);
[comFit] = comFinder([0 10 0],[-10.968 0 50],50,0);

f = figure;
f.Position = [300 300 630 535];
hold on

plot(atand(comPref/50),Z,'k','LineWidth',2);
plot(atand(comFit/50),Z,'r','LineWidth',2);

plot([0 0],[42 50],'r','LineWidth',2);
scatter(0,48,100,'r','filled','v');
plot([-50 50],[59 59],'--k');
plot([-50 50],[50 50],'k');

set(gca,'XLim',[-10 50],'ylim',[35 Z(end)],'FontSize',20,'xtick',-50:10:50,'ytick',50:20:150);

xlabel('Center of Motion (\circ)');
ylabel('Plane Distance (cm)');