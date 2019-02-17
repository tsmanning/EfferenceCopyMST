function [data_params,mdot_data] = multidot_extraction(path,rawdatafile_prefix,plot_suppress)

% Extracts raw multidot data using Dan's ecp script and does initial
% processing/plotting of data
%
% Usage: [data_params,spikes,ecad] = multidot_extraction(path,rawdatafile_prefix)


% In spiral space, 0deg is CCW rotation, 90deg is expansion, 180deg is
% CW rotation, 270deg is contraction, and angles in between are spiral
% combinations of radial and rotation about an axis normal to the screen.

% Use ecfile/ECAData from bighead pipeline to grab ecodes and
% timepoints
EFILE = [path,rawdatafile_prefix,'E'];
e = ecfile(EFILE);
ecad = ECAData(get(e, 'Times'), get(e, 'Channels'), get(e, 'Values'));

% Get spikes
spikeinds = find(ecad.Values == 601);
spikes = ecad.Times(spikeinds) - ecad.Times(1);

% Get stimulus parameters for session
headflag = find(ecad.Values == 1499);

% Need to remove any spikes that trickled in during header stream
% (22 ecodes long)
chkhead = ecad.Values(headflag+1:headflag+22);
headspks = find(chkhead == 601);

if ~isempty(headspks)
    numheadspks = numel(headspks);
    chkhead(headspks) = nan;
    begind = headflag + 23;
    endind = headflag + 22 + numheadspks;
    
    while numheadspks ~= 0
        % Tack on ecodes equal to number of spikes past header flag + 22
        chkhead2 = ...
            [chkhead; ecad.Values(begind:endind)];
        
        % Check if any of these have spikes too. If so rinse & repeat.
        headspks = find(chkhead2 == 601);
        numheadspks = numel(headspks);
        chkhead2(headspks) = nan;
        
        chkhead = chkhead2;
        begind = endind + 1;
        endind = endind + numheadspks;
    end
end

head_codes = chkhead(~isnan(chkhead)) - 1500;

data_params = struct;
data_params.fixpt_x = head_codes(1);
data_params.fixpt_y = head_codes(2);
data_params.stimcent_x = head_codes(3);
data_params.stimcent_y = head_codes(4);
data_params.stim_radius = head_codes(5);
data_params.screen_dist = head_codes(6);
data_params.spiral_angs = ...
    linspace(head_codes(7),head_codes(8),head_codes(9));
data_params.linear_angs = ...
    linspace(head_codes(10),head_codes(11),head_codes(12));
data_params.dot_speed = head_codes(13);
data_params.dot_density = head_codes(14);
data_params.dot_size = head_codes(15);
data_params.coherence = head_codes(16);
data_params.foreground_greyval = head_codes(17);
data_params.background_greyval = head_codes(18);
data_params.stim_per_trial = head_codes(19);
data_params.trial_duration = head_codes(20);
data_params.ISI = head_codes(21);
data_params.day_seed = head_codes(22);

% Get stimulus timing data
times = ecad.Times - ecad.Times(1);

trial_starts = times(ecad.Values==1166);
trial_ends = times(ecad.Values==1030); % use reward ecode as marker of
% successful trials
stim_ons = times(ecad.Values==1161);
stim_offs = times(ecad.Values==1162);

% Get trial-specific ecodes (linear, spiral, or blank)
trcodes = unique(ecad.Values);
linear_codes = trcodes(trcodes>=3000 & trcodes<3500);
spiral_codes = trcodes(trcodes>=3500 & trcodes<4000);
if numel(linear_codes) > head_codes(12)
    blank_code = linear_codes(head_codes(12)+1:end);
    linear_codes = linear_codes(1:head_codes(12));
end

% Find stimulus presentation epochs where fixation was maintained
% i.e. where stim_off ecode follows stim_on within set trial duration
comp_trials = zeros(numel(stim_ons),1,'logical');
for i = 1:numel(stim_ons)
    stoff_theo = stim_ons(i) + data_params.trial_duration;
    
    stoff_chk = stim_offs>stim_ons(i) & stim_offs<stoff_theo;
    if sum(stoff_chk) ~= 0
        comp_trials(i) = 1;
    end
end

comp_stim_on = stim_ons(comp_trials);
num_comp_stim = sum(comp_trials);

% Stim type ecode always leads stim on ecode by two indices w/o spikes
ecodes = ecad.Values(ecad.Values~=601);
temp = find(ecodes==1161);
stim_types = ecodes(temp(comp_trials) - 2);

% Get stim-wise info
types = nan(num_comp_stim,1);
dirs = nan(num_comp_stim,1);
spiketimes = cell(num_comp_stim,1);
spikecounts = nan(num_comp_stim,1);

for i = 1:num_comp_stim
    if stim_types(i)>=3500
        types(i) = 2;
        stimind = stim_types(i)-spiral_codes(1)+1;
        dirs(i) = data_params.spiral_angs(stimind);
    elseif stim_types(i)<3500 && stim_types(i)~=blank_code
        types(i) = 1;
        stimind = stim_types(i)-linear_codes(1)+1;
        dirs(i) = data_params.linear_angs(stimind);
    elseif stim_types(i)==blank_code
        types(i) = 0;
        dirs(i) = -1;
    end
    spiketimes{i} = spikes(spikes>=comp_stim_on(i)+40 & ...
        spikes<comp_stim_on(i)+540);
    spikecounts(i) = numel(spiketimes{i});
end

% Sort by unique trial
mdot_data = struct;

[unitypes,~,inds] = unique([types dirs],'rows');

for i = 1:size(unitypes,1)
    mdot_data(i).trial_type = unitypes(i,1);
    mdot_data(i).trial_dir = unitypes(i,2);
    
    unitypeinds = inds==i;
    mdot_data(i).spiketimes = spiketimes(unitypeinds);
    mdot_data(i).spikecounts = spikecounts(unitypeinds);
    mdot_data(i).stim_starts = comp_stim_on(unitypeinds);
    mdot_data(i).stim_ends = stim_offs(unitypeinds);
end

FR_sums = arrayfun(@(x) sum(x.spikecounts),mdot_data);
FR_nums = arrayfun(@(x) numel(x.spikecounts),mdot_data);
FR_means = FR_sums./FR_nums;

linear_means = FR_means(unitypes(:,1)==1);
spiral_means = FR_means(unitypes(:,1)==2);
blank_mean = FR_means(unitypes(:,1)==0);

data_params.linear_means = linear_means;
data_params.spiral_means = spiral_means;
data_params.blank_mean = blank_mean;

% Cosine-weighted Direction Selectivity Index
DSI = nan(2,1);
x = {'linear_means','spiral_means'};
y = {'linear_angs','spiral_angs'};

for i = 1:2 % loop though linear/spiral measures
    [max_resp,max_resp_ang] = max(data_params.(x{i}));
    means_norm = data_params.(x{i})/max_resp;
    angs = data_params.(y{i})*(pi/180);
    
    theta_pref = angs(max_resp_ang);
    
    delta_theta = theta_pref - angs;
    neginds = find(delta_theta<0);
    delta_theta(neginds) = delta_theta(neginds) + 2*pi;
    dsi_func = @(R,Dtheta) 1 - sum(R.*((1-cos(Dtheta))))./numel(R);
    
    DSI(i) = dsi_func(means_norm,delta_theta);
end

% Pref/Null Direction Tuning Index
DTI = nan(2,1);

for i = 1:2
    % probably want to fix this to match circular mean and 180deg response
    % or just max and 180 deg response, rather than assuming min is 180 deg
    % separated.
    max_resp = max(data_params.(x{i}));
    min_resp = min(data_params.(x{i}));
    
    DTI(i) = (max_resp - min_resp)/(max_resp + min_resp);
end

if ~plot_suppress
    % Plot tested location on screen and cell tunings
    
    f1 = figure;
    set(gcf,'Position',[40 250 820 520]);
    angs = 0:pi/50:2*pi;
    radius = data_params.stim_radius/10;
    stim_centx = data_params.stimcent_x/10;
    stim_centy = data_params.stimcent_y/10;
    plot(radius*cos(angs) + stim_centx,radius*sin(angs) + stim_centy,'--k');
    set(gca,'XLim',[-50 50],'YLim',[-35 35]);
    
    f2 = figure;
    set(gcf,'Position',[905 220 500 500]);
    p1 = polar([data_params.linear_angs data_params.linear_angs(1)]*(pi/180),...
        [linear_means linear_means(1)],'k');
    newpolartix(8,p1);
    % p2 = polar([data_params.linear_angs data_params.linear_angs(1)],...
    %       blank_mean*ones(1,numel(data_params.linear_angs)+1));
    % newpolartix(8,p2);
    title('Linear Motion Tuning');
    set(findall(gcf,'type','text'),'visible','on'); % why doesn't this line work in newpolartix??
    annotation(gcf,'textbox',[0.55 0.08 0.45 0.047],'Color',[0 0 0],...
        'String',['DSI = ',num2str(DSI(1))],'FontSize',20,...
        'FitBoxToText','off','LineStyle','none');
    annotation(gcf,'textbox',[0.05 0.08 0.45 0.047],'Color',[0 0 0],...
        'String',['DTI = ',num2str(DTI(1))],'FontSize',20,...
        'FitBoxToText','off','LineStyle','none');
    
    f3 = figure;
    set(gcf,'Position',[1415 250 500 500]);
    p3 = polar([data_params.spiral_angs data_params.spiral_angs(1)]*(pi/180),...
        [spiral_means spiral_means(1)],'k');
    newpolartix(8,p3);
    % p4 = polar([data_params.spiral_angs data_params.spiral_angs(1)]*(pi/180),...
    %       blank_mean*ones(1,numel(data_params.spiral_angs)+1),'--k');
    % newpolartix(8,p4);
    title('Spiral Space Tuning');
    set(findall(gcf,'type','text'),'visible','on'); % why doesn't this line work in newpolartix??
    annotation(gcf,'textbox',[0.55 0.08 0.45 0.047],'Color',[0 0 0],...
        'String',['DSI = ',num2str(DSI(2))],'FontSize',20,...
        'FitBoxToText','off','LineStyle','none');
    annotation(gcf,'textbox',[0.05 0.08 0.45 0.047],'Color',[0 0 0],...
        'String',['DTI = ',num2str(DTI(2))],'FontSize',20,...
        'FitBoxToText','off','LineStyle','none');
end

% Save data
save([path,'data_params'],'data_params');
save([path,'mdot_data'],'mdot_data');
save([path,'spikes'],'spikes');

if ~plot_suppress
    hgsave(f1,[path,'stimulus_location']);
    hgsave(f2,[path,'linear_tuning']);
    hgsave(f3,[path,'spiral_tuning']);
end

end
