%% Population sampling analysis pipeline for Bighead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define analysis options

dataDir = '/home/tyler/matlab/data/';

monkey = {'pbh','qbh','rbh'};
monkinds = [1:3];

for i = monkinds
    %% Setup
    cellspath = [dataDir,monkey{i},'/'];
    poppath = [cellspath,'population_data/'];
    
    if ~exist(poppath,'dir')
        mkdir(poppath);
    end
    
%     %% 1. Find cells that pass inclusion criteria 
%     %       thresholds = [anova rsqr num_reps lockout]
%     %
%     %       [included_cells,cell_stats,excluded_cells,reasons] = 
%     %           cell_excluder2(cellspath,monkey,thresholds);
%     %   
%     %       collectfigs(cellspath,mean_std,fits);
    
    thresholds = [0.05,0.5,4,0.05,1];
   
    [included_cells,cell_stats,excluded_cells,reasons] = ...
         cell_excluder(cellspath,monkey{i},thresholds);
    
%     % collectfigs(cellspath,1,0);
%     
%     %% 2. Collect von Mises fit parameters, plot distribution of heading and
%     %    pursuit direction preferences 
%     %
%     %    [bh_grouptune2(cellspath,plot_tuning_dists,fitcutoff)]
%     %
%     %    fitcutoff will nan out all parameters associated with fit rqrs less
%     %    than number (same as threshold used for cell_excluder2
    
    bh_grouptune(cellspath,1,0.3);
    
%     %% 3. Plot parameters: 
%     %       [plot_group_params(poppath,gain,offset,band,shift)]
%     
    plot_group_params(poppath,1,1,1,1);
%     
%     %% 4. Run statistics: 
%     %       group_stats(path,gain,offset,band,tuncent,savesuppress)
    
    group_stats(poppath,0,0,0,1,0);
    
%     %% 5. Run replay analysis:
%     %       replay_stats(crossMonk,cellspath,saveSuppress);
%     
    replay_stats(0,cellspath,0);
%       
    % Clean up
    if numel(monkinds) > 1
        close all
    end
end

%% 7. Combine data from monkeys:
%       (only monocular data available for pbh)
%
%       pars = [tuning_center offset amplitude bandwidth];
%       [comb_params,comb_monks] = ...
%           combine_monks(monk_dirs,monk_viewparams,sepplots,pars,saveSuppress);

monk_dirs = {[dataDir,'qbh/population_data/'],...
             [dataDir,'pbh/population_data/'],...
             [dataDir,'rbh/population_data/']};
monk_params = {'comb',...
               'monoc',...
               'comb'};
[monk_data,comb_monks] = combine_monks(monk_dirs,monk_params,0,[1 0 0 0],0);

%% 8. Run Monocular/Binocular comparison

params = {'amplitude','offset','bandwidth','tuning_center'};

for i = 1:numel(monkey)
   mbset(i) = load([monk_dirs{i},'monobino']); 
end

[mbComp] = monobino_comp([mbset(1).monobino,mbset(2).monobino,mbset(3).monobino],4);

hgsave(mbComp,[dataDir,'combined_monks/',params{4},'/mbComp']);

