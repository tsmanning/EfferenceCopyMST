function []=pursuit_response_plots(path,test_set,dynamics,tuning_map,polar)

% Plots pursuit position and velocity traces aligned with response
% dynamics; plots pursuit direction tuning in cartesian coordinates

if test_set~=0
    set_no=num2str(test_set);
    set_dir=['set',set_no,'/'];
else
    set_dir='';
end

% Load in Data
load(strcat(path,'/pursuit_tuning/',set_dir,'purs_trials'))
load(strcat(path,'/pursuit_tuning/',set_dir,'trial_data'))
load(strcat(path,'/pursuit_tuning/',set_dir,'baseline_data'))

purs_dirs       = trial_data.trial_dir;
num_trial_types = trial_data.num_trials;
std_plot        = trial_data.std_plot;
FR_plot         = trial_data.FR_plot;
std_plot_blink  = trial_data.std_plot_blink;
FR_plot_blink   = trial_data.FR_plot_blink;
mean_bl_fr      = baseline_data.firing_rate;

max_FR = trial_data.max_fr;

% Plot position, velocity, rasters, and PSTH plots
if dynamics
    for M=1:num_trial_types
        trial_start=mean(purs_trials(M).ev_times(:,3));
        purs_pre=mean(purs_trials(M).ev_times(:,4));
        purs_start=0;
        blink_start=mean(purs_trials(M).ev_times(:,6));
        blink_end=mean(purs_trials(M).ev_times(:,7));
        trial_end=mean(purs_trials(M).ev_times(:,8));
        
        [num_reps,~]=size(purs_trials(M).ev_times);
        
        for N=1:num_reps
            figaro=figure(M);
            
            % Plot x-position
            subplot(4,1,1);hold on;
            plot(purs_trials(M).pos_timing(N,1:purs_trials(M).pos_length(N)),...
                purs_trials(M).posx(N,1:purs_trials(M).pos_length(N)),'k');
            set(gca,'XLim',[trial_start,trial_end],'YLim',[-10,10],'Box','off','FontSize',15);
            plot([purs_pre purs_pre],[-10 30],'--r');   % Mark pursuit pre-start
            plot([purs_start purs_start],[-10 30],'--k');   % Mark pursuit start
            plot([blink_start blink_start],[-10 30],'--r');     % Mark blink start
            plot([blink_end blink_end],[-10 30],'--r');     % Mark blink end
            
            % Plot y-position
            subplot(4,1,2);hold on;
            plot(purs_trials(M).pos_timing(N,1:purs_trials(M).pos_length(N)),...
                purs_trials(M).posy(N,1:purs_trials(M).pos_length(N)),'k');
            set(gca,'XLim',[trial_start,trial_end],'YLim',[-10,10],'Box','off','FontSize',15);
            plot([purs_pre purs_pre],[-10 30],'--r');   % Mark pursuit pre-start
            plot([purs_start purs_start],[-10 30],'--k');   % Mark pursuit start
            plot([blink_start blink_start],[-10 30],'--r');     % Mark blink start
            plot([blink_end blink_end],[-10 30],'--r');     % Mark blink end
            
            % Plot velocity
            subplot(4,1,3);hold on;
            plot(purs_trials(M).vel_timing(N,1:purs_trials(M).vel_length(N)),...
                1000*purs_trials(M).vel(N,1:purs_trials(M).vel_length(N)),'k');
            set(gca,'XLim',[trial_start,trial_end],'YLim',[-5,30],'Box','off','FontSize',15);
            plot([purs_pre purs_pre],[-5 30],'--r');   % Mark pursuit pre-start
            plot([purs_start purs_start],[-5 30],'--k');   % Mark pursuit start
            plot([blink_start blink_start],[-5 30],'--r');     % Mark blink start
            plot([blink_end blink_end],[-5 30],'--r');     % Mark blink end
        end
        subplot(4,1,1);
        ylabel('Eye Position X (deg)','FontSize',15);
        title(['/theta=',num2str(purs_trials(M).pur_dir)],'FontSize',15);
        subplot(4,1,2);
        ylabel('Eye Position Y (deg)','FontSize',15);
        subplot(4,1,3);
        ylabel('Eye Velocity (deg/s)','FontSize',15);
        
        % Plot rasters & PSTH
        for o = 1:num_reps
            fg = max_FR + 4*o;
            t = purs_trials(M).spikes{o};
            num_spks = length(t);
            
            subplot(4,1,4);
            hold on;
            scatter(t,fg.*ones(1,num_spks),5,'k','filled','Marker','s');
        end
        subplot(4,1,4);
        bar(purs_trials(M).psth_edges,purs_trials(M).psth_hist,'histc','k');
        
        
        plot([purs_pre purs_pre],[0 max_FR+(4*num_reps)],'--r');   % Mark pursuit pre-start
        plot([purs_start purs_start],[0 max_FR+(4*num_reps)],'--k');   % Mark pursuit start
        plot([blink_start blink_start],[0 max_FR+(4*num_reps)],'--r');     % Mark blink start
        plot([blink_end blink_end],[0 max_FR+(4*num_reps)],'--r');     % Mark blink end
        set(gca,'XLim',[trial_start,trial_end],'YLim',[0,max_FR+(4*num_reps)+4],'Box','off','FontSize',15);
        xlabel('Time (ms)','FontSize',15);
        ylabel('Firing Rate (Hz)','FontSize',15);
        set(gcf,'Position',[50 50 750 950]);
        
        hgsave(figaro,strcat(path,'/pursuit_tuning/',set_dir,num2str(purs_trials(M).pur_dir),'deg'));
    end
end

if tuning_map==1
    if polar==0
        scaling_factor=max(FR_plot_blink)+max(std_plot_blink);
        scaling_factor=round(scaling_factor*1.1);
        
        fig = figure;
        hold on;
        set(gcf,'Position',[50 50 1130 930]);   % Define Figure Window Size for 1080i
        stdshade(FR_plot,std_plot,0.3,'r',purs_dirs);
        stdshade(FR_plot_blink,std_plot_blink,0.2,'b',purs_dirs);
        plot([0 315],[mean_bl_fr mean_bl_fr],'--k');                  % Plot baseline
        set(gca,'XTick',0:45:315,'XLim',[0,315],'YLim',[0,scaling_factor],'Box','off','FontSize',15);
        xlabel('Pursuit Direction (deg)','FontSize',15);ylabel('Firing Rate (Hz)','FontSize',15);
        
        % Create legend [(distance from left) (distance from bottom) (width) (height)]
        annotation(fig,'textbox',[0.55 0.776 0.35 0.0465],'Color',[0 0 1],...
            'String',' - Pursuit Tuning (Blink Period)','FontSize',18,'FitBoxToText','off','EdgeColor',[1 1 1]);
        annotation(fig,'textbox',[0.55 0.84 0.35 0.0465],'Color',[1 0 0],...
            'String',' - Pursuit Tuning (Whole Trial)','FontSize',18,'FitBoxToText','off','EdgeColor',[1 1 1]);
        
        hgsave(fig,strcat(path,'/pursuit_tuning/',set_dir,'tuning_map'));
    elseif polar==1
        fig = figure;
        pursuit_polar(trial_data);
        
        hgsave(fig,strcat(path,'/pursuit_tuning/',set_dir,'tuning_map_polar'));
    end
end

end