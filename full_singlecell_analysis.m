% Single cell data analysis pipeline for Bighead

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define analysis options

monkey = 'qbh';
cell_no = '146';
cell_id = [monkey,'_',cell_no];

datpath = ['/home/tyler/matlab/data/',monkey,'/',cell_id];
filename = cell_id;

test_set = 'm';              % For trials with only one set, set to zero; 
                           % for merged set to 'm'
%%%%%%%%%%%%%%%%%%

file_ex = 0;

multidot_ext = 0;

spike_stats = 0;
    ht_stats = 1;
    pt_stats = 1;
    bh_stats = 0;
    rp_stats = 0;
    mdot_stats = 0;

heading_data = 0;
    ht_data_only = 0;
    ht_plot_only = 1;
    ht_psth = 0;
    ht_tuning_map = 1;  

pursuit_data = 0;
    pt_data_only = 0;
    pt_plot_only = 1;
    pt_psth = 0;
    pt_tuning_map = 1;
        polar = 1;

bighead_data = 1;
    num_eyes = 1;          % Monocular = 1, Binocular = 2
    
    % need to stick in pursQual stuff here, between bh_response_1 and *_2
    merge_sets = 0;
    test_sets = [1];       % List set numbers alone 
                           % (e.g. to combine set1 & set 2, use [1 2])

    headset = 0;           % If more than one ht dataset, define one that
                           % plot/fit uses

    bh_data_only = 0;
    bh_plot_only = 1;
    bh_psth = 1;
    bh_tuning_map = 0;
    
    single_plane_stim = 0;
    
run_fit = 0;               % Fits data with von Mises

run_dynamics = 0;
    kernel_no = 2;         % Kernel options: 1)exponential, 2)gaussian, 
                           %                 3)alpha, 4)boxcar
    conditions = 6:7;      % Conditions: 1)fixation, 2/3)normal, 
                           %             4/5)simulated, 6/7) stabilized  
run_replay = 0;

run_volvssp = 0;           % Run after all bighead_data* fxns are run
    vol_datadir = 'set_merge_monoc';    % Volume Set
    sp_datadir = 'set2';                % Single Plane Set
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%   Data Extraction   %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if file_ex
    % Split data into heading tuning, pursuit tuning, and bighead trial
    % datasets
    if ~exist([datpath,'/data_manifest.mat'],'file')
        [data_manifest] = build_dirs(datpath,filename);
    else
        load([datpath,'/data_manifest.mat']);
    end
    
    % Extract data from E/A files and sort into trials
    
    if data_manifest.ht_tests == 1  % Check number of sets for each test
        bh_dataex([datpath,'/heading_tuning'],[filename,'_ht']);
    else
        for i = 1:data_manifest.ht_tests
            bh_dataex([datpath,'/heading_tuning/set',num2str(i)],[filename,'_ht']);
        end
    end
    
    if data_manifest.pt_tests == 1
        bh_dataex([datpath,'/pursuit_tuning'],[filename,'_pt']);
    else
        for i = 1:data_manifest.pt_tests
            bh_dataex([datpath,'/pursuit_tuning/set',num2str(i)],[filename,'_pt']);
        end
    end
    
    %     if data_manifest.bh_tests == 1
    %         bh_dataex([datpath,'/bh_tests'],[filename,'_bh']);
    %     else
    for i = 1:data_manifest.bh_tests
        bh_dataex([datpath,'/bh_tests/set',num2str(i)],[filename,'_bh']);
    end
    %     end
    
    if data_manifest.rp_tests == 1
        bh_dataex([datpath,'/pursuit_replay'],[filename,'_rp']);
    else
        for i = 1:data_manifest.rp_tests
            bh_dataex([datpath,'/pursuit_replay/set',num2str(i)],[filename,'_rp']);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%    FR Statistics    %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if spike_stats
    if ht_stats
        neuron_stats(datpath,test_set,'heading_tuning','Heading Tuning',0);
    end
    if pt_stats
        neuron_stats(datpath,test_set,'pursuit_tuning','Pursuit Tuning',0);
    end
    if bh_stats
        neuron_stats(datpath,test_set,'bh_tests','Bighead Tests',0);
    end
    if rp_stats
        neuron_stats(datpath,test_set,'pursuit_replay','Replay Tests',0);
    end
    if mdot_stats
        neuron_stats(datpath,test_set,'multidot','Multidot Tests',0);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% Heading Tuning Data %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if heading_data
    if ~ht_plot_only
        % Extract event and spike times and align trials
        heading_response(datpath,test_set);
        
        % Consolidate trial repetitions and calculate vector mean/SEM/spike density
        % functions
        heading_response_2(datpath,test_set);
        
        % Plot trial spike density plots and tuning maps (set dynamics/tuning_map
        % to 1 to plot)
        heading_response_plots(datpath,test_set,ht_psth,ht_tuning_map);
        
    elseif ht_plot_only
        heading_response_plots(datpath,test_set,ht_psth,ht_tuning_map);
    elseif ht_data_only
        heading_response(datpath,test_set);
        heading_response_2(datpath,test_set);
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% Pursuit Tuning Data %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if pursuit_data
    if ~pt_plot_only
        % Extract event and spike times and align trials
        pursuit_response(datpath,test_set);
        
        % Consolidate trial repetitions and calculate vector mean/SEM/spike density
        % functions
        pursuit_response_2(datpath,test_set);
        
        % Plot trial spike density plots and tuning maps (set dynamics/tuning_map
        % to 1 to plot)
        pursuit_response_plots(datpath,test_set,pt_psth,pt_tuning_map,polar);
        
    elseif pt_plot_only
        pursuit_response_plots(datpath,test_set,pt_psth,pt_tuning_map,polar);
    elseif pt_data_only
        pursuit_response(datpath,test_set);
        pursuit_response_2(datpath,test_set);
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%     Bighead Data    %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if bighead_data
    warnSuppress = 0;
    
    if ~bh_plot_only && ~merge_sets && ~bh_data_only
        % Extract event and spike times and align trials
        bighead_response(datpath,test_set,num_eyes,single_plane_stim);
        % Measure quality of pursuit in each trial
        set_no = num2str(test_set);
        set_dir = ['set',set_no,'/'];
        pur_quality([datpath,'/bh_tests/',set_dir],'trial_ev',[],0);
        
        % Consolidate trial reps and calculate vector mean/SEM/spike density functions
        bighead_response_2(datpath,test_set,num_eyes,warnSuppress);
        
        % Plot trial-wise spike density plots and pursuit condition tuning curves
        bighead_response_plots(datpath,test_set,bh_psth,bh_tuning_map,num_eyes,headset);
        
    elseif bh_plot_only && ~merge_sets
        bighead_response_plots(datpath,test_set,bh_psth,bh_tuning_map,num_eyes,headset);
    elseif bh_data_only && ~merge_sets
        bighead_response(datpath,test_set,num_eyes,single_plane_stim);
        bighead_response_2(datpath,test_set,num_eyes,warnSuppress);
    end
    
    if merge_sets
        % Get trial_ev struct for individual sets + merge
        for i = 1:numel(test_sets)
            bighead_response(datpath,test_sets(i),num_eyes,single_plane_stim);
            set_no = num2str(test_sets(i));
            set_dir = ['set',set_no,'/'];
            pur_quality([datpath,'/bh_tests/',set_dir],'trial_ev',[],0);
        end
        set_merger(datpath,test_sets,num_eyes);
        
        % Run rest of stream on
        bighead_response_2(datpath,'m',num_eyes,warnSuppress);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%     Bighead Fit     %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if run_fit
    bighead_modelfit(datpath,test_set,1,num_eyes,headset,0);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%     Multidot extraction/analysis     %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if multidot_ext
    if test_set~=0
        set_no = num2str(test_set);
        set_dir = ['set',set_no,'/'];
    elseif test_set == 0
        set_dir = '';
    end
    multidot_extraction([datpath,'/multidot/',set_dir],[filename,'_mdot'],0);
end

%-------------------------------------------------------------------------%
% Clear settings vars

clear file_ex spike_stats ht_stats pt_stats bh_stats heading_data ht_plot_only ...
    ht_psth ht_tuning_map pursuit_data pt_plot_only pt_psth pt_tuning_map...
    bighead_data merge_sets bh_plot_only bh_dynamics bh_tuning_map run_dynamics ...
    plot_psth plot_az plot_diff_nopurs plot_diff_normpurs run_fit
