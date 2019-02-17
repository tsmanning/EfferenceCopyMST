function [] = group_stats(path,gain,offset,band,tuncent,savesuppress)

% Checks for significant differences between parameters calculated for each
% bighead condition

% Usage: [] = group_stats(poppath,gain,offset,band,tuncent,savesuppress)

% Load in data and setup vars
monoculo = 0;
binoculo = 0;
combined = 0;
manturnoff = 1;
monobinoon = 1;

if exist([path,'monoc.mat'],'file') ~= 0
    load([path,'monoc'],'monoc')
    
    monoculo = 1;
end

if exist([path,'binoc.mat'],'file') ~= 0
    load([path,'binoc'],'binoc')
    load([path,'monobino'],'monobino')
    
    binoculo = 1;
end

if exist([path,'comb.mat'],'file') ~= 0
    load([path,'comb'],'comb')
    
    combined = 1;
end

% Run stats on gain parameters
if gain
    if exist([path,'pop_tuning_gain'],'dir')==0
        mkdir([path,'pop_tuning_gain']);
    end
    
    if monoculo && manturnoff
        % Monoc
        stat_data_monoc = monoc;
        [norm_fix_gain,sim_fix_gain,stab_fix_gain] = ...
            gainstatplot(stat_data_monoc,[],'Monocular',1,0);
        
        if ~savesuppress
            hgsave(norm_fix_gain,[path,'pop_tuning_gain/normvfix_gain_monoc']);
            hgsave(sim_fix_gain,[path,'pop_tuning_gain/simvfix_gain_monoc']);
            hgsave(stab_fix_gain,[path,'pop_tuning_gain/stabvfix_gain_monoc']);
        end
    end
    
    if binoculo && manturnoff
        % Binoc
        stat_data_binoc = binoc;
        [norm_fix_gain,sim_fix_gain,stab_fix_gain] = ...
            gainstatplot(stat_data_binoc,[],'Binocular',1,0);
        
        if ~savesuppress
            hgsave(norm_fix_gain,[path,'pop_tuning_gain/normvfix_gain_binoc']);
            hgsave(sim_fix_gain,[path,'pop_tuning_gain/simvfix_gain_binoc']);
            hgsave(stab_fix_gain,[path,'pop_tuning_gain/stabvfix_gain_binoc']);
        end
    end
    
    if combined && manturnoff
        % Combined
        stat_data_comb = comb;
        [norm_fix_gain,sim_fix_gain,stab_fix_gain] = ...
            gainstatplot(stat_data_comb,[],'Combined Monocular/Binocular',1,0);
        
        if ~savesuppress
            hgsave(norm_fix_gain,[path,'pop_tuning_gain/normvfix_gain_comb']);
            hgsave(sim_fix_gain,[path,'pop_tuning_gain/simvfix_gain_comb']);
            hgsave(stab_fix_gain,[path,'pop_tuning_gain/stabvfix_gain_comb']);
        end
    end
    
    if monoculo && binoculo && monobinoon
        % Minoc vs Binoc
        [normvfix,simvfix,stabvfix] = ...
            monobinocomp(monobino.bin_gain_mat,monobino.mon_gain_mat,'Response Amplitude');
        
        if ~savesuppress
            hgsave(normvfix,[path,'pop_tuning_gain/normvfix_viewcomp']);
            hgsave(simvfix,[path,'pop_tuning_gain/simvfix_viewcomp']);
            hgsave(stabvfix,[path,'pop_tuning_gain/stabvfix_viewcomp']);
        end
    end
end

% Run stats on offset parameters
if offset
    if exist([path,'pop_tuning_offset'],'dir')==0
        mkdir([path,'pop_tuning_offset']);
    end
    
    if monoculo && manturnoff
        % Monocular
        stat_data_monoc = monoc;
        [norm_fix_offset,sim_fix_offset,stab_fix_offset] = ...
            offsetstatplot(stat_data_monoc,[],'Monocular',1,0);
        
        if ~savesuppress
            hgsave(norm_fix_offset,[path,'pop_tuning_offset/normvfix_offset_monoc']);
            hgsave(sim_fix_offset,[path,'pop_tuning_offset/simvfix_offset_monoc']);
            hgsave(stab_fix_offset,[path,'pop_tuning_offset/stabvfix_offset_monoc']);
        end
    end
    
    if binoculo && manturnoff
        % Binocular
        stat_data_binoc = binoc;
        [norm_fix_offset,sim_fix_offset,stab_fix_offset] = ...
            offsetstatplot(stat_data_binoc,[],'Binocular',1,0);
        
        if ~savesuppress
            hgsave(norm_fix_offset,[path,'pop_tuning_offset/normvfix_offset_binoc']);
            hgsave(sim_fix_offset,[path,'pop_tuning_offset/simvfix_offset_binoc']);
            hgsave(stab_fix_offset,[path,'pop_tuning_offset/stabvfix_offset_binoc']);
        end
    end
    
    if combined && manturnoff
        % Combined
        stat_data_comb = comb;
        [norm_fix_offset,sim_fix_offset,stab_fix_offset] = ...
            offsetstatplot(stat_data_comb,[],'Combined Monocular/Binocular',1,0);
        
        if ~savesuppress
            hgsave(norm_fix_offset,[path,'pop_tuning_offset/normvfix_offset_comb']);
            hgsave(sim_fix_offset,[path,'pop_tuning_offset/simvfix_offset_comb']);
            hgsave(stab_fix_offset,[path,'pop_tuning_offset/stabvfix_offset_comb']);
        end
    end
end

% Run stats on band parameters
if band
    % Setup directory to which data will be saved
    if exist([path,'pop_tuning_band'],'dir')==0
        mkdir([path,'pop_tuning_band']);
    end
    
    if monoculo && manturnoff
        % Combined
        stat_data_monoc = monoc;
        [norm_fix_band,sim_fix_band,stab_fix_band] = ...
            bandstatplot(stat_data_monoc,[],'Monocular',1,0);
        
        if ~savesuppress
            hgsave(norm_fix_band,[path,'pop_tuning_band/normvfix_band_monoc']);
            hgsave(sim_fix_band,[path,'pop_tuning_band/simvfix_band_monoc']);
            hgsave(stab_fix_band,[path,'pop_tuning_band/stabvfix_band_monoc']);
        end
    end
    
    if binoculo && manturnoff
        % Combined
        stat_data_binoc = binoc;
        [norm_fix_band,sim_fix_band,stab_fix_band] = ...
            bandstatplot(stat_data_binoc,[],'Binocular',1,0);
        
        if ~savesuppress
            hgsave(norm_fix_band,[path,'pop_tuning_band/normvfix_band_binoc']);
            hgsave(sim_fix_band,[path,'pop_tuning_band/simvfix_band_binoc']);
            hgsave(stab_fix_band,[path,'pop_tuning_band/stabvfix_band_binoc']);
        end
    end
    
    if combined && manturnoff
        % Combined
        stat_data_comb = comb;
        [norm_fix_band,sim_fix_band,stab_fix_band] = ...
            bandstatplot(stat_data_comb,[],'Combined Monocular/Binocular',1,0);
        
        if ~savesuppress
            hgsave(norm_fix_band,[path,'pop_tuning_band/normvfix_band_comb']);
            hgsave(sim_fix_band,[path,'pop_tuning_band/simvfix_band_comb']);
            hgsave(stab_fix_band,[path,'pop_tuning_band/stabvfix_band_comb']);
        end
    end
end

% Run stats on tuning center parameters
if tuncent
    % Setup directory to which data will be saved
    if exist([path,'pop_tuning_center'],'dir')==0
        mkdir([path,'pop_tuning_center']);
    end
    
    if monoculo && manturnoff
        % Monoc
        stat_data_monoc = monoc;
        [normvfix,simvfix,stabvfix] = ...
            tcstatplot(stat_data_monoc,[],'Monocular',1,0,[]);
        
        if ~savesuppress
            hgsave(normvfix,[path,'pop_tuning_center/normvfix_monoc']);
            hgsave(simvfix,[path,'pop_tuning_center/simvfix_monoc']);
            hgsave(stabvfix,[path,'pop_tuning_center/stabvfix_monoc']);
        end
    end
    
    if binoculo && manturnoff
        % Binoc
        stat_data_binoc = binoc;
        [normvfix,simvfix,stabvfix] = ...
            tcstatplot(stat_data_binoc,[],'Binocular',1,0,[]);
        
        if ~savesuppress
            hgsave(normvfix,[path,'pop_tuning_center/normvfix_binoc']);
            hgsave(simvfix,[path,'pop_tuning_center/simvfix_binoc']);
            hgsave(stabvfix,[path,'pop_tuning_center/stabvfix_binoc']);
        end
    end
    
    if combined && manturnoff
        % Combined
        stat_data_comb = comb;
        [normvfix,simvfix,stabvfix] = ...
            tcstatplot(stat_data_comb,[],'Combined Monocular/Binocular',1,0,[]);
        
        if ~savesuppress
            hgsave(normvfix,[path,'pop_tuning_center/normvfix_comb']);
            hgsave(simvfix,[path,'pop_tuning_center/simvfix_comb']);
            hgsave(stabvfix,[path,'pop_tuning_center/stabvfix_comb']);
        end
    end
    
    if monoculo && binoculo && monobinoon
        % Minoc vs Binoc
        [normvfix,simvfix,stabvfix] = ...
            monobinocomp(monobino.bin_tuncent_mat,monobino.mon_tuncent_mat,'Preferred Heading');
        
        if ~savesuppress
            hgsave(normvfix,[path,'pop_tuning_center/normvfix_viewcomp']);
            hgsave(simvfix,[path,'pop_tuning_center/simvfix_viewcomp']);
            hgsave(stabvfix,[path,'pop_tuning_center/stabvfix_viewcomp']);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Offset stats
%     function [norm_fix_offset,sim_fix_offset,stab_fix_offset] = offsetstatplot(data,titlestr)
%         % Analyze offset changes during pursuit
%         
%         % Set up params
%         offmat = data.offset_mat;
%         c = -data.lr_index;
%         numcells = size(offmat,1);
%         
%         normmap = [linspace(0,0.75,10)' linspace(0,0.75,10)' linspace(0,0.75,10)'];
%         simmap = [zeros(10,1) zeros(10,1) linspace(0,1,10)'];
%         stabmap = [linspace(0,1,10)' zeros(10,1) zeros(10,1)];
%         
%         colormaps = {normmap,simmap,stabmap};
%         cond_colors = {[0.5 0.5 0.5],[0 0 0.75],[0.75 0 0]};
%         
%         fix_med = median(offmat(:,1),'omitnan');
%         
%         l_inds = [2 3 4];   % norm, sim, stab
%         r_inds = [5 6 7];
%         
%         names = {'Normal','Simulated','Stabilized'};
%         
%         % Plot results
%         
%         for i = 1:3
%             % Run sign-rank tests
%             p_cond = signrank([offmat(:,1);offmat(:,1)],[offmat(:,l_inds(i));offmat(:,r_inds(i))]);
%             p_cond = round(p_cond,4);
%             cond_med = median([offmat(:,l_inds(i));offmat(:,r_inds(i))],'omitnan');
%             cond_med = round(cond_med,4);
%             cond_max = max([offmat(:,l_inds(i));offmat(:,r_inds(i))],[],'omitnan');
%             max_fix = max(offmat(:,1));
%             
%             h(i) = figure;
%             set(gcf,'Position',[25 500 1350 500]);
%             subplot(1,2,1); hold on;
%             scatter(offmat(:,1),offmat(:,l_inds(i)),100,c,'filled','Marker','square');
%             scatter(offmat(:,1),offmat(:,r_inds(i)),100,c,'filled');
%             plot([0 max_fix*1.01],[0 cond_max*1.01],'--k');  % fix to max shift
%             set(gca,'XLim',[0,max_fix*1.01],'YLim',[0,cond_max*1.01],'FontSize',20);
%             xlabel('Offset (Fixation)','FontSize',20);
%             ylabel(['Offset (',names{i},' Pursuit)'],'FontSize',20);
%             title([titlestr,', n=',num2str(numcells)]);
%             colormap(gcf,colormaps{i});
%             cbar1 = colorbar;
%             cbar1.Label.String = 'Left-Right PTI';
%             annotation(gcf,'textbox',[0.15 0.48 0.15 0.3],'Color',[0 0 0],...
%                 'String',['p=',num2str(p_cond)],'FontSize',18,'FitBoxToText','off','LineStyle','none');
%             
%             subplot(1,2,2); hold on;
%             h1 = histogram([offmat(:,l_inds(i))-offmat(:,1);offmat(:,r_inds(i))-offmat(:,1)],...
%                 'BinWidth',5,'FaceColor',cond_colors{i});
%             h2 = histogram(offmat(:,l_inds(i))-offmat(:,1),'BinWidth',5,'FaceColor',cond_colors{i}*0.5);
%             h1.FaceAlpha = 1;
%             h2.FaceAlpha = 1;
%             maxshift = max(abs([h1.Data;h2.Data]),[],'omitnan');
%             ymaxlim = 2*floor(max(h1.Values)/2)+4;  % Set Max y value as a multiple of two
%             ylabel('Number of Occurrences','FontSize',20);
%             xlabel('Offset Difference (spks/s)','FontSize',20);
%             title([names{i},' Pursuit vs. Fixation']);
%             max_data = max([h1.Values]) + 3;
%             set(gca,'YTick',0:4:ymaxlim,'YMinorTick','On','YLim',[0 max_data],'FontSize',20);
%             set(gca,'XLim',[-maxshift*1.15,maxshift*1.15],'FontSize',20);
%             
%             plot([0 0],[0 max_data],'--k');
%             
%             text(cond_med,max_data-1.5,[' Med = ',num2str(cond_med)],'Color',cond_colors{i},...
%                 'FontSize',15);
%             plot([cond_med cond_med],[max_data-2.5 max_data-1],'Color',cond_colors{i},...
%                 'LineWidth',3);
%             
%             sqrsym = char(9632);
%             circsym = char(9679);
%             annotation(gcf,'textbox',[0.6 0.6 0.15 0.3],'Color',cond_colors{i}*0.5,...
%                 'String','Left Pursuit','FontSize',18,'FitBoxToText','off','LineStyle','none');
%             annotation(gcf,'textbox',[0.6 0.55 0.15 0.3],'Color',cond_colors{i},...
%                 'String','Right Pursuit','FontSize',18,'FitBoxToText','off','LineStyle','none');
%             annotation(gcf,'textbox',[0.14 0.6 0.15 0.3],'Color',[0 0 0],...
%                 'String',[sqrsym,' Left Pursuit'],'FontSize',18,'FitBoxToText','off','LineStyle','none');
%             annotation(gcf,'textbox',[0.14 0.55 0.15 0.3],'Color',[0 0 0],...
%                 'String',[circsym,' Right Pursuit'],'FontSize',18,'FitBoxToText','off','LineStyle','none');
%         end
%         
%         norm_fix_offset = h(1);
%         sim_fix_offset = h(2);
%         stab_fix_offset = h(3);
%     end
% 
% % Amplitude stats
%     function [norm_fix_gain,sim_fix_gain,stab_fix_gain] = gainstatplot(data,titlestr)
%         % Analyze gain changes during pursuit
%         
%         % Set up params
%         gmat = data.gain_mat;
%         c = -data.lr_index;
%         numcells = size(gmat,1);
%         
%         normmap = [linspace(0,0.75,10)' linspace(0,0.75,10)' linspace(0,0.75,10)'];
%         simmap = [zeros(10,1) zeros(10,1) linspace(0,1,10)'];
%         stabmap = [linspace(0,1,10)' zeros(10,1) zeros(10,1)];
%         
%         colormaps = {normmap,simmap,stabmap};
%         cond_colors = {[0.5 0.5 0.5],[0 0 0.75],[0.75 0 0]};
%         
%         fix_med = median(gmat(:,1),'omitnan');
%         
%         l_inds = [2 3 4];   % norm, sim, stab
%         r_inds = [5 6 7];
%         
%         names = {'Normal','Simulated','Stabilized'};
%         
%         % Plot results
%         
%         for i = 1:3
%             % Run sign-rank tests
%             p_cond = signrank([gmat(:,1);gmat(:,1)],[gmat(:,l_inds(i));gmat(:,r_inds(i))]);
%             p_cond = round(p_cond,4);
%             cond_med = median([gmat(:,l_inds(i))-gmat(:,1);gmat(:,r_inds(i))-gmat(:,1)],'omitnan');
%             cond_med = round(cond_med,4);
%             cond_max = max([gmat(:,l_inds(i));gmat(:,r_inds(i))],[],'omitnan');
%             max_fix = max(gmat(:,1));
%             
%             f(i) = figure;
%             set(gcf,'Position',[25 500 1550 600]);
%             subplot(1,2,1); hold on;
%             scatter(gmat(:,1),gmat(:,l_inds(i)),100,c,'filled','Marker','square');
%             scatter(gmat(:,1),gmat(:,r_inds(i)),100,c,'filled');
%             plot([0 max_fix*1.01],[0 cond_max*1.01],'--k');  % fix to max shift
%             set(gca,'XLim',[0,max_fix*1.01],'YLim',[0,cond_max*1.01],'FontSize',20);
%             xlabel('Amplitude (Fixation)','FontSize',20);
%             ylabel(['Amplitude (',names{i},' Pursuit)'],'FontSize',20);
%             title([titlestr,', n=',num2str(numcells)]);
%             colormap(gcf,colormaps{i});
%             cbar1 = colorbar;
%             cbar1.Label.String = 'Left-Right PTI';
%             annotation(gcf,'textbox',[0.15 0.48 0.15 0.3],'Color',[0 0 0],...
%                 'String',['p=',num2str(p_cond)],'FontSize',18,'FitBoxToText','off','LineStyle','none');
%             
%             subplot(1,2,2); hold on;
%             h = histogram([gmat(:,l_inds(i))-gmat(:,1);gmat(:,r_inds(i))-gmat(:,1)],'BinWidth',5,'FaceColor',cond_colors{i});
%             h2 = histogram(gmat(:,l_inds(i))-gmat(:,1),'BinWidth',5,'FaceColor',cond_colors{i}*0.5);
%             h.FaceAlpha = 0.6;
%             h2.FaceAlpha = 0.6;
%             maxshift = max(abs([h.Data;h2.Data]),[],'omitnan');
%             ymaxlim = 2*floor(max(h.Values)/2)+4;
%             ylabel('Number of Occurrences','FontSize',20);
%             xlabel('Amplitude Difference (sp/s)','FontSize',20);
%             title([names{i},' Pursuit vs. Fixation']);
%             max_data = max([h.Values]) + 3;
%             set(gca,'YTick',0:2:ymaxlim,'YMinorTick','On','YLim',[0 max_data],'FontSize',20);
%             set(gca,'XLim',[-maxshift*1.15,maxshift*1.15],'FontSize',20);
%             
%             plot([0 0],[0 max_data],'--k');
%             text(cond_med,max_data-1.5,[' Med = ',num2str(cond_med)],'Color',cond_colors{i},...
%                 'FontSize',15);
%             plot([cond_med cond_med],[max_data-2.5 max_data-1],'Color',cond_colors{i},...
%                 'LineWidth',3);
%             
%             sqrsym = char(9632);
%             circsym = char(9679);
%             annotation(gcf,'textbox',[0.6 0.6 0.15 0.3],'Color',cond_colors{i}*0.5,...
%                 'String','Left Pursuit','FontSize',18,'FitBoxToText','off','LineStyle','none');
%             annotation(gcf,'textbox',[0.6 0.55 0.15 0.3],'Color',cond_colors{i},...
%                 'String','Right Pursuit','FontSize',18,'FitBoxToText','off','LineStyle','none');
%             annotation(gcf,'textbox',[0.14 0.6 0.15 0.3],'Color',[0 0 0],...
%                 'String',[sqrsym,' Left Pursuit'],'FontSize',18,'FitBoxToText','off','LineStyle','none');
%             annotation(gcf,'textbox',[0.14 0.55 0.15 0.3],'Color',[0 0 0],...
%                 'String',[circsym,' Right Pursuit'],'FontSize',18,'FitBoxToText','off','LineStyle','none');
%         end
%         
%         norm_fix_gain = f(1);
%         sim_fix_gain = f(2);
%         stab_fix_gain = f(3);
%     end
% 
% % Band stats
%     function [norm_fix_band,sim_fix_band,stab_fix_band] = bandstatplot(data,titlestr)
%         % Analyze gain changes during pursuit
%         
%         % Set up params
%         bmat = data.band_mat;
%         c = -data.lr_index;
%         numcells = size(bmat,1);
%         
%         normmap = [linspace(0,0.75,10)' linspace(0,0.75,10)' linspace(0,0.75,10)'];
%         simmap = [zeros(10,1) zeros(10,1) linspace(0,1,10)'];
%         stabmap = [linspace(0,1,10)' zeros(10,1) zeros(10,1)];
%         
%         colormaps = {normmap,simmap,stabmap};
%         cond_colors = {[0.5 0.5 0.5],[0 0 0.75],[0.75 0 0]};
%         
%         fix_med = median(bmat(:,1),'omitnan');
%         
%         l_inds = [2 3 4];   % norm, sim, stab
%         r_inds = [5 6 7];
%         
%         names = {'Normal','Simulated','Stabilized'};
%         deg_symbol = sprintf(char(176));
%         
%         % Plot results
%         
%         for i = 1:3
%             % Run sign-rank tests
%             p_cond = signrank([bmat(:,1);bmat(:,1)],[bmat(:,l_inds(i));bmat(:,r_inds(i))]);
%             cond_med = median([bmat(:,l_inds(i));bmat(:,r_inds(i))],'omitnan');
%             cond_max = max([bmat(:,l_inds(i));bmat(:,r_inds(i))],[],'omitnan');
%             
%             h(i) = figure;
%             set(gcf,'Position',[25 500 1250 500]);
%             subplot(1,2,1); hold on;
%             scatter(bmat(:,1),bmat(:,l_inds(i)),100,c,'filled','Marker','square');
%             scatter(bmat(:,1),bmat(:,r_inds(i)),100,c,'filled');
%             plot([0 cond_max*1.01],[0 cond_max*1.01],'--k');  % fix to max shift
%             set(gca,'XLim',[0,cond_max*1.01],'YLim',[0,cond_max*1.01],'FontSize',20);
%             xlabel('Bandwidth (Fixation)','FontSize',20);
%             ylabel(['Bandwidth (',names{i},' Pursuit)'],'FontSize',20);
%             title([titlestr,', n=',num2str(numcells)]);
%             colormap(gcf,colormaps{i});
%             cbar1 = colorbar;
%             cbar1.Label.String = 'Right-Left PTI';
%             annotation(gcf,'textbox',[0.27 0.3 0.32 0.0465],'Color',[0 0 0],...
%                 'String',['p=',num2str(p_cond)],'FontSize',18,'FitBoxToText','off','LineStyle','none');
%             
%             subplot(1,2,2); hold on;
%             h1 = histogram(bmat(:,1),'BinWidth',5,'FaceColor',[0 0.75 0]);
%             h2 = histogram([bmat(:,l_inds(i));bmat(:,r_inds(i))],'BinWidth',5,'FaceColor',cond_colors{i});
%             h1.FaceAlpha = 0.6;
%             h2.FaceAlpha = 0.6;
%             ylabel('Number of Occurrences','FontSize',20);
%             xlabel(['Tuning Curve Bandwidth (',deg_symbol,' FWHM)'],'FontSize',20);
%             title(['Fixation vs. ',names{i},' Pursuit']);
%             max_data = max([h1.Values h2.Values])+1;
%             set(gca,'YLim',[0 max_data],'YTick',0:1:max_data,'FontSize',20);
%             
%             text(fix_med,max_data-1,['\downarrow ',num2str(fix_med)],'Color',[0 0.75 0]);
%             text(cond_med,max_data-0.5,['\downarrow ',num2str(cond_med)],'Color',cond_colors{i});
%         end
%         
%         norm_fix_band = h(1);
%         sim_fix_band = h(2);
%         stab_fix_band = h(3);
%     end

% Tuning center stats
%     function [normvfix,simvfix,stabvfix] = tcstatplot(data,titlestr)
%         
%         tcmat = data.tuncent_mat;
%         num_cells = numel(data.cellID);
%         
%         % Conditions: 1 - Normal, 2 - Simulated, 3 - Stabilized
%         for con = 1:3
%             condition = con;
%             datmat = tcmat;
%             
%             paramind_l = condition + 1;
%             paramind_r = condition + 4;
%             l_color = [0 0 0;...
%                 0 0 0.65;...
%                 0.65 0 0];
%             r_color = [0.5 0.5 0.5;...
%                 0 0 1;...
%                 1 0 0];
%             purs_cond = {'Normal','Simulated','Stabilized'};
%             
%             %%%% Compare Pursuit Conditions vs fixation
%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             
%             % Flip sign of tuning curve shifts for leftwards pursuit (so simulated pursuit shifts CCW)
%             l_param = -1*(datmat(:,paramind_l)-datmat(:,1));
%             r_param = datmat(:,paramind_r)-datmat(:,1);
%             
%             % Flip sign of tuning curve shifts for backwards headings (so right purs
%             % always shifts tuning curve/CoM to right)
%             for i = 1:numel(data.backforw)
%                 r_param(i) = r_param(i)*data.backforw(i)';
%                 l_param(i) = l_param(i)*data.backforw(i)';
%             end
%             
%             xmin = 1.05*min(datmat(:,1),[],'omitnan');
%             xmax = 1.05*max(datmat(:,1),[],'omitnan');
%             ymin = 1.05*min([datmat(:,paramind_r);datmat(:,paramind_l)],[],'omitnan');
%             ymax = 1.05*max([datmat(:,paramind_r);datmat(:,paramind_l)],[],'omitnan');
%             
%             if xmin>0
%                 xmin = 0;
%             end
%             if ymin>0
%                 ymin = 0;
%             end
%             
%             unitmin = min([ymin xmin]);
%             unitmax = min([ymax xmax]);
%             
%             % Sign-rank test for tuning differences between fixation and pursuit
%             p = round(signrank([r_param;l_param]),3,'significant');
%             param_med = median([r_param;l_param],'omitnan');
%             
%             % Plot Pursuit-Fixation scatterplot
%             figs(con) = figure;
%             set(gcf,'Position',[50 50 1800 700]);
%             
%             subplot(1,2,1);
%             hold on;
%             scatter(datmat(:,1),datmat(:,paramind_l),100,'filled',...
%                 'MarkerFaceColor',l_color(condition,:));
%             scatter(datmat(:,1),datmat(:,paramind_r),100,'filled',...
%                 'MarkerFaceColor',r_color(condition,:));
%             plot([unitmin unitmax],[unitmin unitmax],'--k','LineWidth',3);  % fix to max shift
%             set(gca,'XLim',[xmin,xmax],'YLim',[ymin,ymax],'FontSize',20);
%             xlabel('Preferred Heading (Fixation, \circ Az)','FontSize',20);
%             ylabel(['Preferred Heading (',purs_cond{condition},' Pursuit)'],'FontSize',20);
%             title(titlestr);
%             annotation(gcf,'textbox',[0.3 0.2 0.32 0.0465],'Color',[0 0 0],...
%                 'String',['n=',num2str(num_cells)],'FontSize',30,'FitBoxToText',...
%                 'off','LineStyle','none');
%             
%             % Plot Pursuit-Fixation shift histogram
%             subplot(1,2,2);
%             hold on;
%             h = histogram([r_param;l_param],'BinWidth',5,'FaceColor',l_color(condition,:));
%             h2 = histogram(l_param,'BinWidth',5,'FaceColor',r_color(condition,:));
%             h.FaceAlpha = 1;
%             h2.FaceAlpha = 1;
%             maxshift = max(abs([h.Data;h2.Data]),[],'omitnan');
%             plot([0 0],[0 max(h.Values)+1],'--k','LineWidth',3);  % fix to max shift
%             xlabel(['\Delta',' Preferred Heading (',purs_cond{condition},...
%                 ' Pursuit - Fixation)'],'FontSize',20);
%             ylabel('Number of Shifts','FontSize',20);
%             title(titlestr);
%             plot([param_med param_med],[max(h.Values) max(h.Values)+1],'k','LineWidth',3);
%             ymaxlim = 2*floor(max(h.Values)/2)+4;
%             set(gca,'YTick',0:2:ymaxlim,'YMinorTick','On','FontSize',20);
%             a = gca;
%             a.YAxis.MinorTickValues = 0:1:ymaxlim;
%             set(gca,'XLim',[-maxshift*1.15,maxshift*1.15],'FontSize',20);
%             annotation(gcf,'textbox',[0.6 0.6 0.15 0.3],'Color',l_color(condition,:),...
%                 'String','Left Pursuit','FontSize',18,'FitBoxToText','off','LineStyle','none');
%             annotation(gcf,'textbox',[0.6 0.55 0.15 0.3],'Color',r_color(condition,:),...
%                 'String','Right Pursuit','FontSize',18,'FitBoxToText','off','LineStyle','none');
%             annotation(gcf,'textbox',[0.77 0.6 0.15 0.3],'Color',[0 0 0],...
%                 'String',['p<',num2str(p),', median=',num2str(param_med)],...
%                 'FontSize',18,'FitBoxToText','off','LineStyle','none');
%         end
%         
%         normvfix = figs(1);
%         simvfix = figs(2);
%         stabvfix = figs(3);
%     end

% Minocular vs Binocular paired comparisons
    function [normvfix,simvfix,stabvfix] = monobinocomp(binmat,monmat,xlab)
        % Get tuning center SHIFTS from fixation condition (during norm & sim purs)
        % and find shift differences between monocular/binocular
        
        lnormfix_bin = abs(binmat(:,2)-binmat(:,1));
        lnormfix_mon = abs(monmat(:,2)-monmat(:,1));
        rnormfix_bin = abs(binmat(:,5)-binmat(:,1));
        rnormfix_mon = abs(monmat(:,5)-monmat(:,1));
        lsimfix_bin = abs(binmat(:,3)-binmat(:,1));
        lsimfix_mon = abs(monmat(:,3)-monmat(:,1));
        rsimfix_bin = abs(binmat(:,6)-binmat(:,1));
        rsimfix_mon = abs(monmat(:,6)-monmat(:,1));
        lstabfix_bin = abs(binmat(:,4)-binmat(:,1));
        lstabfix_mon = abs(monmat(:,4)-monmat(:,1));
        rstabfix_bin = abs(binmat(:,7)-binmat(:,1));
        rstabfix_mon = abs(monmat(:,7)-monmat(:,1));
        
        shifts = [lnormfix_bin';lnormfix_mon';...
            rnormfix_bin';rnormfix_mon';...
            lsimfix_bin';lsimfix_mon';...
            rsimfix_bin';rsimfix_mon';...
            lstabfix_bin';lstabfix_mon';...
            rstabfix_bin';rstabfix_mon'];
        
        medians = nan(12,1);
        for i = 1:12
            medians(i,1) = median(shifts(i,:),'omitnan');
        end
        
        % Nonparametric test (Wilcoxin sign-rank) for significant
        % differences between monocular and binocular presentations
        
        p(1) = signrank(lnormfix_mon,lnormfix_bin);
        p(2) = signrank(rnormfix_mon,rnormfix_bin);
        p(3) = signrank(lsimfix_mon,lsimfix_bin);
        p(4) = signrank(rsimfix_mon,rsimfix_bin);
        p(5) = signrank(lstabfix_mon,lstabfix_bin);
        p(6) = signrank(rstabfix_mon,rstabfix_bin);
        
        % Plot Pursuit Conditions - Fixation histograms
        colors = [0 0 0;...
            0 0 1;...
            1 0 0];
        purs_cond = {'Normal','Simulated','Stabilized'};
        numcells = numel(lnormfix_bin);
        ylab = 'Number of Occurrences';
        
        for con = 1:3
            condition = con;
            lbin_param = shifts(1+4*(condition-1),:);
            lmon_param = shifts(2+4*(condition-1),:);
            rbin_param = shifts(3+4*(condition-1),:);
            rmon_param = shifts(4+4*(condition-1),:);
            
            compfigs(condition) = figure;
            set(gcf,'Position',[50 50 800 900]);
            
            % Left Pursuit
            subplot(2,1,1);
            hold on;
            h1 = histogram(lbin_param,'BinWidth',5,'FaceColor',colors(condition,:));
            h2 = histogram(lmon_param,'BinWidth',5,'FaceColor',[0.5 0.5 0.5]);
            h1.FaceAlpha = 0.8;
            h2.FaceAlpha = 0.8;
            ylabel(ylab,'FontSize',20);
            title('Left Pursuit Monoc v. Binoc');
            max_data=max([h1.Values h2.Values],[],'omitnan')+1;
            set(gca,'YLim',[0 max_data],'YTick',0:1:max_data,'FontSize',20);
            annotation(gcf,'textbox',[0.6 0.8 0.32 0.0465],'Color',[0 0 0],...
                'String',['n=',num2str(numcells),', p=',num2str(p(1+2*(condition-1)))],...
                'FontSize',18,'FitBoxToText','off','LineStyle','none');
            annotation(gcf,'textbox',[0.6 0.87 0.32 0.0465],'Color',colors(condition,:),...
                'String','Binocular','FontSize',18,'FitBoxToText','off','LineStyle','none');
            annotation(gcf,'textbox',[0.6 0.845 0.32 0.0465],'Color',[0.5 0.5 0.5],...
                'String','Monocular','FontSize',18,'FitBoxToText','off','LineStyle','none');
            
            % Right Pursuit
            subplot(2,1,2);
            hold on;
            h3 = histogram(rbin_param,'BinWidth',5,'FaceColor',colors(condition,:));
            h4 = histogram(rmon_param,'BinWidth',5,'FaceColor',[0.5 0.5 0.5]);
            h3.FaceAlpha = 0.8;
            h4.FaceAlpha = 0.8;
            xlabel(['\Delta ',xlab,' (',purs_cond{condition},' Pursuit - Fixation)'],'FontSize',20);
            ylabel(ylab,'FontSize',20);
            title('Right Pursuit Monoc v. Binoc');
            max_data2 = max([h3.Values h4.Values],[],'omitnan')+1;
            set(gca,'YLim',[0 max_data2],'YTick',0:1:max_data2,'FontSize',20);
            annotation(gcf,'textbox',[0.6 0.3 0.32 0.0465],'Color',[0 0 0],...
                'String',['n=',num2str(numcells),', p=',num2str(p(2+2*(condition-1)))],...
                'FontSize',18,'FitBoxToText','off','LineStyle','none');
            
            xmax = max([h1.BinEdges h2.BinEdges h3.BinEdges h4.BinEdges],[],'omitnan');
            subplot(2,1,1);
            set(gca,'XLim',[0 xmax]);
            subplot(2,1,2);
            set(gca,'XLim',[0 xmax]);
        end
        
        normvfix = compfigs(1);
        simvfix = compfigs(2);
        stabvfix = compfigs(3);
    end

end