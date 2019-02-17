function [hStabLag] = pursStab(trial_ev,plotInd)

% Determine stabilization lag time with cross-correlation analysis
%
% Usage: [hStabLag] = pursStab(trial_ev,plotInd)

if ~isempty(plotInd)
    plotOn = 1;
else
    plotOn = 0;
end

kernel = 0.1*ones(10,1);
eyeVel = 10;

stabInds = arrayfun(@(x) x.pur_type == 3,trial_ev);
stabInds = find(stabInds == 1);

hStabLag = nan(numel(stabInds),1);
vStabLag = nan(numel(stabInds),1);

us = 1;

for j = 1:numel(stabInds)
    
    i = stabInds(j);
    
    %% Grab trial data
    h = trial_ev(i).eye_pos(1,:)';
    v = trial_ev(i).eye_pos(2,:)';
    t = trial_ev(i).eye_pos(3,:)';
    
    hCorr = trial_ev(i).az_corr_vals;
    vCorr = trial_ev(i).el_corr_vals;
    tCorr = trial_ev(i).evcorr_times;
    
    if trial_ev(i).pur_dir == 180
        velSign = -1;
    elseif trial_ev(i).pur_dir == 0
        velSign = 1;
    end
    
    % Eye position is zero-centered for whole of heading + pursuit epoch
    epochEnd = trial_ev(i).tr_ev_time(end);
    epochStart = trial_ev(i).tr_ev_time(end-1);
    epsilon = trial_ev(i).tr_ev_time(end-2);
    
    epochDur = (epochEnd - epochStart)/1000;
    epsilonDur = (epochStart - epsilon)/1000;
    
    offsetMag = eyeVel*(epochDur)/2;
    rampOffMag = eyeVel*(epsilonDur) + offsetMag;   
    
    %% Smooth and downsample eye position to framerate
    
    % Use 10ms box filter to find running average of eye position
    hConv = conv(h,kernel,'same');
    vConv = conv(h,kernel,'same');
    
    % Use went times as sample points
    wents = tCorr;
    tInd = find(t == wents(1));
    wentInds = wents + abs(wents(1)) + tInd;
    
    tDS = t(wentInds);
    hDS = hConv(wentInds);
    vDS = vConv(wentInds);
    
    %% Upsample stabilization vector to eye position sampling rate

    % Get interframe intervals
    framelengths = [diff(tCorr);8];
    
    hCorrUS = [];
    vCorrUS = [];
    
    for i = 1:numel(tCorr)
        numTpts = framelengths(i);
        hFrameCorr = hCorr(i)*ones(numTpts,1);
        vFrameCorr = vCorr(i)*ones(numTpts,1);
        
        hCorrUS = [hCorrUS;hFrameCorr];
        vCorrUS = [vCorrUS;vFrameCorr];
    end
    
    tCorrUS = [tCorr(1):1:(tCorr(end) + 7)]';
    
    %% Find correction lag with cross-correlation
    
    if us == 1
        % Align vectors
        wentOff = find(t == tCorr(1));
        h = h(wentOff:end);
        v = v(wentOff:end);
        t = t(wentOff:end);
        
        hCorr = hCorrUS;
        vCorr = vCorrUS;
        tCorr = tCorrUS;
        
        % Correction starts at single frame after start of epoch
        startInd = find(t == epsilon);% + 8;
    else
        h = hDS;
        v = vDS;
        t = tDS;
        
        % Allow for rounding error in 120Hz > integer period
        startInd = find(t == epsilon);% + 1;
        if isempty(startInd)
            test1 = find(t == epsilon + 1) + 1;
            test2 = find(t == epsilon + -1) + 1;
            test3 = [test1 test2];
            
            startInd = test3;
        end
    end
    
    if velSign == 1
%         hReoff = abs(min(h));
%         vReoff = abs(min(v));
        
        hReoff = -h(startInd);
        vReoff = -v(startInd);
    else
        hReoff = -max(h);
        vReoff = -max(v);
    end
 
    % Run cross-corr and find argmax
    h1 = [-(h(startInd) + hReoff)*ones(20,1);-(h(startInd:end) + hReoff);-(h(end) + hReoff)*ones(20,1)];
    h2 = [hCorr(startInd)*ones(20,1);hCorr(startInd:end);hCorr(end)*ones(20,1)];
    
    [hCrossCorrs,hLags] = ...
        xcorr(h1,h2,50);
    [vCrossCorrs,vLags] = ...
        xcorr(v + vReoff,-vCorr,50);
    
    [~,hMaxInd] = max(hCrossCorrs);
    [~,vMaxInd] = max(vCrossCorrs);
    
    hStabLag(j) = hLags(hMaxInd);
    vStabLag(j) = vLags(vMaxInd);
    
    %% Plot single trial
    if plotOn
        if j == plotInd
            
            f = figure;
            f.Position = [100 100 900 700];
            hold on;
            plot([t(1) t(end)],[0 0],'--k','LineWidth',1.5);
            
            % Pursuit Target Position
            plot([t(1) epsilon],[-velSign*offsetMag -velSign*offsetMag],'k','LineWidth',1.5);
            plot([epsilon t(end)],...
                [-velSign*rampOffMag (-velSign*rampOffMag + velSign*eyeVel*(epochDur + epsilonDur))],...
                'k','LineWidth',1.5);
            
            % Eye Position & Correction
            plot(tCorr,-hCorr + h(startInd),'LineWidth',2.5);
            plot(t,h,'LineWidth',2.5);
            text(0,0.5,['Stabilization lag: ',num2str(hStabLag(j)),'ms'],'FontSize',20);
            set(gca,'XLim',[t(1) t(end)],'YLim',[-6 6],'FontSize',20);
            ylabel('Horizontal Eye Position (\circ)');
            xlabel('Time from Self-motion Start (ms)');
            
            figure;
            hold on;
            plot(t,h + hReoff);
            plot(tCorr-hStabLag(j),-hCorr);
%             plot(h2);
            
            figure;
            plot(hLags,hCrossCorrs);
        end
    end
end

end

