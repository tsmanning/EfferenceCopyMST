function [] = replay_stats(path)

% Selects cells with replay datasets and performs stats over cell sample
%
% Usage: replay_stats

% Load in list of included cells

load([path,'population_data/included_cells.mat'])

cell_list = included_cells(:,1);
num_inc_cells = numel(cell_list);

% Search for cells with replay datasets
repinds = zeros(num_inc_cells,1);

for i = 1:num_inc_cells
    if exist([path,cell_list{i},'/pursuit_replay'],'dir') ~= 0
        repinds(i) = 1;
    end    
end

repinds2 = find(repinds == 1);
replay_cells = cell_list{repinds2};

rep_stats = struct;
type = {'simulated','replay'};

for i = 1:numel(replay_cells);
    rep_stats.cell = replay_cells{i};
    
    % Load in simulated data
    
    
    % Load in replay data
    
    
      
end

end