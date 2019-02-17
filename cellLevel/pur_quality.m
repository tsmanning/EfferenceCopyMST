function [pursQual,idealvel] = pur_quality(path,targetmat,trial,plot_only)

% Trialwise pursuit quality measurements, should give the path for low
% level (i.e. setwise, not merged) BIGHEAD datasets
%
% Usage: [pursQual,went_times] = pur_quality(path,datamat,trial-to-plot)
%        [pursQual,went_times] = pur_quality('DAT_DIR/xbh_XXX/bh_tests/set1/','trial_ev',20,0)

% Get data, setup variables
s = load([path,targetmat,'.mat']);
s2 = struct2cell(s);
datamat = s2{1};
load([path,'trial_data.mat'])
load([path,'trials_ecad.mat'])
load([path,'ecad.mat'])
num_trials = numel(datamat);

if ~plot_only   % would be better to define pursQual object with plotting methods
    %% Setup variables
    positions = cell(numel(datamat),1);
    poserror = cell(numel(datamat),1);
    went_times = cell(numel(trials_ecad),1);
    
    purs_spd = round(trial_data.pursuit_speed);
    ideal2 = 0;
    idealvel = nan(numel(datamat),1);
    analyWindStart = nan(numel(datamat),2);
    pursGain = nan(numel(datamat),1);
    veldat = cell(numel(datamat),1);
    veldat_dsamp = cell(numel(datamat),1);
    vel_error = cell(numel(datamat),1);
    veldat_dsamp_incsacc = cell(numel(datamat),1);
    veldat2D = cell(numel(datamat),1);
    veldat_polar = cell(numel(datamat),1);
    num_saccades = nan(numel(datamat),1);
    
    % Eye data for each trial
    for i = 1:num_trials
        % Event code timepoints after start of dot translation
        tpts = datamat(i).tr_ev_time(4:end);
        
        %% Identify ideal eye movement parameters
        purs_type = datamat(i).pur_type;
        
        if datamat(i).pur_dir == 0 && datamat(i).pur_type ~= 2
            purs_dir = 1;
            idealvel(i) = 10;
            chkstart = datamat(i).tr_ev_time(6);
        elseif datamat(i).pur_dir == 180 && datamat(i).pur_type ~= 2
            purs_dir = -1;
            idealvel(i) = -10;
            chkstart = datamat(i).tr_ev_time(6);
        else
            % Fixation and simulated pursuit conditions
            purs_dir = 0;
            idealvel(i) = 0;
            chkstart = datamat(i).tr_ev_time(4);
        end
        
        analyWindStart(i,1) = chkstart;
        
        %% Get Eye Position Traces & Error
        % Generate vector of ideal eye positions throughout course of trial
        if purs_type == 0 || purs_type == 2
            % Fixation and simulated pursuit conditions
            ideal_heyepos = zeros(tpts(end)-tpts(1)+1,1);
            ideal_veyepos = zeros(tpts(end)-tpts(1)+1,1);
        else
            % Normal and Stabilized Pursuit
            purs_offset = ((tpts(end)-tpts(3))*purs_spd/1000)/2;
            posinc = purs_spd/1000;
            ideal_heyepos = purs_dir.*[zeros(1,tpts(3)-tpts(1)) ...
                (posinc:posinc:posinc*(tpts(end)-tpts(3)+1))]' - purs_dir*purs_offset;
            ideal_veyepos = zeros(tpts(end)-tpts(1)+1,1);
        end
        
        % Get eye positions from the start of simulated heading
        eye_posdat = datamat(i).eye_pos;
        init_tpt = -1*eye_posdat(3,1) + 1; % Index for start of trial
        
        heyepos = eye_posdat(1,init_tpt:end)';
        veyepos = eye_posdat(2,init_tpt:end)';
        eyepos_times = eye_posdat(3,init_tpt:end)';
        
        positions{i} = [heyepos veyepos eyepos_times];
        
        % Get raw position differences (change to only H + P epoch)
        herror = ideal_heyepos - heyepos;
        verror = ideal_veyepos - veyepos;
        
        poserror{i} = [herror verror];
        
        %% Estimate Eye Velocity Traces & Downsample to went frequency
        % Get screen display went times for each trial for downsampling
        bsearch = trials_ecad(1,i).Strind(1);
        esearch = trials_ecad(1,i).Strind(end);
        tstart = datamat(i).ev_time(4); % absolute times for Efile
        
        went_subinds = int32(find(ecad.Values(bsearch:esearch) == 1509));
        went_times{i,1} = ecad.Times(went_subinds + bsearch);
        went_times{i,1} = went_times{i,1} - tstart;
        
        % Get eye velocity estimates using Rex's algorithm (calculated velocity
        % estimates at any one time point actually report velocity 2ms in past)
        % (1000/6 = 1/2 tpts * 1/3 tpts * 1000 ms/1 sec)
        heyevel = (1000/6) * (heyepos(5:end) + heyepos(4:end-1) - ...
            heyepos(2:end-3) - heyepos(1:end-4));
        veyevel = (1000/6) * (veyepos(5:end) + veyepos(4:end-1) - ...
            veyepos(2:end-3) - veyepos(1:end-4));
        eyevel_times = eyepos_times(5:end); % change to (3:end-2) to remove lag
        veldat{i} = [heyevel veyevel eyevel_times];
        
        % Use bighead's sliding average (window trails current position
        % by 10ms, inclusive) to smooth eye velocity estimates
        heyevel_smooth = movmean(heyevel,[9 0]);
        veyevel_smooth = movmean(veyevel,[9 0]);
        
        % Downsample velocity estimates to match frame updates on screen
        wents = went_times{i};
        went_startind = find(wents == 0) + 1;       % Get second went
        went_inds = wents(went_startind:end) - 3;   % convert went times to inds
        heyevel_downsamp = heyevel_smooth(went_inds);    % Downsample vel estimates
        veyevel_downsamp = veyevel_smooth(went_inds);    % Downsample vel estimates
        
        %% Saccade Detection & Removal from velocity data
        eyevel_polarmag = sqrt(heyevel_downsamp.^2 + veyevel_downsamp.^2);
        eyevel_polardir = atan2(veyevel_downsamp,heyevel_downsamp);
        
        thresh_test = 3*std(eyevel_polarmag);  % pretty liberal criteron
        % Set threshold for saccade detection, select greater of 2SD or 20deg/s
        if thresh_test > 25
            sacc_thresh = thresh_test;
        else
            sacc_thresh = 25;
        end
        
        % ID inds that contain saccades (add vel offset for H+P epoch inds?)
        % (different regime used for cutting spikes in saccade spikes)
        sacc_inds = find(eyevel_polarmag >= sacc_thresh);
        
        veltimes = double(went_inds + 3);         % Convert inds back to times
        veldat_dsamp_incsacc{i} = [heyevel_downsamp veyevel_downsamp veltimes];
        veldat_polar{i} = [eyevel_polarmag eyevel_polardir veltimes];
        veldat2D{i} = [veltimes eyevel_polarmag];
        
        % Convert indices with saccades to nans
        heyevel_downsamp(sacc_inds) = nan;
        veyevel_downsamp(sacc_inds) = nan;
        eyevel_polarmag(sacc_inds) = nan;
        
        veldat2D{i} = [veldat2D{i} eyevel_polarmag];   % Slap desaccaded data onto side for plotting
        veldat_dsamp{i} = [heyevel_downsamp veyevel_downsamp veltimes];
        
        %% Raw velocity error
        if idealvel(i) ~= 0
            % Normal and Stabilized Trials
            start_chkind = find(veltimes == chkstart);
            
            heyevel_error = [zeros(start_chkind - 1,1); ...
                idealvel(i)*ones(length(heyevel_downsamp) - start_chkind + 1,1)] - heyevel_downsamp;
            veyevel_error = 0 - veyevel_downsamp;
            
            vel_error{i} = [heyevel_error veyevel_error veltimes];
            
            pursGain(i) = nanmean(heyevel_downsamp(start_chkind:end))*(purs_dir/purs_spd);
        else
            % Fixation and Simulated
            start_chkind = veltimes(1);
            
            heyevel_error = 0 - heyevel_downsamp;
            veyevel_error = 0 - veyevel_downsamp;
            
            vel_error{i} = [heyevel_error veyevel_error veltimes];
        end
        
        analyWindStart(i,2) = start_chkind;
        
        %% Count number of saccades AFTER start of pursuit (or trial start for fixation trials)
        hp_saccs = sacc_inds(sacc_inds > start_chkind);
        
        dsac = diff(hp_saccs);          % Find contiguous inds over sacc thresh
        dsac2 = diff(dsac);
        
        t1 = numel(find(dsac == 1));    % if inds dip below thresh for a bit,
        t2 = numel(find(dsac == 0));
        
        num_saccades(i) = numel(hp_saccs) - t1 - t2;
        
        %% Get saccade parameters (peak velocity, direction) (+duration?)
        
        % find peaks of individual saccade events
        % get direction from atan(V_vert/V_horiz), accounting for quadrant issues
    end
    
    %% Get RMS position error across all trials
    
    
    %% Get RMS velocity error across all trials
    %%%%%%%%%%%% (NEED TO SEPARATE OUT FIXATION AND PURSUIT TRIALS)
    rms_funch = @(velerror) sqrt(nanmean(velerror(:,1).^2));
    rms_funcv = @(velerror) sqrt(nanmean(velerror(:,2).^2));
    rms_func2D = @(velerror) sqrt(nanmean(velerror(:,1).^2 + velerror(:,1).^2));
    rms_velerror = cellfun(rms_func2D,vel_error);
    rms_hvelerror = cellfun(rms_funch,vel_error);
    rms_vvelerror = cellfun(rms_funcv,vel_error);
    
    signed_herror = @(velerror) nanmean(velerror(:,1));
    signed_verror = @(velerror) nanmean(velerror(:,2));
    signed_hvelerror = cellfun(signed_herror,vel_error);
    signed_vvelerror = cellfun(signed_verror,vel_error);
    
    %% Collect data into structure and save
    
    pursQual = struct;
    pursQual.analyWindStart = analyWindStart;
    pursQual.wentTimes = went_times;
    pursQual.pos = positions;
    pursQual.poserror = poserror;
    pursQual.veldata = veldat;
    pursQual.veldatPolar = veldat_polar;
    pursQual.veldatDsamp = veldat_dsamp_incsacc;
    pursQual.veldatDsampDesacc = veldat_dsamp;
    pursQual.numSaccades = num_saccades;
    pursQual.velerrorTimeseries = vel_error;
    pursQual.rmsVelError = [rms_hvelerror rms_vvelerror];
    pursQual.signedVelError = [signed_hvelerror signed_vvelerror];
    pursQual.gain = pursGain;
    
    save([path,'pursQual'],'pursQual');
end

%% Plot
if ~isempty(trial)
    % Plot test trial
    % trial = 1;
    test = veldat_dsamp{trial};
    test_sacc = veldat_dsamp_incsacc{trial};
    
    a = positions{trial};
    figure;
    set(gcf,'Position',[50 500 550 500]);
    plot(a(:,1),a(:,2));
    set(gca,'XLim',[-6 6],'YLim',[-6 6]);
    title('Eye Position');
    
    figure;
    subplot(2,1,1);
    set(gcf,'Position',[650 500 550 500]);
    hold on;
    plot(test_sacc(:,3)-558,test_sacc(:,1),'r');
    plot(test(:,3)-558,test(:,1));
    plot([test(1,3):1:test(end,3)]-558,[zeros(test(end,3)-test(1,3)-849,1);...
        idealvel(trial)*ones(850,1)],'k');
    title('Horizontal Eye Velocity');
    ylabel('Velocity (deg/s)');
    xlabel('Time from Start of Pursuit Epoch (ms)');
    
    subplot(2,1,2);
    hold on;
    plot(test_sacc(:,3)-558,test_sacc(:,2),'r');
    plot(test(:,3)-558,test(:,2));
    plot([test(1,3):1:test(end,3)]-558,zeros(test(end,3)-test(1,3)+1,1),'k');
    title('Vertical Eye Velocity');
    ylabel('Velocity (deg/s)');
    xlabel('Time from Start of Pursuit Epoch (ms)');
    
    vel2d = veldat2D{trial};
    figure;
    hold on;
    set(gcf,'Position',[650 50 550 320]);
    plot(vel2d(:,1)-558,vel2d(:,2),'r');
    plot(vel2d(:,1)-558,vel2d(:,3));
    set(gca,'YLim',[0 1.2*max(max(vel2d(:,2:3)))]);
    title('Two-Dimensional Unsigned Eye Velocity');
    ylabel('Velocity (deg/s)');
    xlabel('Time from Start of Pursuit Epoch (ms)');
    
    % Histograms of estimated de-saccaded velocity
    x = test;
    bin_width = 2;
    edgebound = round(max(max(abs(x(66:end,1:2)))),-1);
    edges = -edgebound:bin_width:edgebound;
    
    figure;
    set(gcf,'Position',[1300 600 550 400]);
    hold on;
    h1 = histogram(x(66:end,1),edges);
    datmean = nanmean(x(66:end,1));
    histmax = max(h1.Values,[],'omitnan')*1.1;
    minbin = min(h1.BinEdges);
    maxbin = max(h1.BinEdges);
    plot([idealvel(trial) idealvel(trial)],[0 histmax],'--k');
    plot([datmean datmean],[0 histmax],'--r');
    set(gca,'XLim',[minbin*1.1 maxbin*1.1],'YLim',[0 histmax]);
    ylabel('Number of Occurrences');
    xlabel('Velocity Estimates (deg/s)');
    title('Eye Velocity (Horizontal Component)');
    
    figure;
    set(gcf,'Position',[1300 70 550 400]);
    hold on;
    h2 = histogram(x(66:end,2),edges);
    datmean2 = nanmean(x(66:end,2));
    histmax2 = max(h2.Values,[],'omitnan')*1.1;
    minbin2 = min(h2.BinEdges);
    maxbin2 = max(h2.BinEdges);
    plot([ideal2 ideal2],[0 histmax2],'--k');
    plot([datmean2 datmean2],[0 histmax2],'--r');
    set(gca,'XLim',[minbin2*1.1 maxbin2*1.1],'YLim',[0 histmax2]);
    ylabel('Number of Occurrences');
    xlabel('Velocity Estimates (deg/s)');
    title('Eye Velocity (Vertical Component)');
    
    figure;
    histogram(num_saccades,max(num_saccades));
    title('Number of Saccades per Trial');
    ylabel('Number of Trials');
    xlabel('Number of Saccades Detected');
    
    % Gain quality histograms (NEED TO SEPARATE OUT FIXATION AND PURSUIT
    % TRIALS)
    figure;
    subplot(2,1,1);
    hold on;
    hand_herror = histogram(signed_hvelerror);
    histmax3 = max(hand_herror.Values,[],'omitnan')*1.1;
    mean_hvelerror = mean(signed_hvelerror);
    plot([mean_hvelerror mean_hvelerror],[0 histmax3],'--r');
    title('Trialwise Pursuit Gain Error (Horizontal Component)');
    ylabel('Number of Trials');
    xlabel('Velocity Error (deg/s)');
    
    subplot(2,1,2);
    hold on;
    hand_verror = histogram(signed_vvelerror);
    histmax4 = max(hand_verror.Values,[],'omitnan')*1.1;
    mean_vvelerror = mean(signed_vvelerror);
    plot([mean_vvelerror mean_vvelerror],[0 histmax4],'--r');
    title('Trialwise Pursuit Gain Error (Vertical Component)');
    ylabel('Number of Trials');
    xlabel('Velocity Error (deg/s)');
    
    minbinerror = min([hand_verror.BinEdges hand_herror.BinEdges]);
    maxbinerror = max([hand_verror.BinEdges hand_herror.BinEdges]);
    
    subplot(2,1,1);
    %     set(gca,'XLim',[minbinerror maxbinerror],'YLim',[0 max([histmax3 histmax4])]);
    set(gca,'XLim',[-5 5],'XTick',-5:1:5,'YLim',[0 max([histmax3 histmax4])]);
    subplot(2,1,2);
    %     set(gca,'XLim',[minbinerror maxbinerror],'YLim',[0 max([histmax3 histmax4])]);
    set(gca,'XLim',[-5 5],'XTick',-5:1:5,'YLim',[0 max([histmax3 histmax4])]);
end

end