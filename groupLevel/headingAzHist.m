function [f1,muAng] = headingAzHist(dataDir) 
% Plot histogram of tested heading angles (azimuth)
%dataDir = '/home/tyler/matlab/data/combined_monks/';
load([dataDir,'comb_params.mat']);
load([dataDir,'comb_monks.mat']);

numCells = numel(comb_params);

views = arrayfun(@(x) ~isempty(x.monoc),comb_params);
views = double(views);
views(views==0) = 2;
viewName = {'monoc','binoc'};

% Grab all heading azimuth angles tested in across all cells
% a = arrayfun(@(x) x.angles,cellData,'UniformOutput',false);
c = [];

for i = 1:numCells
    viewtemp = viewName{views(i)};
    angles = comb_params(i).(viewtemp).azimuth;
    
    % Hack to ignore non-unique angles cause by round off errors
    tempAng = diff(angles);
    temp2 = find(tempAng<(pi/180));
    if ~isempty(temp2)
        keepInds = ones(numel(angles),1,'logical');
        keepInds(temp2 + 1) = false;
        angles = angles(keepInds);
    end
    
    c = [c;angles];
end

% Reclassify angles in 0:360 range
c(c>360) = c(c>360) - 360;
c(c<0) = c(c<0) + 360;

% Shift coordinates to -180:180
c(c>180)  = c(c>180) - 360;

cinds = and(c~=0,c~=180);
cinds = and(cinds,c~=-180);

c = c(cinds);

% Get circular average
ax = sin(c*(pi/180));
ay = cos(c*(pi/180));

muAx = mean(ax);
muAy = mean(ay);

muAng = atan(muAx/muAy)*(180/pi);

f1 = figure;
hold on;
h = histogram(c,'BinWidth',20);
set(gca, 'xtick',-180:30:180);

ub = max(h.Values);
plot([muAng muAng],[0 ub*1.1],'--k');
end