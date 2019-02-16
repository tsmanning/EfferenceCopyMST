function []=heading_response_plots(path,test_set,psth,tuning_map)

% Plots all spike density plots for all trial conditions as well as 2D
% heading map

if test_set~=0
    set_no=num2str(test_set);
    set_dir=['set',set_no,'/'];
else
    set_dir='';
end

% Load in Data
load(strcat(path,'/heading_tuning/',set_dir,'head_trials'))
load(strcat(path,'/heading_tuning/',set_dir,'trial_data'))

max_FR = trial_data.maxFR;
r_space = round(max_FR*0.017);
trial_end = round(mean(head_trials(1).ev_times(:,end)),-1); % find mean end time, round to nearest tens

if psth
    % Plot heading-wise PSTH and rasters
    
    % Plot -45:45 elevation directions
    elevations={'45','0','-45'};
    for els=1:3
        horfig=figure;
        headinds = [2 3 4 5 6 7 8 9;
            10 11 12 13 14 15 16 17;
            18 19 20 21 22 23 24 25];
        
        for azs=1:8
            subplot(1,8,azs);hold on;
            
            % Plot PSTH
            bars = bar(head_trials(headinds(els,azs)).psth_edges,head_trials(headinds(els,azs)).psth_hist,'k');
            bars.BarWidth = 1;
            
            % Plot rasters
            num_reps = size(head_trials(headinds(els,azs)).spikes,1);
            
            for Y = 1:num_reps
                fg = max_FR + r_space*Y;
                t = head_trials(headinds(els,azs)).spikes{Y};   % Spikes container changed to cell array, need to rerun heading_response_1/2 for older trials
                num_spks = length(t);
                
                subplot(1,8,azs);
                hold on;
                scatter(t,fg.*ones(1,num_spks),3,'k','filled','Marker','s');
            end
            
            plot([0 0],[0 max_FR],'--r');
            set(gca,'XLim',[-230,trial_end],'YLim',[0,max_FR+r_space*num_reps+2],'Box','off');
            set(gcf,'Position',[0 1050-330*els 1800 225]);
            title([num2str(head_trials(headinds(els,azs)).head_el),' , ',num2str(head_trials(headinds(els,azs)).head_az)]);
        end
        
        % Save Plot
        hgsave(horfig,[path,'/heading_tuning/',set_dir,'tuning_dynamics_el',elevations{els},'.fig']);
    end
    
    % Plot -90 & 90 elevation directions
    vertfig = figure;
    dir = [1 26];
    for verts = 1:2
        subplot(1,2,verts);hold on;
        
        % Plot PSTH
        bars = bar(head_trials(dir(verts)).psth_edges,...
            head_trials(dir(verts)).psth_hist,'k');
        bars.BarWidth = 1;
        
        % Plot rasters
        [num_reps,~] = size(head_trials(dir(verts)).spikes);   % Find number of trial reps
        
        for Y = 1:num_reps
            fg = max_FR + r_space*Y;
            t = head_trials(dir(verts)).spikes{Y};
            num_spks = length(t);
            
            subplot(1,2,verts);
            hold on;
            scatter(t,fg.*ones(1,num_spks),3,'k','filled','Marker','s');
        end
        
        plot([0 0],[0 max_FR],'--r');
        set(gca,'XLim',[-230,trial_end],'YLim',[0,max_FR+r_space*num_reps+2],'Box','off');
        set(gcf,'Position',[0 350 400 225]);
        title([num2str(head_trials(dir(verts)).head_el),' , ',num2str(head_trials(dir(verts)).head_az)]);
    end
    
    % Save Plot
    hgsave(vertfig,strcat(path,'/heading_tuning/',set_dir,'tuning_dynamics_vert'));
end

if tuning_map
    % Plot 2D tuning with equirectangular projection
    equirectangular_map([path,'/heading_tuning/',set_dir,'head_trials']);
    
    % Save Plot
    hgsave(gcf,strcat(path,'/heading_tuning/',set_dir,'tuning_map'));
end

end