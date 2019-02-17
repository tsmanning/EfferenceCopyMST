function [depthcomp] = bighead_depthcomp1(monkey,cellid,vol_datapath,sp_datapath,saveon)
% Comparison between full 100cm volume and single depth plane versions of
% bighead.
%
% Usage: [] = bighead_depthcomp(path,vol_datapath,sp_datapath)

% Load in data and setup parameters
% params = [Fixation            Amp - Pref Az (rad) - Band - Offset
%           Normal (R)
%           Simulated (R)
%           Stabilized (R)
%           Normal (L)
%           Simulated (L)
%           Stabilized (L)                                              ]
%
% data_table - positions of right/left blocks are reversed, so L comes
% first

datpath = ['/home/tyler/matlab/data/',monkey,'/',cellid];

load([datpath,'/heading_tuning/head_trials']);

load([datpath,'/bh_tests/',vol_datapath,'/bh_trials']);
load([datpath,'/bh_tests/',vol_datapath,'/trial_data']);
load([datpath,'/bh_tests/',vol_datapath,'/data_fits/params']);
load([datpath,'/bh_tests/',vol_datapath,'/data_fits/data_table']);
volBhTrials = bh_trials;
volTrialData = trial_data;
volParams = params;

vol.conds = data_table(2:8,1);
vol.aztun = cell2mat(data_table(2:8,4));
vol.band = cell2mat(data_table(2:8,5));
vol.offset = cell2mat(data_table(2:8,5));
vol.amp = cell2mat(data_table(2:8,5));

load([datpath,'/bh_tests/',sp_datapath,'/bh_trials']);
load([datpath,'/bh_tests/',sp_datapath,'/trial_data']);
load([datpath,'/bh_tests/',sp_datapath,'/data_fits/params']);
load([datpath,'/bh_tests/',sp_datapath,'/data_fits/data_table']);
spBhTrials = bh_trials;
spTrialData = trial_data;
spParams = params;

sp.conds = data_table(2:8,1);
sp.aztun = cell2mat(data_table(2:8,4));
sp.band = cell2mat(data_table(2:8,5));
sp.offset = cell2mat(data_table(2:8,3));
sp.amp = cell2mat(data_table(2:8,2));

vonmises = @(x,angles) (x(1)/(1-exp(-4/x(3)^2))) * ...
    (exp(-2.*(1-cos(angles-x(2)))/(x(3))^2) - exp(-4/x(3)^2)) + x(4);
angles = min(volTrialData.trial_az):1:max(volTrialData.trial_az);
calcangles = angles*(pi/180);

% Get preferred 2D heading
depthcomp.cell = cellid;

FRs = arrayfun(@(x) x.mean_FR,head_trials);
[~,maxind] = max(FRs);
depthcomp.prefhead = ...
    [head_trials(maxind).head_az head_trials(maxind).head_el];

% Sort parameter fits

depthcomp.sets = {vol_datapath,sp_datapath};
depthcomp.depth_conds = {'volume','single plane'};
depthcomp.pursuit_conds = {'fixation';...
    'normal (L)';'simulated (L)';'stabilized (L)';...
    'normal (R)';'simulated (R)';'stabilized (R)'};

depthcomp.dirtun_diff(:,1) = vol.aztun(2:end) - vol.aztun(1);
depthcomp.dirtun_diff(:,2) = sp.aztun(2:end) - sp.aztun(1);

depthcomp.dirtuning(:,1) = vol.aztun;
depthcomp.dirtuning(:,2) = sp.aztun;

depthcomp.bandwidth(:,1) = vol.band;
depthcomp.bandwidth(:,2) = sp.band;

depthcomp.offset(:,1) = vol.offset;
depthcomp.offset(:,2) = sp.offset;

depthcomp.amp(:,1) = vol.amp;
depthcomp.amp(:,2) = sp.amp;

%-------------------------------------------------------------------------%
param_scatter = 1;
tun_curves = 1;

if param_scatter
    % Plot fitted parameters for two depth conditions
    figure;
    set(gcf,'Position',[100 400 700 500]);
    c = {'Normal','Simulated','Stabilized'};
    colors = [0 0 0;...
        0 0 0.7;...
        0.7 0 0];
    ymax = max([depthcomp.dirtun_diff(:,1);depthcomp.dirtun_diff(:,2)])*1.1;
    ymin = min([depthcomp.dirtun_diff(:,1);depthcomp.dirtun_diff(:,2)])*1.1;
    
    subplot(2,2,1);
    hold on;
    title('Multiple Depth Planes (Left Purs)');
    bar(depthcomp.dirtun_diff(1:3,1));
    set(gca,'xtick',[1:3],'xticklabel',c,'xlim',[0.5 3.5],'ylim',[ymin ymax]);
    % b.FaceColor = 'flat';
    % b.CData = colors;
    
    subplot(2,2,3);
    hold on;
    title('Single Depth Plane (Left Purs)');
    bar(depthcomp.dirtun_diff(1:3,2));
    set(gca,'xtick',[1:3],'xticklabel',c,'xlim',[0.5 3.5],'ylim',[ymin ymax]);
    % b.FaceColor = 'flat';
    % b.CData = colors;
    
    subplot(2,2,2);
    hold on;
    title('Multiple Depth Planes (Right Purs)');
    bar(depthcomp.dirtun_diff(4:6,1));
    set(gca,'xtick',[1:3],'xticklabel',c,'xlim',[0.5 3.5],'ylim',[ymin ymax]);
    % b.FaceColor = 'flat';
    % b.CData = colors;
    
    subplot(2,2,4);
    hold on;
    title('Single Depth Plane (Right Purs)');
    bar(depthcomp.dirtun_diff(4:6,2));
    set(gca,'xtick',[1:3],'xticklabel',c,'xlim',[0.5 3.5],'ylim',[ymin ymax]);
    % b.FaceColor = 'flat';
    % b.CData = colors;
end

if tun_curves
    % Plot tuning curves from depth conditions side-by-side
    figure;
    set(gcf,'Position',[850 100 1000 800]);
    minang = angles(1);
    maxang = angles(end);
    maxFR = max([volParams(:,1) + volParams(:,4);...
        spParams(:,1) + spParams(:,4)])*1.1;
    
    i = 0;
    
    subplot(2,2,1);
    hold on;
    Vfixpar = volParams(1,:);
    SPfixpar = spParams(1,:);
    title('Fixation');
    plot(angles,vonmises(Vfixpar,calcangles),'Color',[0 0.7 0]);
    plot(angles,vonmises(SPfixpar,calcangles),'Color',[0 0.7 0],'LineStyle','--');
    set(gca,'XLim',[minang maxang],'YLim',[0 maxFR]);
    
    subplot(2,2,2);
    hold on;
    Vnorpar = volParams(2 + 3*i,:);
    SPnorpar = spParams(2 + 3*i,:);
    title('Normal Pursuit');
    plot(angles,vonmises(Vnorpar,calcangles),'Color',[0 0 0]);
    plot(angles,vonmises(SPnorpar,calcangles),'Color',[0 0 0],'LineStyle','--');
    set(gca,'XLim',[minang maxang],'YLim',[0 maxFR]);
    
    subplot(2,2,3);
    hold on;
    Vsimpar = volParams(3 + 3*i,:);
    SPsimpar = spParams(3 + 3*i,:);
    title('Simulated Pursuit');
    plot(angles,vonmises(Vsimpar,calcangles),'Color',[0 0 0.7]);
    plot(angles,vonmises(SPsimpar,calcangles),'Color',[0 0 0.7],'LineStyle','--');
    set(gca,'XLim',[minang maxang],'YLim',[0 maxFR]);
    
    subplot(2,2,4);
    hold on;
    Vstabpar = volParams(4 + 3*i,:);
    SPstabpar = spParams(4 + 3*i,:);
    title('Stabilized Pursuit');
    plot(angles,vonmises(Vstabpar,calcangles),'Color',[0.7 0 0]);
    plot(angles,vonmises(SPstabpar,calcangles),'Color',[0.7 0 0],'LineStyle','--');
    set(gca,'XLim',[minang maxang],'YLim',[0 maxFR]);
end

% Save
if saveon
    popdatadir = ['/home/tyler/matlab/data/',monkey,'/population_data/'];
    
    if exist([popdatadir,'depth_comps'],'dir')==0
        mkdir(popdatadir,'depth_comps');
    end
    
    save([popdatadir,'depth_comps/',cellid],'depthcomp');
end

end