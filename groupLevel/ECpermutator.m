% Run permutation test for condition-wise firing rates
load('/home/tyler/matlab/data/combined_monks/comb_params.mat');
load('/home/tyler/matlab/data/combined_monks/comb_monks.mat');

numCells = numel(comb_params);
backforw = comb_monks.backforw;

% ID which viewing condition to use for each cell dataset
views = arrayfun(@(x) ~isempty(x.monoc),comb_params);
views = double(views);
views(views==0) = 2;
viewName = {'monoc','binoc'};

% Trialwise FRs are organized as follows -
%   rows: pursuit condition (F,Nr,Nl,Sir,Sil,Stl,Str)
%   columns: heading azimuth

cellData = struct;
for i = 1:numCells
    viewtemp = viewName{views(i)};
    
    cellData(i).cellID = comb_params(i).cellID;
    cellData(i).FRmat = comb_params(i).(viewtemp).trial_FRs;
    cellData(i).angles = comb_params(i).(viewtemp).azimuth;
end

% Want to make several pools for shuffling/selection with replacement
% 1) F + Str
% 2) F + Stl
% 3) Nr + Sir
% 4) Nl + Sil
% 5) F + Str + Stl
%
% Use these pools to generate new (F,Nr,Nl,Sir,Sil,Stl,Str)

numReps = 500;

normVsim = nan(numReps,numCells*2);
stabVfix = nan(numReps,numCells*2);

wait_handle = waitbar(0,[0,num2str(numReps)],'Name','Permutation Cycle:');

% Permutation loop
for i = 1:numReps
    waitbar(i/numReps,wait_handle,[num2str(i),'/',num2str(numReps)])
    
    tcMat = nan(numCells,7);
    
    % Loop over included cells
    for j = 1:numCells
        % 1) Make Pools and collect tested heading angles
        angles = cellData(j).angles.*(pi/180);
        
        % Hack to avoid round off errors in finding unique angles for a cell
        tempAng = diff(angles);
        temp2 = find(tempAng<(pi/180));
        if ~isempty(temp2)
            keepInds = ones(numel(angles),1,'logical');
            keepInds(temp2 + 1) = false;
            angles = angles(keepInds);
        end
        angle_spacing = round(diff(angles(1:2)),5,'significant');
        
        numAngles = numel(angles);
        numTrials = cellfun(@(x) numel(x),cellData(j).FRmat);
        
        poolDat = cell(4,numAngles);
        for k = 1:numAngles
            poolDat{1,k} = [cellData(j).FRmat{1,k};cellData(j).FRmat{6,k}];
            poolDat{2,k} = [cellData(j).FRmat{1,k};cellData(j).FRmat{7,k}];
            poolDat{3,k} = [cellData(j).FRmat{2,k};cellData(j).FRmat{4,k}];
            poolDat{4,k} = [cellData(j).FRmat{3,k};cellData(j).FRmat{5,k}];
            poolDat{5,k} = [cellData(j).FRmat{1,k};cellData(j).FRmat{6,k};...
                            cellData(j).FRmat{7,k}];
        end
        
        % 2) Resample to build new matrix of FRs
        resampMat = cell(size(cellData(j).FRmat));
        
        % Define pools used for each condition
        poolinds = [5 3 4 3 4 1 2];
        
        % Loop over angles
        for k = 1:numAngles
            % Loop over pursuit conditions
            for l = 1:7
                pool = poolinds(l);
                
                % Randomly populate FR vector from pools (no replacement)
                inds = randsample(numel(poolDat{pool,k}),numTrials(l,k),1);
                
                temp = poolDat{pool,k};
                resampMat{l,k} = temp(inds);
            end
        end
        
        % 3) Arrange FRs into structure of double arrays for fitting
        maxTrials = max(numTrials,[],2);
        frStruct = struct;
        
        % Loop over pursuit conditions
        for k = 1:7
            frStruct(k).FRs = nan(maxTrials(k),7);
            
            for l = 1:numAngles
                frStruct(k).FRs(1:numTrials(k,l),l) = [resampMat{k,l}];
            end
        end

        % 4) Fit resampled data and get preferred tuning
        %    (takes ~0.23sec/cell)
        prefHead = nan(1,7);
        
        % Loop over pursuit conditions
        for k = 1:7
            data = frStruct(k).FRs;
            
            [datMax,maxInd] = max(nanmean(data,1));
            [datMin,~] = min(nanmean(data,1));
            minamp = datMax - datMin;
            thetaPref = angles(maxInd);
            
            % Set up initial conditions and constraints for fmincon
            x0 = [datMax angles(maxInd) pi datMin];
            opts = optimoptions(@fmincon,'Display','off');
            lb = [minamp thetaPref-angle_spacing 1.5*diff(angles(1:2)) 0];
            ub = [datMax*1.15 thetaPref+angle_spacing Inf datMin];

            fitParams = ...
                fmincon(@vmFitScoreLSQ,x0,[],[],[],[],lb,ub,[],opts,data,angles);
            
            prefHead(k) = fitParams(2).*(180/pi);
        end
        
        tcMat(j,:) = prefHead;
    end
    % 5) Subtract pref. tunings and run folding procedure
    
    normVfixR = tcMat(:,2) - tcMat(:,1);
    normVfixL = -1*(tcMat(:,3) - tcMat(:,1));
    
    simVfixR = tcMat(:,4) - tcMat(:,1);
    simVfixL = -1*(tcMat(:,5) - tcMat(:,1));    
    
    stabVfixR = tcMat(:,6) - tcMat(:,1);
    stabVfixL = -1*(tcMat(:,7) - tcMat(:,1));
    
%     normVsimR = tcMat(:,2) - tcMat(:,4);
%     normVsimL = -1*(tcMat(:,3) - tcMat(:,5));
    
    normVfixR = normVfixR.*backforw;
    normVfixL = normVfixL.*backforw;
    
    simVfixR = simVfixR.*backforw;
    simVfixL = simVfixL.*backforw;
    
    stabVfixR = stabVfixR.*backforw;
    stabVfixL = stabVfixL.*backforw;
    
    normVsimR = normVfixR - simVfixR;
    normVsimL = normVfixL - simVfixL;
    
    normVsim(i,:) = [normVsimR;normVsimL]';
    stabVfix(i,:) = [stabVfixR;stabVfixL]';
end

delete(wait_handle);

% 6) Calculate differences for real, recorded data
%    (organized in columns - F,NoL,SiL,StL,NoR,SiR,StR)
realtcm = comb_monks.tuncent_mat;

realnvfR = realtcm(:,5) - realtcm(:,1);
realnvfL = -1*(realtcm(:,2) - realtcm(:,1));

realsivfR = realtcm(:,6) - realtcm(:,1);
realsivfL = -1*(realtcm(:,3) - realtcm(:,1));

realsvfR = realtcm(:,7) - realtcm(:,1);
realsvfL = -1*(realtcm(:,4) - realtcm(:,1));

% realnvsR = realtcm(:,5) - realtcm(:,6);
% realnvsL = -1*(realtcm(:,2) - realtcm(:,3));

realnvfR = realnvfR.*backforw;
realnvfL = realnvfL.*backforw;

realsivfR = realsivfR.*backforw;
realsivfL = realsivfL.*backforw;

realsvfR = realsvfR.*backforw;
realsvfL = realsvfL.*backforw;

realnvsR = realnvfR - realsivfR;
realnvsL = realnvfL - realsivfL;

realnvs = [realnvsR;realnvsL];
realsvf = [realsvfR;realsvfL];

nonNanPairs = and(~isnan(realsvf),~isnan(realnvs));
[m,b] = lsqbisec(realnvs(nonNanPairs),realsvf(nonNanPairs));

% 7) Find p-values for recorded data
nvs = reshape(normVsim,numel(normVsim),1);
svf = reshape(stabVfix,numel(stabVfix),1);

nvsPvals = nan(2*numCells,1);
svfPvals = nan(2*numCells,1);

for i = 1:2*numCells
    nvsPvals(i) = 2*min([sum(realnvs(i)>nvs,'omitnan')/numel(nvs);...
                         sum(realnvs(i)<nvs,'omitnan')/numel(nvs)]);
    
    svfPvals(i) = 2*min([sum(realsvf(i)>svf,'omitnan')/numel(svf);...
                         sum(realsvf(i)<svf,'omitnan')/numel(svf)]);
end

sigNVSinds = and(nvsPvals<0.05,nonNanPairs);
sigSVFinds = and(svfPvals<0.05,nonNanPairs);

nvsNOTsvf = and(sigNVSinds,~sigSVFinds);
svfNOTnvs = and(sigSVFinds,~sigNVSinds);
nsJointInds = and(~sigNVSinds,~sigSVFinds);
sigJointInds = and(sigNVSinds,sigSVFinds);

% 8) Plot NS and significant datapoints

shiftcomp = figure;
shiftcomp.Position = [100 100 750 700];

hold on;
scatter(realnvs(nsJointInds),realsvf(nsJointInds),100,'filled','k');
scatter(realnvs(nvsNOTsvf),realsvf(nvsNOTsvf),100,'k','LineWidth',2);
scatter(realnvs(svfNOTnvs),realsvf(svfNOTnvs),100,'s','k','LineWidth',2);
scatter(realnvs(sigJointInds),realsvf(sigJointInds),200,'*','k','LineWidth',2);

plotLims = 90;
cax = gca;
cax.XLim = [-plotLims plotLims];
cax.YLim = [-plotLims plotLims];

set(gca,'FontSize',20);
a = gca;
a.YTick = -plotLims:30:plotLims;
a.XTick = -plotLims:30:plotLims;
a.XLim = [-plotLims,plotLims];
a.YLim = [-plotLims,plotLims];

plot([-plotLims plotLims],[-plotLims plotLims],'--k');
plot([-plotLims plotLims],[-plotLims*m plotLims*m],'--r');

xlabel('\Delta Preferred Heading (Normal - Simulated, \circ Az)','FontSize',20);
ylabel('\Delta Preferred Heading (Stabilized - Fixation, \circ Az)','FontSize',20);


