function [] = bighead_response_plots(path,test_set,psth,tuning_map,num_eyes,headset)

% Plots trial-wise response dynamics and shows response changes between
% pursuit types (none, normal, stabilized, simulated)

viewing_opts = {'monoc','binoc'};

if test_set ~= 0 && ischar(test_set) == 0
    set_no = num2str(test_set);
    set_dir = ['set',set_no,'/'];
elseif test_set == 0
    set_dir = '';
elseif test_set == 'm'
    set_dir = ['set_merge_',viewing_opts{num_eyes},'/'];
end

% Load in Data
load([path,'/bh_tests/',set_dir,'bh_trials'])
load([path,'/bh_tests/',set_dir,'trial_data'])
load([path,'/bh_tests/',set_dir,'baseline_data'])   % Loading it in, but not really using it

azimuth_angles = unique(round(trial_data.trial_az,2));
elevation = trial_data.trial_el(1);
num_az = numel(azimuth_angles);
max_FR = round(trial_data.max_fr_psth,-1);

% Plot rasters/psth and tuning map
if psth == 1
    
    if exist([path,'/bh_tests/',set_dir,'/psth/'],'dir') == 0
        mkdir([path,'/bh_tests/',set_dir,'/psth/']);
    end
    
    r_space = round(max_FR*0.017); % set raster spacing
    raster_offset = max_FR;
    postrace_offset = 25;
    
    for X = 1:num_az   % Figures: 4 conditions for each base heading
        figaro = figure;
        set(gcf,'Position',[0 50 1800 800]);   % Define Figure Window Size for 1080i
        
        % No Pursuit condition
        
        % Get EV times & plot
%         trial_start = -200; %round(mean(bh_trials(7*(X-1)+1).ev_times(:,2)),-1);
%         trans_start = 0;
%         purs_eps = 400;
%         purs_start = 550;
%         trial_end = 1400;
        
        trial_start = round(min(bh_trials(7*(X-1)+2).ev_times(:,2)),-1);
        trans_start = 0;
        purs_eps = round(min(bh_trials(7*(X-1)+2).ev_times(:,5)),-1);
        purs_start = round(min(bh_trials(7*(X-1)+2).ev_times(:,6)),-1);
        trial_end = round(min(bh_trials(7*(X-1)+2).ev_times(:,7)),-1);
        
        [num_reps,~] = size(bh_trials(7*(X-1)+1).ev_times);
        
        subplot(2,4,1);hold on;
        plot([trans_start trans_start],[0 max_FR],'--r');    % Mark Translation start
        plot([purs_eps purs_eps],[0 max_FR],'--r');    % Mark Pursuit epsilon 
        plot([purs_start purs_start],[0 max_FR],'--r');    % Mark Pursuit initiation 
        
        % Plot PSTH
        bars = bar(bh_trials(7*(X-1)+1).psth_edges,bh_trials(7*(X-1)+1).psth_hist,...
            'k');
        bars.BarWidth = 1;
        
        ylimmax = max_FR + r_space*num_reps + postrace_offset*2;
        set(gca,'XLim',[trial_start,trial_end],...
                'YLim',[0,ylimmax],'Box','off',...
                'XTick',[trial_start trans_start purs_eps purs_start trial_end],...
                'YTick',0:max_FR/4:max_FR);
        xlabel('Time from Translation Start (ms)');
        ylabel('Firing Rate (sp/s)');
        
        title(['Az = ',num2str(bh_trials(7*(X-1)+1).head_az),...
            ', El = ',num2str(bh_trials(7*(X-1)+1).head_el)]);
        
        % Plot Rasters
        for a = 1:num_reps
            fg = raster_offset + r_space*a;
            t = bh_trials(7*(X-1)+1).spikes{a};
            %             t = bh_trials(7*(X-1)+1).desac_spikes(a,:);
            num_spks = length(t);
            
            subplot(2,4,1);hold on;
            scatter(t,fg.*ones(1,num_spks),5,'k','filled','Marker','s');
        end
        
        % Highlight epoch used for spike counts
        
%         if trial_end>1100
%             begin_window = trial_end-600;
%         else
%             begin_window = trial_end-400;
%         end
        
        begin_window = purs_start;
        
        fillmax = raster_offset + r_space*num_reps + 2*r_space;
        fillmin = raster_offset;
        xfill = [begin_window,trial_end,trial_end,begin_window];
        yfill = [fillmin,fillmin,fillmax,fillmax];
        fill(xfill,yfill,[0 0 0.8],'FaceAlpha',0.3,'EdgeAlpha',0.3);
        
        % Plot Horizontal Eye Position
        plot(bh_trials(7*(X-1)+1).pos_timing,...
            bh_trials(7*(X-1)+1).posx.*2.5 + ylimmax - postrace_offset,'k');
        
        for Y = 0:1     % Each subplot row is a single pursuit direction
            for Z = 1:3     % Each subplot column is a single pursuit condition
                
                switch trial_data.purs_type(7*(X-1)+Y+2*Z)
                    case 0
                        purs_type = 'Fixation';
                    case 1
                        purs_type = 'Normal Pursuit';
                    case 2
                        purs_type = 'Simulated Pursuit';
                    case 3
                        purs_type = 'Stabilized Pursuit';
                end
                
                if bh_trials(7*(X-1)+Y+2*Z).pur_dir == 0
                    purs_dir = 'Right';
                else
                    purs_dir = 'Left';
                end
                
                % Get EV times & plot                
                [num_reps,~] = size(bh_trials(7*(X-1)+Y+2*Z).ev_times);                
                
                subplot(2,4,Y*4+(Z+1));hold on;
                plot([trans_start trans_start],[0 max_FR],'--r');    % Mark Translation start
                plot([purs_eps purs_eps],[0 max_FR],'--r');    % Mark Pursuit prestart
                plot([purs_start purs_start],[0 max_FR],'--r');          % Mark Pursuit start
                
                % Plot PSTH
                bars = bar(bh_trials(7*(X-1)+Y+2*Z).psth_edges,...
                    bh_trials(7*(X-1)+Y+2*Z).psth_hist,'k');
                bars.BarWidth = 1;
                
                ylimmax = max_FR + r_space*num_reps + 50;
                
                set(gca,'XLim',[trial_start,trial_end],...
                    'YLim',[0,ylimmax],...
                    'Box','off',...
                    'XTick',[trial_start trans_start purs_eps purs_start trial_end],...
                    'YTick',0:max_FR/4:max_FR);
                title([purs_type,', ',purs_dir]);
                
                % Plot Rasters
                for a = 1:num_reps
                    fg = raster_offset + r_space*a;
                    t = bh_trials(7*(X-1)+Y+2*Z).spikes{a};
                    num_spks = length(t);
                    
                    subplot(2,4,Y*4+(Z+1));hold on;
                    scatter(t,fg.*ones(1,num_spks),5,'k','filled','Marker','s');
                end
                
                % Highlight epoch used for spike counts
                xfill = [begin_window,trial_end,trial_end,begin_window];
                yfill = [fillmin,fillmin,fillmax,fillmax];
                fill(xfill,yfill,[0 0 0.8],'FaceAlpha',0.3,'EdgeAlpha',0.3);
                
                % Plot Horizontal Eye Position
                plot(bh_trials(7*(X-1)+Y+2*Z).pos_timing,...
                     bh_trials(7*(X-1)+Y+2*Z).posx.*3.5 + ylimmax - postrace_offset,'k');
                
            end
        end
        
        hgsave(figaro,[path,'/bh_tests/',set_dir,'/psth/','az',num2str(bh_trials(7*(X-1)+Y+2*Z).head_az),'_el',num2str(bh_trials(7*(X-1)+Y+2*Z).head_el),'.fig']);
    end
end

if tuning_map == 1
    %%% Plot tuning curves with connected means/STD
    FR_plot = trial_data.fr_plot_HP;
    %     FR_plot = trial_data.fr_plot_desac;
    std_plot = trial_data.std_plot_HP;
    %     std_plot = trial_data.std_plot_desac;
    
    dir = {' Right',' Left'};
    colors = {'k','b','r'};
    x_axis = azimuth_angles;
    x_max = max(x_axis);
    x_min = min(x_axis);
    y_max = max(max(FR_plot))+max(max(std_plot));
    
    tunfig = figure;hold on;
    set(gcf,'Position',[50 50 1800 900]);   % Define Figure Window Size for 1080i
    for S = 0:1   % Loop over pursuit direction (0:right/0deg, 1:left/180deg)
        for offset = 1:3  % Loop over pursuit type
            subplot(1,2,2-S);hold on;
            stdshade(FR_plot(2*offset+S,:),std_plot(2*offset+S,:),0.15,colors{offset},x_axis);
        end
        stdshade(FR_plot(1,:),std_plot(1,:),0.15,'g',x_axis); % Heading only trials
        
        set(gca,'XTick',x_axis,'XLim',[x_min,x_max],'YLim',[0,y_max],'Box','off','FontSize',20);
        s = sprintf(char(176));
        xlabel(['Heading Direction (',s,' Azimuth)'],'FontSize',20);
        ylabel('Firing Rate (Hz)','FontSize',20);
        title(strcat('Pursuit  ',dir(S+1)));  %left or right
    end
    
    % Create legend [(distance from left) (distance from bottom) (width) (height)]
    annotation(tunfig,'textbox',[0.15 0.30 0.15 0.0465],'Color',[0 1 0],...
        'String',' - No Pursuit','FontSize',18,'FitBoxToText','off','EdgeColor',[1 1 1]);
    annotation(tunfig,'textbox',[0.15 0.25 0.15 0.0465],'Color',[0 0 0],...
        'String',' - Normal Pursuit','FontSize',18,'FitBoxToText','off','EdgeColor',[1 1 1]);
    annotation(tunfig,'textbox',[0.15 0.20 0.15 0.0465],'Color',[0 0 1],...
        'String',' - Simulated Pursuit','FontSize',18,'FitBoxToText','off','EdgeColor',[1 1 1]);
    annotation(tunfig,'textbox',[0.15 0.15 0.15 0.0465],'Color',[1 0 0],...
        'String',' - Stabilized Pursuit','FontSize',18,'FitBoxToText','off','EdgeColor',[1 1 1]);
    
    hgsave(tunfig,strcat(path,'/bh_tests/',set_dir,'tuning_maps')); % save only the H+P plot
    
    %%% Plot sampling range on tuning (manually set if headset ~= 0 )
    if headset ~= 0
        test_range = open([path,'/heading_tuning/set',num2str(headset),'/tuning_map.fig']);
    else
        test_range = open([path,'/heading_tuning/tuning_map.fig']);
    end
    
    azimuth_angles_adj = zeros(1,num_az);
    numpos = 0;
    numneg = 0;
    
    % Shift polar axis to -180:180
    for T = 1:num_az
        if azimuth_angles(T) <= 180
            azimuth_angles_adj(T) = azimuth_angles(T);
            numpos = numpos + 1;
        elseif azimuth_angles(T) > 180
            azimuth_angles_adj(T) = azimuth_angles(T) - 360;
            numneg = numneg + 1;
        end
    end
    
    if numpos ~= 0 && numneg ~= 0
        if azimuth_angles_adj(1) < 0    % For 0 crossings
            plot([azimuth_angles_adj(1) azimuth_angles_adj(end)],[elevation elevation],...
                'Color',[1 1 1],'LineWidth',4);
        else                            % For 180 crossings
            plot([azimuth_angles_adj(1) 180],[elevation elevation],...
                'Color',[1 1 1],'LineWidth',4);
            plot([-180 azimuth_angles_adj(end)],[elevation elevation],...
                'Color',[1 1 1],'LineWidth',4);
        end
    elseif numpos == 0 && numneg ~= 0
        plot([azimuth_angles_adj(1) azimuth_angles_adj(end)],[elevation elevation],...
            'Color',[1 1 1],'LineWidth',4);
    elseif numpos ~= 0 && numneg == 0
        plot([azimuth_angles_adj(1) azimuth_angles_adj(end)],[elevation elevation],...
            'Color',[1 1 1],'LineWidth',4);
    end
    
    hgsave(test_range,[path,'/bh_tests/',set_dir,'test_range']);
end

end
