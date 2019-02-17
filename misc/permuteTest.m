function [p,testVal,statfig] = permuteTest(group1,group2,numReps,compFxn,plotOn)

% Run permutation test on two groups for median paired difference
%
% Usage: [p] = permuteTest(group1,group2,numReps,compFxn,plotOn)
%        [p] = permuteTest([vec1],[vec2],10000,1,1)
%        compFxn: 1-Median, 2-Mean, 3-Correlation

% Get size of groups to use (number of non-nan pairs)
nonNanPairs = and(~isnan(group1),~isnan(group2));
groupSize = sum(nonNanPairs);

% Get pool of datapoints to sample from
allPts = [group1(nonNanPairs);group2(nonNanPairs)];

% Get measured comparison between groups
switch compFxn
    case 1
        fxn = @(g1,g2) median(g1 - g2,'omitnan');
        xlab = 'Median Paired Difference';
    case 2
        fxn = @(g1,g2) nanmean(g1 - g2);
        xlab = 'Mean Paired Difference';
    case 3
        fxn = @(g1,g2) corr(g1,g2);
        xlab = 'Correlation';
end

testVal = fxn(group1(nonNanPairs),group2(nonNanPairs));

% Run resampling
resampVals = nan(numReps,1);
for i = 1:numReps
    if compFxn ~= 3
        g1Inds = randsample(numel(allPts),groupSize,1);
        g2Inds = randsample(numel(allPts),groupSize,1);
        
        resampVals(i,1) = fxn(allPts(g1Inds),allPts(g2Inds));
    else
        g1Inds = randsample(groupSize,groupSize,1);
        g2Inds = randsample(groupSize,groupSize,1);
        
        grp1 = group1(nonNanPairs);
        grp2 = group2(nonNanPairs);
        
        resampVals(i,1) = fxn(grp1(g1Inds),grp2(g2Inds));
    end
end

% Get probability of drawing difference (two-tailed test)
% p = 2*min((x<X|H_0),x>X(|H_0))
p = 2*min([sum(testVal>resampVals)/numel(resampVals);...
           sum(testVal<resampVals)/numel(resampVals)]);

if plotOn
    statfig = figure;
    statfig.Position = [100 100 1800 700];
    
    subplot(1,2,1);
    hold on;
    maxDat = max([group1;group2])*1.1;
    minDat = min([group1;group2])*1.1;
    Lims = max([abs(maxDat) abs(minDat)]);
    scatter(group1,group2,100,'filled','k');
    ax1 = gca;
    set(gca,'FontSize',20);
    
    if compFxn == 3
        plot([-Lims Lims],[-Lims Lims],'--k');
        ax1.YLim = [-Lims Lims];
    else
        plot([0 0],[0 Lims],'--k');
        ax1.XLim = [0 Lims];
    end
    
    subplot(1,2,2);
    hold on;
    histogram(resampVals,100,'FaceColor','k');
    ax2 = gca;
    ymax = ax2.YLim(2);
    xmax = max(ax2.XLim);
    ax2.XLim = [-xmax xmax];
    xlabel(xlab);
    set(gca,'FontSize',20);
    plot([testVal testVal],[0 ymax],'--r');
    text(0.9*-xmax,0.85*ymax,['x_{samp} = ',num2str(round(testVal,3,'significant'))],'FontSize',20);
    text(0.9*-xmax,0.95*ymax,['p(x_{samp}|x_{pop}=0) = ',num2str(round(p,3,'significant'))],'FontSize',20);
end

end
