function collectfigs(path,meanstd,fits)

poppath = [path,'population_data/'];

load([poppath,'included_cells.mat'])
cells = included_cells(:,1);

% Tuning curves (mean+std)
if meanstd
    if exist([poppath,'mean_std/'],'dir') == 7
%         rmdir([poppath,'mean_std/'],'s');
%         
%         mkdir([poppath,'mean_std/figs/']);
%         mkdir([poppath,'mean_std/svg/']);
%         mkdir([poppath,'mean_std/png/']);
    else
        mkdir([poppath,'mean_std/figs/']);
        mkdir([poppath,'mean_std/svg/']);
        mkdir([poppath,'mean_std/png/']);
    end
    
    for i = 22:55%numel(cells)
        if exist([path,'/',cells{i},'/bh_tests/set_merge_monoc/'],'dir') == 7
            meanfig = openfig([path,'/',cells{i},'/bh_tests/set_merge_monoc/tuning_maps.fig']);
            set(gcf,'Position',[0 50 1800 900]);
            img = getframe(meanfig);
            
            hgsave(meanfig,[poppath,'mean_std/figs/',cells{i},'_monoc']);
            saveas(gcf,[poppath,'mean_std/svg/',cells{i},'_monoc.svg']);
            imwrite(img.cdata,[poppath,'mean_std/png/',cells{i},'_monoc.png']);
            close(meanfig);
        elseif exist([path,'/',cells{i},'/bh_tests/set_merge_binoc/'],'dir') == 7
            meanfig = openfig([path,'/',cells{i},'/bh_tests/set_merge_binoc/tuning_maps.fig']);
            set(gcf,'Position',[0 50 1800 900]);
            img = getframe(meanfig);
            
            hgsave(meanfig,[poppath,'mean_std/figs/',cells{i},'_binoc']);
            saveas(gcf,[poppath,'mean_std/svg/',cells{i},'_binoc.svg']);
            imwrite(img.cdata,[poppath,'mean_std/png/',cells{i},'_binoc.png']);
            close(meanfig);
        end
    end
end

% Data fits
if fits
    if ~exist([poppath,'data_fits/'],'dir')
        mkdir([poppath,'data_fits/figs/']);
        mkdir([poppath,'data_fits/svg/']);
        mkdir([poppath,'data_fits/png/']);
    end
    
    for i = 1:55%numel(cells)
        if exist([path,'/',cells{i},'/bh_tests/set_merge_monoc/'],'dir')==7
            fitfig = openfig([path,'/',cells{i},...
                '/bh_tests/set_merge_monoc/data_fits/fitted_tuning.fig']);
            set(gcf,'Position',[0 50 1800 900]);
            img = getframe(fitfig);
            
            hgsave(fitfig,[poppath,'data_fits/figs/',cells{i},'_monoc']);
            saveas(fitfig,[poppath,'data_fits/svg/',cells{i},'_monoc.svg']);
            imwrite(img.cdata,[poppath,'data_fits/png/',cells{i},'_monoc.png']);
            close(fitfig);
        elseif exist([path,'/',cells{i},'/bh_tests/set_merge_binoc/'],'dir')==7 && ...
              ~exist([path,'/',cells{i},'/bh_tests/set_merge_monoc/'],'dir')
            fitfig = openfig([path,'/',cells{i},...
                '/bh_tests/set_merge_binoc/data_fits/fitted_tuning.fig']);
            set(fitfig,'Position',[0 50 1800 900]);
            img = getframe(fitfig);
            
            hgsave(fitfig,[poppath,'data_fits/figs/',cells{i},'_binoc']);
            saveas(fitfig,[poppath,'data_fits/svg/',cells{i},'_binoc.svg']);
            imwrite(img.cdata,[poppath,'data_fits/png/',cells{i},'_binoc.png']);
            close(fitfig);
        end
        
    end
end

end