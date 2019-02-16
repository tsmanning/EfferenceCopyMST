function [] = single_cell_pipeline(datPath,opts,cellsubset)

% Automatic version of full_singlecell_analysis script, runs data according
% to instructions in cellDirtree, which collects how data was initially
% processed manually.
%
% Usage: single_cell_pipeline(opts,cellsubset)
%        single_cell_pipeline([1 1 1 0 0 0 1],[... 35 36 ...])
%
% opts = [E/A-file extraction,
%         spike stats,
%         heading tuning,
%         pursuit tuning,
%         bighead/merging/TC fit,
%         replay comp,
%         vol vs single plane]
% 
% Expects: cellDirTree to be located under ../data/cellDirTree
%          monkey data to be organized as ../data/monk1/Xbh_XXX

%%%%%%%%%%%%%%%%%%%%      TO DO        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% want to add a part to the beginning to build all directories? this should
% be the script supplied to someone never handling this data before (with
% cellDirTree .mat file)

% need to handle plotting at some point - probably better to supply inds
% than go through the entire cell set
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%datPath = '/home/tyler/matlab/data/';

load([datPath,'cellDirTree'])

% Set cellsubset to [] to run all cells, otherwise supply vector of inds
if isempty(cellsubset)
    cellInds = 1:numel(cellDirTree);
else
    cellInds = cellsubset;
end

wait_handle = waitbar(0,[0,num2str(numel(cellInds))],'Name','Running Trial:');
set(findall(wait_handle,'type','text'),'Interpreter','none'); % Turn off TeX interpreter for underscore

cellCount = 0;

for i = cellInds
    cellCount = cellCount + 1;
    
    waitbar(cellCount/numel(cellInds),wait_handle,...
        ['Cell ',num2str(cellCount),'/',num2str(numel(cellInds))])
    
    % Check if dataset was able to be run at all; skip if not
    if isempty(cellDirTree(i).dataManifest)
        warning(['Skipping cell ',cellDirTree(i).name,' without a data manifest']);
        cellCount = cellCount + 1;
        continue
    end
    
    monkey = cellDirTree(i).name(1:3);
    cellID = cellDirTree(i).name;
    cellPath = [datPath,monkey,'/',cellID,'/'];
    
    % Get Directories containing E/A files
    headTunDirs = cellDirTree(i).heading_tuning;
    pursTunDirs = cellDirTree(i).pursuit_tuning;
    
    if ~isempty(cellDirTree(i).bh_tests)
        temp = cellfun(@(x) numel(x),cellDirTree(i).bh_tests);
        origInds = temp == 4;   % Select only dirs named 'set?' and not merged ones
        bhTestDirs = cellDirTree(i).bh_tests(origInds);
    else
        bhTestDirs = cellDirTree(i).bh_tests;
    end
    
    replayDirs = cellDirTree(i).pursuit_replay;
    mdotDirs = cellDirTree(i).multidot;
    
    % Check if re-extraction flag set
    if opts(1)
        waitbar(cellCount/numel(cellInds),wait_handle,...
            ['Cell ',num2str(cellCount),'/',num2str(numel(cellInds)),...
            ' (',cellDirTree(i).name,' - Extracting E/A files)'])
        % Heading Tuning
        if numel(headTunDirs) == 1
            bh_dataex([cellPath,'heading_tuning'],[cellID,'_ht']);
        elseif ~isempty(headTunDirs)
            for j = 1:numel(headTunDirs)
                bh_dataex([cellPath,'heading_tuning/',headTunDirs{j}],[cellID,'_ht']);
            end
        end
        
        % Pursuit Tuning
        if numel(pursTunDirs) == 1
            bh_dataex([cellPath,'pursuit_tuning'],[cellID,'_pt']);
        elseif ~isempty(pursTunDirs)
            for j = 1:numel(pursTunDirs)
                bh_dataex([cellPath,'pursuit_tuning/',pursTunDirs{j}],[cellID,'_pt']);
            end
        end
        
        % Multidot (plots suppressed)
        if numel(mdotDirs) == 1
            multidot_extraction([cellPath,'multidot/'],[cellID,'_mdot'],1);
        elseif ~isempty(mdotDirs)
            for j = 1:numel(mdotDirs)
                multidot_extraction([cellPath,'multidot/',mdotDirs{j},'/'],[cellID,'_mdot'],1);
            end
        end
        
        % Bighead
        if numel(bhTestDirs) == 1
            bh_dataex([cellPath,'bh_tests/set1'],[cellID,'_bh']);
        elseif ~isempty(bhTestDirs)
            for j = 1:numel(bhTestDirs)
                bh_dataex([cellPath,'bh_tests/',bhTestDirs{j}],[cellID,'_bh']);
            end
        end
        
        % Pursuit Replay
        if numel(replayDirs) == 1
            bh_dataex([cellPath,'pursuit_replay'],[cellID,'_rp']);
        elseif ~isempty(replayDirs)
            for j = 1:numel(replayDirs)
                bh_dataex([cellPath,'pursuit_replay/',pursTunDirs{j}],[cellID,'_rp']);
            end
        end
        
        close all
    end
    
    % Check if stats flag is set (suppresses plots where possible)
    if opts(2)
        waitbar(cellCount/numel(cellInds),wait_handle,...
            ['Cell ',num2str(cellCount),'/',num2str(numel(cellInds)),...
            ' (',cellDirTree(i).name,' - Running Spike Stats)'])
        % Heading Tuning
        if numel(headTunDirs) == 1 
            neuron_stats(cellPath,0,'heading_tuning','Heading Tuning',1);
        elseif numel(headTunDirs) > 1
            for j = 1:numel(headTunDirs)
                neuron_stats(cellPath,j,'heading_tuning','Heading Tuning',1);
            end
        end
        
        % Pursuit Tuning
        if numel(pursTunDirs) == 1 
            neuron_stats(cellPath,0,'pursuit_tuning','Pursuit Tuning',1);
        elseif numel(pursTunDirs) > 1
            for j = 1:numel(pursTunDirs)
                neuron_stats(cellPath,j,'pursuit_tuning','Pursuit Tuning',1);
            end
        end
        
        % Bighead Tests
        if numel(bhTestDirs) == 1 
            neuron_stats(cellPath,1,'bh_tests','Bighead Tests',1);
        elseif numel(bhTestDirs) > 1
            for j = 1:numel(bhTestDirs)
                neuron_stats(cellPath,j,'bh_tests','Bighead Tests',1);
            end
        end
        
        % Replay Trials
        if numel(replayDirs) == 1 
            neuron_stats(cellPath,0,'pursuit_replay','Replay Tests',1);
        elseif numel(replayDirs) > 1
            for j = 1:numel(replayDirs)
                neuron_stats(cellPath,j,'pursuit_replay','Replay Tests',1);
            end
        end
        
        % Multidot
        if numel(mdotDirs) == 1 
            neuron_stats(cellPath,0,'multidot','Multidot Tests',1);
        elseif numel(mdotDirs) > 1
            for j = 1:numel(mdotDirs)
                neuron_stats(cellPath,j,'multidot','Multidot Tests',1);
            end
        end
        
        close all
    end
    
    % Heading Tuning (bighead_response_plots needs tuning map)
    if opts(3)
        waitbar(cellCount/numel(cellInds),wait_handle,...
            ['Cell ',num2str(cellCount),'/',num2str(numel(cellInds)),...
            ' (',cellDirTree(i).name,' - Heading Tuning)'])
        if numel(headTunDirs) == 1 
            ht_psth = 1;
            ht_tuning_map = 1;
            heading_response(cellPath,0);
            heading_response_2(cellPath,0);
            %heading_response_plots(cellPath,0,ht_psth,ht_tuning_map);
            
            numHeadTuns = 1;
        elseif numel(headTunDirs) > 1
            for j = 1:numel(headTunDirs)
                ht_psth = 1;
                ht_tuning_map = 1;
                heading_response(cellPath,j);
                heading_response_2(cellPath,j);
                %heading_response_plots(cellPath,j,ht_psth,ht_tuning_map);
            end
            
            numHeadTuns = numel(headTunDirs);
        end
        
        close all
    end
        
    % Pursuit Tuning
    if opts(4)
        waitbar(cellCount/numel(cellInds),wait_handle,...
            ['Cell ',num2str(cellCount),'/',num2str(numel(cellInds)),...
            ' (',cellDirTree(i).name,' - Pursuit Tuning)'])
        if numel(pursTunDirs) == 1
            if exist([cellPath,'pursuit_tuning/spikes.mat'],'file') == 0
                warning(['Skipping cell ',cellDirTree(i).name,': pursuit tuning not run.']);
                continue
            end
            
            pt_psth = 1;
            pt_tuning_map = 1;
            polar = 1;
            
            % Check to make sure each trial type run at least once
            load([cellPath,'pursuit_tuning/trials.mat'])
            if size(trials,1)<max(trials(:,2))
                warning(['Incomplete pursuit tuning dataset for cell ',cellDirTree(i).name]);
                continue
            else
                pursuit_response(cellPath,0);
                pursuit_response_2(cellPath,0);
                %pursuit_response_plots(cellPath,0,pt_psth,pt_tuning_map,polar);
                
                numPursTuns = 1;
            end
        elseif numel(pursTunDirs) > 1
            for j = 1:numel(pursTunDirs)
                pt_psth = 1;
                pt_tuning_map = 1;
                polar = 1;
                pursuit_response(cellPath,j);
                pursuit_response_2(cellPath,j);
                %pursuit_response_plots(cellPath,j,pt_psth,pt_tuning_map,polar);
                
                numPursTuns = numel(headTunDirs);
            end
        end
        
        close all
    end
    
    % Bighead Tests, set merging, & von Mises fits
    if opts(5)
        waitbar(cellCount/numel(cellInds),wait_handle,...
            ['Cell ',num2str(cellCount),'/',num2str(numel(cellInds)),...
            ' (',cellDirTree(i).name,' - Bighead Tests)'])
        
        if isempty(cellDirTree(i).bh_tests)
            warning(['Skipping cell ',cellDirTree(i).name,': bighead not run.']);
            
            continue
        end
        
        % Check for merged sets (binoc/monoc) & single plane sets
        binoc = ...
            sum(cellfun(@(x) strcmp(x,'set_merge_binoc'),cellDirTree(i).bh_tests));
        monoc = ...
            sum(cellfun(@(x) strcmp(x,'set_merge_monoc'),cellDirTree(i).bh_tests));
        single_plane = 0;
        if ~isempty(cellDirTree(i).single_plane)
            single_plane = 1;
        end
        
        warnSuppress = 1;
        
        if binoc
            num_eyes = 2;
            single_plane_stim = 0;
            test_sets = cellDirTree(i).bh_sets.set_merge_binoc.original_sets;
            bh_psth = 1;
            bh_tuning_map = 1;
            
            % If multiple heading tuning sets exist, specify which one is
            % linked to bighead dataset
            if exist([cellPath,'bh_tests/set_merge_binoc/headset.mat'],'file') ~= 0 
                load([cellPath,'bh_tests/set_merge_binoc/headset.mat'])
            elseif ~exist([cellPath,'heading_tuning/set1/'],'dir')
                headset = 0;
            elseif exist([cellPath,'bh_tests/set_merge_binoc.old/headset.mat'],'file') ~= 0
                load([cellPath,'bh_tests/set_merge_binoc.old/headset.mat'])
            end
            
%             for j = 1:numel(test_sets)
%                 % Initial Processing step
%                 bighead_response(cellPath,test_sets(j),num_eyes,single_plane_stim);
%                 % Measure quality of pursuit in each trial
%                 set_no = num2str(test_sets(j));
%                 set_dir = ['set',set_no,'/'];
%                 pur_quality([cellPath,'bh_tests/',set_dir],'trial_ev',[],0);
%             end
%             [trial_ev,trial_data] = set_merger(cellPath,test_sets,num_eyes);
%             
%             % Check to see if all trial types were run
%             numfix = sum(trial_data.purs_type == 0);
%             numnorm = sum(trial_data.purs_type == 1);
%             numsim = sum(trial_data.purs_type == 2);
%             numstab = sum(trial_data.purs_type == 3);
%             test = sum([numfix numnorm numsim numstab]);
%             
%             if test < 7*numel(unique(round(trial_data.trial_az,4)))
%                 warning(['Skipping cell ',cellDirTree(i).name,', binoc: bighead not completed.']);
%                 
%                 continue
%             end
%             
%             bighead_response_2(cellPath,'m',num_eyes,warnSuppress);
%             %bighead_response_plots(cellPath,'m',bh_psth,bh_tuning_map,num_eyes,headset);
%             bighead_modelfit(cellPath,'m',0,num_eyes,headset,0);
            
            load([cellPath,'bh_tests/set_merge_binoc/trial_ev'])
            [hStabLag] = pursStab(trial_ev,[]);
            save([cellPath,'bh_tests/set_merge_binoc/hStabLag'],'hStabLag');
            
            clear trial_ev
        end
        
        if monoc
            num_eyes = 1;
            single_plane_stim = 0;
            test_sets = cellDirTree(i).bh_sets.set_merge_monoc.original_sets;
            bh_psth = 1;
            bh_tuning_map = 1;
            
            if exist([cellPath,'bh_tests/set_merge_monoc/headset.mat'],'file') ~= 0 
                load([cellPath,'bh_tests/set_merge_monoc/headset.mat'])
            elseif ~exist([cellPath,'heading_tuning/set1/'],'dir')
                headset = 0;
            elseif exist([cellPath,'bh_tests/set_merge_monoc.old/headset.mat'],'file') ~= 0
                load([cellPath,'bh_tests/set_merge_monoc.old/headset.mat'])
            end
            
%             for j = 1:numel(test_sets)
%                 % Initial Processing step
%                 bighead_response(cellPath,test_sets(j),num_eyes,single_plane_stim);
%                 % Measure quality of pursuit in each trial
%                 set_no = num2str(test_sets(j));
%                 set_dir = ['set',set_no,'/'];
%                 pur_quality([cellPath,'bh_tests/',set_dir],'trial_ev',[],0);
%             end
%             [trial_ev,trial_data] = set_merger(cellPath,test_sets,num_eyes);
%             
%             % Check to see if all trial types were run
%             numfix = sum(trial_data.purs_type == 0);
%             numnorm = sum(trial_data.purs_type == 1);
%             numsim = sum(trial_data.purs_type == 2);
%             numstab = sum(trial_data.purs_type == 3);
%             test = sum([numfix numnorm numsim numstab]);
%             
%             if test < 7*numel(unique(round(trial_data.trial_az,4)))
%                 warning(['Skipping cell ',cellDirTree(i).name,', monoc: bighead not completed.']);
%                 
%                 continue
%             end
%             
%             bighead_response_2(cellPath,'m',num_eyes,warnSuppress);
%             %bighead_response_plots(cellPath,'m',bh_psth,bh_tuning_map,num_eyes,headset);
%             bighead_modelfit(cellPath,'m',0,num_eyes,headset,0);
            
            load([cellPath,'bh_tests/set_merge_monoc/trial_ev'])
            [hStabLag] = pursStab(trial_ev,[]);
            save([cellPath,'bh_tests/set_merge_monoc/hStabLag'],'hStabLag');
            
            clear trial_ev
        end
        
%         if single_plane
%             num_eyes = 1;
%             single_plane_stim = 1;
%             temp = cellDirTree(i).single_plane{1};
%             test_set = str2double(temp(end));
%             
%             if exist([cellPath,'bh_tests/',temp,'/headset.mat'],'file') ~= 0 
%                 load([cellPath,'bh_tests/',temp,'/headset.mat'])
%             else
%                 headset = 0;
%             end
%             
%             bighead_response(cellPath,test_set,num_eyes,single_plane_stim);
%             bighead_response_2(cellPath,test_set,num_eyes,warnSuppress);
%             %bighead_response_plots(cellPath,test_set,bh_psth,bh_tuning_map,num_eyes,headset);
%             bighead_modelfit(cellPath,test_set,0,num_eyes,headset,1);
%         end
        
        close all
    end

    % Replay comparisons
    if opts(6)
        waitbar(cellCount/numel(cellInds),wait_handle,...
            ['Cell ',num2str(cellCount),'/',num2str(numel(cellInds)),...
            ' (',cellDirTree(i).name,' - Pursuit Replay)'])
        
        if ~isempty(cellDirTree(i).pursuit_replay)
            stab_replay(cellPath);
        end
        
        close all
    end
    
    % Volume vs Single-plane comparison
    if opts(7)
        waitbar(cellCount/numel(cellInds),wait_handle,...
            ['Cell ',num2str(cellCount),'/',num2str(numel(cellInds)),...
            ' (',cellDirTree(i).name,' - Volume vs Single-Plane)'])
        
        if ~isempty(cellDirTree(i).depthcomp)
            vol_datadir = cellDirTree(i).depthcomp{2,1};
            sp_datadir = cellDirTree(i).depthcomp{2,2};
            bighead_depthcomp1(monkey,cellID,vol_datadir,sp_datadir,1);
        end
        
        close all
    end
end

delete(wait_handle);

end
