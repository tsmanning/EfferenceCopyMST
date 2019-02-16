function [isi_hist,edges,autoCorr,lags] = neuron_stats(path,test_set,folder,titlename,plot_suppress)

% Calculate ISI distribution, spike vector autocorrelation
% Usage: [ISIs,edges,bh_spikes,pt_vec,ht_vec]=neuron_stats(path,test_set,folder,titlename)

if test_set~=0 && ischar(test_set)==0
    set_no = num2str(test_set);
    set_dir = ['/set',set_no,'/'];
elseif test_set==0
    set_dir = '/';
end

load([path,'/',folder,set_dir,'spikes']);

% Remove start time offset + convert to binary time vector

spikes = spikes-spikes(1)+1;

spike_vec = zeros(1,spikes(end));
for a = 1:length(spikes)
    spike_vec(spikes(a)) = 1;
end

% Calculate ISIs and plot distribution

ISIs = diff(spikes);
edges = linspace(0,1000,1001);

figgo = figure;
isi_hist = histogram(ISIs,edges);

set(gca,'XLim',[0 150],'XTick',0:25:150,'Box','off','FontSize',20);
title(['ISI Distribution (',titlename,')'],'FontSize',20);
xlabel('Interspike Intervals (msec)','FontSize',20);
ylabel('Number of Observations','FontSize',20);

if ~plot_suppress
    hgsave(figgo,[path,'/',folder,'/',set_dir,'/ISI_dist']);
else
    close(figgo)    % need to save histogram, but don't want plot - cludgy
end

% Calculate autocorrelation and plot

[autoCorr,lags] = xcorr(spike_vec,200,'coeff');
autoCorr(1,201) = 0;

lockout_val = autoCorr(1,202);
farshift_val = mean(autoCorr(1,216:256));
lockout_ratio = lockout_val/farshift_val;

if ~plot_suppress
    figgo2 = figure;
    bar(lags,autoCorr,'hist');
    
    set(gca,'XLim',[-15 15],'XTick',-15:1:15,'YLim',[0 0.25],'YTick',0:.05:0.25,'Box','off','FontSize',20);
    set(gcf,'Position',[10 550 1900 400]);
    title(['Autocorrelation (',titlename,'; lockout ratio=',num2str(lockout_ratio),')'],'FontSize',15);
    xlabel('Lag (msec)','FontSize',20);
    ylabel('Normalized Correlation','FontSize',20);
    
    hgsave(figgo2,[path,'/',folder,'/',set_dir,'/autocorr']);
end

neuron_statistics = struct;
neuron_statistics.lockout_ratio = lockout_ratio;
neuron_statistics.autoCorr = autoCorr;
neuron_statistics.lags = lags;
neuron_statistics.isi_hist = isi_hist;
neuron_statistics.edges = edges;

save([path,'/',folder,set_dir,'neuron_statistics'],'neuron_statistics');

end