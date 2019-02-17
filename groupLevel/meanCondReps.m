% Find mean number of condition repeats across all cells
load('/home/tyler/matlab/data/combined_monks/comb_params.mat');

numCells = numel(comb_params);
reps = nan(numCells,2);

view = arrayfun(@(x) ~isempty(x.monoc),comb_params);
view = double(view);
view(view==0) = 2;

for j = 1:numCells
    if view(j) == 1
        temp = comb_params(j).monoc.trial_FRs;
    end
    if view(j) == 2
        temp = comb_params(j).binoc.trial_FRs;
    end
    
    a = cellfun(@(x) numel(x),temp);
    a = reshape(a,1,numel(a));
    
    reps(j,1) = sum(a);
    reps(j,2) = numel(a);
end

repsBar = sum(reps(:,1))/sum(reps(:,2));
