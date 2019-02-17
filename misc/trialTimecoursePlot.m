function trialTimecoursePlot(SR,trlength)

% Plot trial timecourse
%
% Usage: trialTimecoursePlot(SR,trlength)
%        trialTimecoursePlot(1,'long')

switch trlength
    case 'short'
        t = [-170 0 400 600 1000];
    case 'long'
        t = [-170 0 400 550 1400];
end

pursVel = 10;
pursSign = 1;

epochHP = (t(end)-t(end-1))/1000;
epochEps = (t(4)-t(3))/1000;

offsetHP = -pursSign*pursVel*epochHP/2;
offsetPurs = offsetHP + -pursSign*epochEps*pursVel;

tpts = 0:0.001:(t(end)-t(3))/1000;

tfix = t(1)-500:t(3)-1;

f = figure;
f.Position = [50 100 560 530];
subplot(2,1,1);
hold on;
switch t(end)
    case 1000
        fix = offsetPurs*ones(t(3)-(t(1)-500),1);
        fill([1000 1000 1400 1400],[-10 10 10 -10],'k');
    case 1400
        if SR
            fix = offsetHP*ones(t(3)-(t(1)-500),1);
        else
            fix = offsetPurs*ones(t(3)-(t(1)-500),1);
        end
end

tpurs = t(3):t(5);
pursStepRamp = offsetPurs + pursSign*tpts*pursVel;

plot(tfix,fix,'k','LineWidth',2);
plot(tpurs,pursStepRamp,'k','LineWidth',2);

plot(tfix,-fix,'k','LineWidth',2);
plot(tpurs,-pursStepRamp,'k','LineWidth',2);

plot([tfix';tpurs'],zeros(numel([tfix';tpurs']),1),'k','LineWidth',2);

% plot([t(4) t(4)],[-10 10],'--k');
fill([t(4) t(4) t(end) t(end)],[-10 10 10 -10],[0 0 1],...
    'FaceAlpha',0.1,'EdgeColor',[0 0 1],'FaceAlpha',0.1);

xlabel('Time from self-motion start (ms)');
ylabel('Horizontal Eye Position (\circ)');
set(gca,'YLim',[-10 10],'XLim',[-670 1400]);
text(640,7,sprintf('Analysis \nWindow'));

subplot(2,1,2);
hold on;
set(gca,'YLim',[-0.25 2.5],'XLim',[-670 1400],'YTick',[]);
% plot([t(4) t(4)],[-0.25 2.5],'--k');
fill([t(4) t(4) t(end) t(end)],[-10 10 10 -10],[0 0 1],...
    'FaceAlpha',0.1,'EdgeColor',[0 0 1],'FaceAlpha',0.1);

% Dots on
plot([t(1)-500 t(1)],[0 0],'k','LineWidth',2);
plot([t(1) t(end)],[1 1],'k','LineWidth',2);
plot([t(1) t(1)],[0 1],'k','LineWidth',2);
text(t(1)-450,0.2,'Dots On');

% Translation Start
plot([t(1)-500 t(2)],[1.25 1.25],'k','LineWidth',2);
plot([t(2) t(end)],[2.25 2.25],'k','LineWidth',2);
plot([t(2) t(2)],[1.25 2.25],'k','LineWidth',2);
text(t(1)-450,1.45,'Self-Motion On');

if t(end) == 1000
    fill([1000 1000 1400 1400],[-10 10 10 -10],'k');
end

%% Screen stills
% ITI White Fill
f1 = figure;
f1.Position = [100 100 640 360];
hold on;
fill([-320 320 320 -320],[-180 -180 180 180],'w');
set(gca,'YLim',[-180 180],'XLim',[-320 320],'Visible','off','Box','off');

% FP On
f2 = figure;
f2.Position = [300 100 640 360];
hold on;
fill([-320 320 320 -320],[-180 -180 180 180],'k');
scatter(0,0,100,'r','filled');
set(gca,'YLim',[-180 180],'XLim',[-320 320],'Visible','off','Box','off');

% Dots On
f3 = figure;
f3.Position = [500 100 640 360];
hold on;
fill([-320 320 320 -320],[-180 -180 180 180],'k');
scatter(0,0,100,'r','filled');
xpts = randi(600,60,1);
xpts = xpts - 640/2;
ypts = randi(320,60,1);
ypts = ypts - 360/2;
scatter(xpts,ypts,60,'w','filled');
set(gca,'YLim',[-180 180],'XLim',[-320 320],'Visible','off','Box','off');

% Translation On
T = 50;
R = 5*(pi/180);
dxdt = @(x,T,R) (x.*T)/50 - (1/50)*R*x.^2 - 50*R;
dydt = @(x,y,T,R) (y.*T)/50 - y.*x.*(1/50)*R;

f4 = figure;
f4.Position = [700 100 640 360];
hold on;
fill([-320 320 320 -320],[-180 -180 180 180],'k');
quiver(xpts,ypts,dxdt(xpts./50,T,0),dydt(xpts./50,ypts./50,T,0),...
    'Color','w','LineWidth',2,'MaxHeadSize',5);
scatter(0,0,100,'r','filled');
set(gca,'YLim',[-180 180],'XLim',[-320 320],'Visible','off','Box','off');

% Pursuit Start
f5 = figure;
f5.Position = [900 100 640 360];
hold on;
fill([-320 320 320 -320],[-180 -180 180 180],'k');
quiver(xpts,ypts,dxdt(xpts./50,T,R),dydt(xpts./50,ypts./50,T,R),...
    'Color','w','LineWidth',2,'MaxHeadSize',5);
scatter(0,0,100,'r','filled');
quiver(0,0,100,0,...
    'Color','r','LineWidth',2,'MaxHeadSize',10);
set(gca,'YLim',[-180 180],'XLim',[-320 320],'Visible','off','Box','off');


end