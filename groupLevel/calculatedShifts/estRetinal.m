function [m,p,med,f1,f2] = estRetinal(comb_monks,avging)

% Estimate expected shift in cell tuning curves based on physical shift in
% flow center of motion and compare to real shifts in simulated pursuit
%
% Usage = [m,p,med,f1,f2] = estRetinal(comb_monks)
%         [m,p,med,f1,f2] = estRetinal(comb_monks)

%% Extract vals

numCells = numel(comb_monks.cellID);

% Grab neural tuning curve shifts
simL = comb_monks.tuncent_mat(:,3)-comb_monks.tuncent_mat(:,1);
simR = comb_monks.tuncent_mat(:,6)-comb_monks.tuncent_mat(:,1);

% Grab best fit preferred azimuth and tested elevation
fixPrefAz = comb_monks.headcents;
fixPrefEl = comb_monks.elevation;

% Define whether motion center is contraction or expansion
backforw = comb_monks.backforw;

%% Calculate centers of across all visible depth planes in all cells
comMatR = nan(numCells,101);
comMatL = nan(numCells,101);

for i = 1:numCells
    % Y-axis rotation inverted: -ve is rightward
    [ltemp,~,~] = comFinder([0 -10 0],[fixPrefAz(i) fixPrefEl(i) 50],50,0);
    [rtemp,~,~] = comFinder([0 10 0],[fixPrefAz(i) fixPrefEl(i) 50],50,0);
    
    comMatL(i,:) = atan(ltemp/50)*(180/pi);
    comMatR(i,:) = atan(rtemp/50)*(180/pi);
end

%% Calculate mean of CoM (refer back to royden '94 for how subjects weight)

% Number of actual vals in mean
numValsR = sum(~isnan(comMatR),2);
numValsL = sum(~isnan(comMatL),2);

numValsR(numValsR==0) = nan;    % Avoid divide by zero errors
numValsL(numValsL==0) = nan;

% Straight mean of CoM
meanComsR = nanmean(comMatR,2);
meanComsL = nanmean(comMatL,2);

% Depth weighted mean of CoM (closest weighted most)
comMatRzeros = comMatR;
comMatLzeros = comMatL;

temp1 = isnan(comMatR);
temp2 = isnan(comMatL);

comMatRzeros(isnan(comMatR)) = 0;    % Convert nans to zero for weighted mean  
comMatLzeros(isnan(comMatL)) = 0;

weightVec = 1./(50:150);
weightSumVecR = ~temp1*weightVec';
weightSumVecL = ~temp2*weightVec';

weightedMeanComsR = comMatRzeros*weightVec'./weightSumVecR;
weightedMeanComsL = comMatLzeros*weightVec'./weightSumVecL;

% Select averaging method
switch avging
    case 'UnweightedMean'
        % Use straight mean
        catcom = [meanComsL;meanComsR];
    case 'WeightedMean'
        % Use inverse-depth weighting
        catcom = [weightedMeanComsL;weightedMeanComsR];
    case 'NearPlanes'
        % Use nearest x planes
        % nearest 2: 0.1% total volume (~5 dots)
        % nearest 5: 0.4% total volume (~14 dots)
        % nearest 10: 0.9% total volume (~31 dots)
        % nearest 50: 10% total volume (~350 dots)
        x = 10;
        nearMeanComsR = nanmean(comMatR(:,1:x),2);
        nearMeanComsL = nanmean(comMatL(:,1:x),2);
        catcom = [nearMeanComsL;nearMeanComsR];
end

%% Calculate expected azimuth shifts (Center of Motion pursuit - fixation)

% Convert best fit preferred azimuths to CoM location
preftemp = fixPrefAz;
preftemp(preftemp<-90) = preftemp(preftemp<-90) + 360; % [-90,270)
preftemp(preftemp>90) = preftemp(preftemp>90) - 180;   % [-90,90]

% Calculate Heading shift
comshifts = catcom - [preftemp;preftemp];

% Calculate tuning shift (opposes CoM shift - assumes constant shifts for 
% each heading direction)
comshifts = -comshifts;

% Concatenate neuronal tuning shifts and select only non-NaNs
catsim = [simL;simR];
nonnaninds = and(~isnan(comshifts),~isnan(catsim));

% Invert shifts for backwards headings
comshifts = comshifts .* [backforw;backforw];
catsim = catsim .* [backforw;backforw];

%% Linear regression for relationship between two
b = mean(catsim(nonnaninds));
m = catsim(nonnaninds)\comshifts(nonnaninds);

% covfefe = pca([catsim(nonnaninds) comshifts(nonnaninds)]);
% m = covfefe(1,1)/covfefe(2,1);
% m = covfefe(2,1)/covfefe(1,1);

% [m,b] = lsqbisec(catsim(nonnaninds),comshifts(nonnaninds));

f1 = figure;
f1.Position = [120 220 850 750];
f1.Renderer = 'painters';
plotLims = 80;

% Third axis: lateral position of CoM during fixation
c = (abs(preftemp)/90)-0.1;
c = repmat(c,1,3);
a = [preftemp;preftemp];
inds = ~isnan(catsim);
[rho,p] = corr([catsim(inds)],a(inds),'Type','Spearman');

hold on
scatter(comshifts(1:numCells,1),catsim(1:numCells,1),100,'filled','k');
% scatter(comshifts(1:numCells,1),catsim(1:numCells,1),100,c,'filled');
scatter(comshifts(1+numCells:2*numCells,1),catsim(1+numCells:2*numCells,1),...
    60,'k','LineWidth',2);
% scatter(comshifts(1+numCells:2*numCells,1),catsim(1+numCells:2*numCells,1),...
%     60,c,'LineWidth',2);
set(gca,'xlim',[-80 80],'ylim',[-80 80],'FontSize',20);
plot([-plotLims plotLims],[-plotLims plotLims],'--k');
% plot([-plotLims plotLims],[plotLims -plotLims],'--k');
plot([-plotLims plotLims],[-plotLims*m plotLims*m]+b,'--r');
xlabel('Mean Physical Shift (\circ)');
ylabel('Neuronal Shift (\circ)');

text(18,-60,['Slope = ',num2str(m)],'color','r','FontSize',20);
title(avging);

%% Calculate paired difference and run stats

% Fold data for pursuit direction
comshifts(1:numCells) = comshifts(1:numCells)*-1;
catsim(1:numCells) = catsim(1:numCells)*-1;

f2 = figure;
f2.Position = [980 220 850 750];
f2.Renderer = 'painters';
hold on;

pval = signrank(comshifts,catsim);
p = round(pval,3,'significant');
med = median(comshifts-catsim,'omitnan');
med = round(med,3,'significant');

limval = max(abs(comshifts-catsim))*1.1;

h = histogram([comshifts-catsim],'BinWidth',5,...
    'FaceColor','k','EdgeColor','k');
h2 = histogram([comshifts(1+numCells:2*numCells)-catsim(1+numCells:2*numCells)],...
    'BinWidth',5,'FaceColor','w','EdgeColor','k');
maxCount = max(h.Values);
plot([0 0],[0 maxCount*1.11],'--k','LineWidth',2);
set(gca,'xlim',[-limval limval],'ylim',[0 maxCount*1.11],'FontSize',20);
xlabel('Mean Physical Shift - Neuronal Shift');
plot([med med],[maxCount*1.02 maxCount*1.09],'k','LineWidth',3);
scatter(med,maxCount*1.02,100,'k','filled','v');
    
text(med-2,maxCount*1.08-1,['(p=',num2str(p),')'],'FontSize',20,...
    'HorizontalAlignment','right');
text(med-2,maxCount*1.08,['Med=',num2str(med)],'FontSize',20,...
    'HorizontalAlignment','right');
title(avging);

keyboard;
end