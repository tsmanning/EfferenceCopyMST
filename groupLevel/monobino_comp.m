function [compfig] = monobino_comp(data,param)

% Checks for significant differences in parameter fits between monocular and
% binocular viewing conditions.
%
% Usage: [] = monobino_comp(data([qbh,pbh,...]),[1:4])
%        For data, concatenate monobino structures
%        1: gain, 2: offset, 3: bandwidth, 4: tuning center shift

% Check if data from multiple monkeys is input, if so concatenate datasets.
%%%% want to add bit to ID which monkey data was collected from
num_monks = numel(data);

if num_monks == 1
    monobino_data = data;
elseif num_monks > 1
    struct_fields = fieldnames(data(1));
    
    % Initialize empty field names
    for i = 1:numel(struct_fields)
        monobino_data.(struct_fields{i}) = [];
    end
    
    % Concatenate data from monkey data sets
    for i = 1:num_monks
        for j = 1:numel(struct_fields)
            % would be better to go back and fix this in bh_grouptune3
            if ~iscolumn(data(i).(struct_fields{j})) && isrow(data(i).(struct_fields{j}))
                monobino_data.(struct_fields{j}) = ...
                    [monobino_data.(struct_fields{j});data(i).(struct_fields{j})'];
            else
                monobino_data.(struct_fields{j}) = ...
                    [monobino_data.(struct_fields{j});data(i).(struct_fields{j})];
            end
        end
    end
end

% Grab parameter of interest
params = {'gain','offset','band','centshift'};

xb = ['bin_',params{param},'_mat'];
xm = ['mon_',params{param},'_mat'];

m_datamat = monobino_data.(xm);
b_datamat = monobino_data.(xb);

% Set up params for plots/stats mats
conds = {'Normal','Simulated','Stabilized'};
% colors = [0 0 0;...
%     0 0 0.5;...
%     0.5 0 0;...
%     0.5 0.5 0.5;...
%     0 0 1;...
%     1 0 0];
condColors = {[0 0 0],[0 0 0.55],[0.55 0 0]};
condColorsR = {[0.65 0.65 0.65],[0 0 1],[1 0 0]};
paramLabels = {'Amplitude','Offset','Bandwidth','Preferred Heading'};
paramUnits = {'Sp/s','Sp/s','\circ Az','\circ Az'};

allmax = max(max(abs([b_datamat;m_datamat])));

unitmin = -allmax;
unitmax = allmax;

p = nan(3,1);   % non-parametric
p2 = nan(3,1);   % parametric
meds = nan(3,2);

compfig = figure;
set(gcf,'Position',[50 50 1800 450]);
hold on;

for i = 1:3
    subplot(1,3,i);
    hold on;
    
    scatter(b_datamat(:,i),m_datamat(:,i),100,'filled',...
        'MarkerFaceColor',condColors{i},...
        'MarkerEdgeColor',condColors{i});
    scatter(b_datamat(:,i+3),m_datamat(:,i+3),100,'filled',...
        'MarkerFaceColor',condColorsR{i},...
        'MarkerEdgeColor',condColorsR{i},...
        'MarkerFaceAlpha',0.7,...
        'MarkerEdgeAlpha',1);
    
    plot([unitmin unitmax],[unitmin unitmax],'--k','LineWidth',2);  % fix to max shift
    set(gca,'XLim',[unitmin,unitmax],'YLim',[unitmin,unitmax],'FontSize',15);
    xlabel(['\Delta ',paramLabels{param},'(Binocular, ',paramUnits{param},')'],'FontSize',15);
    ylabel(['\Delta ',paramLabels{param},'(Monocular, ',paramUnits{param},')'],'FontSize',15);
    title(conds{i});
    
    p(i) = signrank([b_datamat(:,i);b_datamat(:,i+3)],[m_datamat(:,i);m_datamat(:,i+3)]);
    medDiff(i) = median([b_datamat(:,i);b_datamat(:,i+3)]-[m_datamat(:,i);m_datamat(:,i+3)],'omitnan');
    [~,p2(i)] = ttest([b_datamat(:,i);b_datamat(:,i+3)],[m_datamat(:,i);m_datamat(:,i+3)]);
    
    meds(i,1) = median([b_datamat(:,i);b_datamat(:,i+3)]);
    meds(i,2) = median([m_datamat(:,i);m_datamat(:,i+3)]);
    
    numcells = numel(b_datamat(:,i));
    text(15,-0.45*unitmax,['med = ',num2str(round(medDiff(i),3,'significant'))],'FontSize',15);
%     text(15,-0.55*unitmax,['p = ',num2str(round(p2(i),3,'significant'))],'FontSize',15);
    text(15,-0.55*unitmax,['p = ',num2str(round(p(i),3,'significant'))],'FontSize',15);
    text(15,-0.65*unitmax,['N = ',num2str(numcells)],'FontSize',15);
end

end