function plot_group_params(path,gain,offset,band,shift)

% Takes parameters collected with bh_grouptune2 and plots scatterplots &
% marginal histograms
%
% Usage: plot_group_params(poppath,gain,offset,band,shift)

% Load data & setup plotting

monoculo=0;
binoculo=0;

if exist([path,'monoc.mat'],'file')~=0
    load([path,'monoc'])
    monoculo=1;
elseif exist([path,'binoc.mat'],'file')~=0
    load([path,'binoc'])
    binoculo=1;
end

if exist([path,'scatterplots'],'dir')==0
    mkdir([path,'scatterplots']);
end

% should look through inputs 2:5, put if x==1, run monoc and binoc to
% optimize.

% Gain params

if gain
    if monoculo
        % Monoc
        plotparams(monoc,path,1);   % Method for popData class
    end
    
    if binoculo
        % Binoc
        plotparams(binoc,path,1);
    end
end

% Offset params

if offset
    if monoculo
        % Monoc
        plotparams(monoc,path,2);
    end
    
    if binoculo
        % Binoc
        plotparams(binoc,path,2);
    end
end

% Bandwidth params

if band
    if monoculo
        % Monoc
        plotparams(monoc,path,3);
    end
    
    if binoculo
        % Binoc
        plotparams(binoc,path,3);
    end
end

% Tuning Center

if shift
    if monoculo
        % Monoc
        plotparams(monoc,path,4);
    end
    
    if binoculo
        % Binoc
        plotparams(binoc,path,4);
    end
end

end