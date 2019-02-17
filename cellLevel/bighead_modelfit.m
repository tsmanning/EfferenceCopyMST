function [params]=bighead_modelfit(path,test_set,showtable,num_eyes,headset,plot_suppress)

% --------------------------------------------------------------------%

% Fits tuning data in different conditions with circular gaussian and
% identifies changes in gain/dc offset/preferred direction

% First pass at script leaves all model parameters free

% --------------------------------------------------------------------%

% Load in data:

% trial_data.fr_plot_HT is a 7x7 matrix organized as follows
%     [No pursuit(angles 1:7);
%      Normal pursuit R (angles 1:7);
%      Normal pursuit L (angles 1:7);
%      Simulated Pursuit R (angles 1:7);
%      Simulated Pursuit L (angles 1:7);
%      Stabilized Pursuit R (angles 1:7);
%      Stabilized Pursuit L (angles 1:7)]
% Reorganized to no pursuit (1), R(2,3,4), and L(5,6,7) conditions (NP,SiP,StP)

viewing_opts={'monoc','binoc'};

if test_set~=0 && ischar(test_set)==0
    set_no=num2str(test_set);
    set_dir=['set',set_no,'/'];
elseif test_set==0
    set_dir='';
elseif test_set=='m'
    set_dir=['set_merge_',viewing_opts{num_eyes},'/'];
end

load([path '/bh_tests/',set_dir,'trial_data.mat'])

if headset~=0   % For multiple heading trials
    load([path '/heading_tuning/set',num2str(headset),'/head_trials.mat'])
else
    load([path '/heading_tuning/','head_trials.mat'])
end

% Get coarse heading tuning data for initial fit
elevation=trial_data.trial_el(1);

count=1;
for i=1:26
    if head_trials(i).head_el==elevation
        head_data(1,count)=head_trials(i).head_az;
        head_data(2,count)=head_trials(i).mean_FR;
        head_data(3,count)=head_trials(i).FR_std;
        
        count=count+1;
    end
end

data=trial_data.fr_plot_HP;
std=trial_data.std_plot_HP;
[~,data_max_ind1]=max(data);
[data_max,data_max_ind2]=max(max(data));
std_max=std(data_max_ind1(data_max_ind2),data_max_ind2);
data_max=1.05*(data_max+std_max);   % For plotting

angles=unique(round(trial_data.trial_az,2));
angles=angles';

reorg=[1 2 4 6 3 5 7];
for j=1:7
    reorgdata(j,:)=data(reorg(j),:);
    reorgstd(j,:)=std(reorg(j),:);
end

% Calculate model parameters

for i=1:7
    [fit_params(i,:),rsqr(i),output_info(i),band(i)] = ...
        von_mises_fit(angles,reorgdata(i,:),0,0,1);  % Data in deg, suppress plotting
end

% check parameter numbering if converting back to using skew parameter
gains=fit_params(:,1);
band_fact=fit_params(:,3);
pref_dir=fit_params(:,2).*(180/pi);  % Convert back to deg for table
% skew_fact=fit_params(:,4);
offsets=fit_params(:,4);

fit_params(:,2)=fit_params(:,2); % Keep pref dir/bandwidth in degrees for table,
% convert to rads for plotting

%-------------------------------------------------------------------------%
% Plot data and fits

if ~plot_suppress
    
    func_angles=linspace(min(angles),max(angles),1000);
    vonmises=@(x,angles)(x(1)/(1-exp(-4/x(3)^2)))*(exp(-2.*(1-cos(angles-x(2)))/(x(3))^2)-exp(-4/x(3)^2))+x(4);
    % vonmises=@(x,angles)(x(1)/(1-exp(-2*x(2)))).*(exp(-x(2).*(1-cos(angles-x(3)-x(4).*(1-cos(angles-x(3))))))-exp(-2*x(2)))+x(5);
    
    fitsfig = figure;
    hold on;
    set(gcf,'Position',[5 345 1200 645]);   % Define Figure Window Size for 1080i
    func = zeros(7,1000);
    func(1,:) = vonmises(fit_params(1,:),func_angles.*(pi/180));
    colors = [0 0 0; 0 0 0.8; 0.8 0 0];
    
    % Heading only
    subplot(1,2,1);
    hold on;
    errorbar(angles,reorgdata(1,:),reorgstd(1,:),'.',...  % Plot data points
        'MarkerSize',20,...
        'MarkerFaceColor',[0 0.8 0],...
        'MarkerEdgeColor',[0 0.8 0],...
        'LineWidth',0.1,...
        'Color',[0 0.8 0]);
    plot(func_angles,func(1,:),'Color',[0 0.8 0]);       % Plot function
    subplot(1,2,2);hold on;
    errorbar(angles,reorgdata(1,:),reorgstd(1,:),'.',...  % Plot data points
        'MarkerSize',20,...
        'MarkerFaceColor',[0 0.8 0],...
        'MarkerEdgeColor',[0 0.8 0],...
        'LineWidth',0.1,...
        'Color',[0 0.8 0]);
    plot(func_angles,func(1,:),'Color',[0 0.8 0]);       % Plot function
    
    for a=1:3   % Pursuit conditions
        % Left Pursuit
        subplot(1,2,1);hold on;
        errorbar(angles,reorgdata(a+4,:),reorgstd(a+4,:),'.',... % Plot data points
            'MarkerSize',20,...
            'MarkerFaceColor',colors(a,:),...
            'MarkerEdgeColor',colors(a,:),...
            'LineWidth',0.1,...
            'Color',colors(a,:));
        func(a+4,:)=vonmises(fit_params(a+4,:),func_angles.*(pi/180));
        plot(func_angles,func(a+4,:),'Color',colors(a,:));    % Plot function
        
        % Right Pursuit
        subplot(1,2,2);hold on;
        errorbar(angles,reorgdata(a+1,:),reorgstd(a+1,:),'.',... % Plot data points
            'MarkerSize',20,...
            'MarkerFaceColor',colors(a,:),...
            'MarkerEdgeColor',colors(a,:),...
            'LineWidth',0.1,...
            'Color',colors(a,:));
        func(a+1,:)=vonmises(fit_params(a+1,:),func_angles.*(pi/180));
        plot(func_angles,func(a+1,:),'Color',colors(a,:));    % Plot function
    end
    
    s = sprintf(char(176));
    dir={' Left',' Right'};
    
    subplot(1,2,1);
    set(gca,'XTick',angles,'XLim',[min(angles),max(angles)],'YLim',[0,data_max],...
        'Box','off','FontSize',15);
    xlabel(['Heading Direction (',s,' Azimuth)'],'FontSize',15);
    ylabel('Firing Rate (Hz)','FontSize',15);
    title(strcat('Pursuit',' ',dir(1)));  %left or right
    
    subplot(1,2,2);
    set(gca,'XTick',angles,'XLim',[min(angles),max(angles)],'YLim',[0,data_max],...
        'Box','off','FontSize',15);
    xlabel(['Heading Direction (',s,' Azimuth)'],'FontSize',15);
    ylabel('Firing Rate (Hz)','FontSize',15);
    title(strcat('Pursuit',' ',dir(2)));  %left or right
end
%-------------------------------------------------------------------------%

% Plot table with each curve's parameters

% data_table = {'Test Condition' 'Gain' 'Offset' 'Preferred Direction' 'Bandwidth' 'Skew' 'R_square'
%     'No Pursuit'  gains(1) offsets(1) pref_dir(1) band(1) skew_fact(1) rsqr(1)
%     'Normal Pursuit (Left)' gains(5) offsets(5) pref_dir(5) band(5) skew_fact(5) rsqr(5)
%     'Simulated Pursuit (Left)' gains(6) offsets(6) pref_dir(6) band(6) skew_fact(6) rsqr(6)
%     'Stabilized Pursuit (Left)' gains(7) offsets(7) pref_dir(7) band(7) skew_fact(7) rsqr(7)
%     'Normal Pursuit (Right)' gains(2) offsets(2) pref_dir(2) band(2) skew_fact(2) rsqr(2)
%     'Simulated Pursuit (Right)' gains(3) offsets(3) pref_dir(3) band(3) skew_fact(3) rsqr(3)
%     'Stabilized Pursuit (Right)' gains(4) offsets(4) pref_dir(4) band(4) skew_fact(4) rsqr(4)
%     };

%%%%%%%%%%%%%%%%%%%% NOTE DATA IS REORGANIZED AGAIN HERE %%%%%%%%%%%%%%%%%%

data_table = {'Test Condition' 'Gain' 'Offset' 'Preferred Direction' 'Bandwidth' 'R_square'
              'No Pursuit'  gains(1) offsets(1) pref_dir(1) band(1) rsqr(1)
              'Normal Pursuit (Left)' gains(5) offsets(5) pref_dir(5) band(5) rsqr(5)
              'Simulated Pursuit (Left)' gains(6) offsets(6) pref_dir(6) band(6) rsqr(6)
              'Stabilized Pursuit (Left)' gains(7) offsets(7) pref_dir(7) band(7) rsqr(7)
              'Normal Pursuit (Right)' gains(2) offsets(2) pref_dir(2) band(2) rsqr(2)
              'Simulated Pursuit (Right)' gains(3) offsets(3) pref_dir(3) band(3) rsqr(3)
              'Stabilized Pursuit (Right)' gains(4) offsets(4) pref_dir(4) band(4) rsqr(4)
              };

if showtable==1
    %     digits = [6 6 6 6 6 6 6];  % Set number of decimal points displayed in table to 6
    digits = [6 6 6 6 6 6];  % Set number of decimal points displayed in table to 6
    
    % (table variable, title, header, no footer, set decimal points)
    stat_tab = statdisptable(data_table, 'Bighead Data Fitting',...
        'Circular Gaussian Parameters', '', digits);
    set(stat_tab,'Position',[5 100 800 180]);
end

% Make new directory for fitting and save outputs

if exist([path,'/bh_tests/',set_dir,'data_fits'],'dir')==0
    mkdir([path,'/bh_tests/',set_dir],'data_fits');
end

if ~plot_suppress
    hgsave(fitsfig,[path,'/bh_tests/',set_dir,'data_fits/fitted_tuning']);
end

save([path,'/bh_tests/',set_dir,'data_fits/data_table'],'data_table');
params = fit_params;  % [amp theta_pref sigma offset] in Hz and radians
save([path,'/bh_tests/',set_dir,'data_fits/params'],'params');
save([path,'/bh_tests/',set_dir,'data_fits/output_info'],'output_info');

end