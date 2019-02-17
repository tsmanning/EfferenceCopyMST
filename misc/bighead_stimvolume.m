function [stimfig] = bighead_stimvolume(num_dots,dot_size,single_plane,plane,invert_color,annot_on,cond)

% Generates figure showing simulated dot volume.
%
% Usage: [stimfig] = bighead_stimvolume(num_dots,single_plane,plane,invert_color,annot_on,cond)
%                    bighead_stimvolume(3500,0:1,50:150,0:1,0:1,0:3)

near_plane = 50;
far_plane = 150;
screen_dist = 50;
screen_hfov = 50*(pi/180); % FOV/2 in rads VA
screen_vfov = 34*(pi/180); % FOV/2 in rads VA

depths = near_plane:far_plane;
hdims = floor(depths.*tan(screen_hfov));     % distance FROM HM/VM, total
vdims = floor(depths.*tan(screen_vfov));     % width/height is 2X + 1

numels = (hdims*2 + 1).*(vdims*2 + 1);
total_numinds = sum(numels);  % ~1000x number of dots on screen

% Generate array of all voxels in visible volume
X = nan(total_numinds,1);
Y = nan(total_numinds,1);
Z = nan(total_numinds,1);
start_inds = [1,(1 + cumsum(numels(1:end-1)))];
end_inds = cumsum(numels);

for i = 1:numel(depths)   % generate x,y,z coords for each depth plane
    num_inds = (hdims(i)*2 + 1)*(vdims(i)*2 + 1);
    xinds = [-hdims(i):hdims(i)]';
    yinds = [-vdims(i):vdims(i)]';
    
    X(start_inds(i):end_inds(i),1) = repelem(xinds,numel(yinds));
    Y(start_inds(i):end_inds(i),1) = repmat(yinds,[numel(xinds) 1]);
    Z(start_inds(i):end_inds(i),1) = depths(i).*ones(num_inds,1);
end

% Plot figure
dot_contrast = 0.5; % [0,1]

stimfig = figure;
set(gcf,'Position',[50 50 1015 900]);
hold on;

if invert_color
    set(gcf,'Color',[0 0 0]);
    
    annot_color = [1 1 1];
    dot_color = [dot_contrast,dot_contrast,dot_contrast];
    line_color = 'w';
    line_color_dash = '--w';
else
    set(gcf,'Color',[1 1 1]);
    
    annot_color = [0 0 0];
    dot_color = [1-dot_contrast,1-dot_contrast,1-dot_contrast];
    line_color = 'k';
    line_color_dash = '--k';
end

% Outline screen edges
plot3([50 50],[-hdims(1) hdims(1)],[-vdims(1) -vdims(1)],line_color,'LineWidth',2);
plot3([50 50],[-hdims(1) hdims(1)],[vdims(1) vdims(1)],line_color,'LineWidth',2);
plot3([50 50],[-hdims(1) -hdims(1)],[-vdims(1) vdims(1)],line_color,'LineWidth',2);
plot3([50 50],[hdims(1) hdims(1)],[-vdims(1) vdims(1)],line_color,'LineWidth',2);

% Outline far plane edges
plot3([150 150],[-hdims(end) hdims(end)],[-vdims(end) -vdims(end)],line_color_dash);
plot3([150 150],[-hdims(end) hdims(end)],[vdims(end) vdims(end)],line_color_dash);
plot3([150 150],[-hdims(end) -hdims(end)],[-vdims(end) vdims(end)],line_color_dash);
plot3([150 150],[hdims(end) hdims(end)],[-vdims(end) vdims(end)],line_color_dash);

% Outline connecting edges
plot3([50 150],[-hdims(1) -hdims(end)],[-vdims(1) -vdims(end)],line_color_dash);
plot3([50 150],[hdims(1) hdims(end)],[vdims(1) vdims(end)],line_color_dash);
plot3([50 150],[-hdims(1) -hdims(end)],[vdims(1) vdims(end)],line_color_dash);
plot3([50 150],[hdims(1) hdims(end)],[-vdims(1) -vdims(end)],line_color_dash);

% Plot dots in single plane or in volume
if ~single_plane
    rand_inds = randperm(total_numinds,num_dots);
    
    x = X(rand_inds);
    y = Y(rand_inds);
    z = Z(rand_inds);
    scatter3(z,x,y,dot_size,dot_color,'filled');
%     scatter3(z,x,y,10,dot_color,'.');
elseif single_plane
    plind = plane - 49;
    
    rand_inds = randperm(numels(plind),num_dots);
    
    x = X(rand_inds + start_inds(plind));
    y = Y(rand_inds + start_inds(plind));
    z = Z(rand_inds + start_inds(plind));
    scatter3(z,x,y,dot_size,dot_color,'filled');
    
    % Outline desired plane
    plot3([plane plane],[-hdims(plind) hdims(plind)],[-vdims(plind) -vdims(plind)],line_color);
    plot3([plane plane],[-hdims(plind) hdims(plind)],[vdims(plind) vdims(plind)],line_color);
    plot3([plane plane],[-hdims(plind) -hdims(plind)],[-vdims(plind) vdims(plind)],line_color);
    plot3([plane plane],[hdims(plind) hdims(plind)],[-vdims(plind) vdims(plind)],line_color);
end

% Plot big dot for eye location
scatter3(0,0,0,500,[0 0 0],'filled');

% Adjust perspective
set(gca,'XLim',[-hdims(end)+50 hdims(end)+50],...
    'YLim',[-hdims(end) hdims(end)],...
    'ZLim',[-hdims(end) hdims(end)],...
    'YDir','reverse',...
    'Visible','off',...
    'CameraPosition',[-1100 1750 300],...
    'CameraViewAngle',7,...
    'CameraTarget',[100 0 0],...
    'Projection','perspective');

if annot_on
    % Add annotations for dimensions of screen
    
    deg_symbol = sprintf(char(176));
    rot_rad = 100/cos(50*(pi/180));
    start_ang = 50*(pi/180);
    
    if cond == 0
        % Screen dimensions (in degrees visual angle)
        text(45,-70,0,['68',deg_symbol],...
            'Color',annot_color,...
            'FontSize',20,...
            'FontWeight','bold',...
            'HorizontalAlignment','right');
        text(45,0,-55,['100',deg_symbol],...
            'Color',annot_color,...
            'FontSize',20,...
            'FontWeight','bold',...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom');
        
        % Depth
        plot3([0 150],[0 0],[-vdims(end)-7 -vdims(end)-7],'Color',annot_color);
        plot3([0 0],[0 0],[-vdims(end)-2 -vdims(end)-7],'Color',annot_color);
        plot3([50 50],[0 0],[-vdims(end)-2 -vdims(end)-7],'Color',annot_color);
        plot3([150 150],[0 0],[-vdims(end)-2 -vdims(end)-7],'Color',annot_color);
        text(25,0,-vdims(end)-5,'50cm',...
            'Color',annot_color,...
            'FontSize',15,...
            'FontWeight','bold',...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom');
        text(100,0,-vdims(end)-5,'100cm',...
            'Color',annot_color,...
            'FontSize',15,...
            'FontWeight','bold',...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom');
    end
    
    if cond == 2 || cond == 3
        % Plot Stimulus Rotation Arrows
        if cond == 2
            rcolor = [0 0 0];
            lcolor = [0 0 0];
        else
            rcolor = [255/255 128/255 0];
            lcolor = [0 102/255 204/255];
        end
        
        testx = 100/sin(34*(pi/180));
        rangs = start_ang:(pi/100):(start_ang + pi/4);
        langs = (2*pi - pi/4 - start_ang):(pi/100):(2*pi - start_ang);
        rcurvez = rot_rad.*cos(rangs);
        rcurvex = rot_rad.*sin(rangs);
        lcurvez = rot_rad.*cos(langs);
        lcurvex = rot_rad.*sin(langs);
        
        plot3(rcurvez,rcurvex,zeros(numel(rcurvez)),'Color',rcolor,'LineWidth',4);
        plot3(lcurvez,lcurvex,zeros(numel(lcurvez)),'Color',lcolor,'LineWidth',4);
        scatter3(rcurvez(end),rcurvex(end),0,150,rcolor,'<','filled');  % not yoked to rotation
        scatter3(lcurvez(1),lcurvex(1),0,150,lcolor,'<','filled');  % not yoked to rotation
        purs_annot = length(lcurvez)/2;
        text(lcurvez(purs_annot),lcurvex(purs_annot),4,['10',deg_symbol,'/s'],...
            'Color',lcolor,...
            'FontSize',15,...
            'FontWeight','bold',...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
    end
    
    if cond == 1 || cond == 3
        % Plot Eye Rotation Arrows
        if cond == 1
            rcolor = [0 0 0];
            lcolor = [0 0 0];
        else
            rcolor = [255/255 128/255 0];
            lcolor = [0 102/255 204/255];
        end
        
        erangs = 0:(pi/100):(start_ang + pi/4);
        elangs = (2*pi - pi/4 - start_ang):(pi/100):2*pi;
        ercurvez = rot_rad.*cos(erangs);
        ercurvex = rot_rad.*sin(erangs);
        elcurvez = rot_rad.*cos(elangs);
        elcurvex = rot_rad.*sin(elangs);
        plot3(ercurvez.*(1/10),ercurvex.*(1/10),-12*ones(numel(ercurvez)),'Color',rcolor,'LineWidth',4);
        plot3(elcurvez.*(1/10),elcurvex.*(1/10),-12*ones(numel(elcurvez)),'Color',lcolor,'LineWidth',4);
        scatter3(ercurvez(end).*(1/10),ercurvex(end).*(1/10),-12,150,rcolor,'<','filled');  % not yoked to rotation
        scatter3(elcurvez(1).*(1/10),elcurvex(1).*(1/10),-12,150,lcolor,'<','filled');  % not yoked to rotation
        
        if cond ~=3
            text(-10,-10,-22,['10',deg_symbol,'/s'],...
                'Color',lcolor,...
                'FontSize',15,...
                'FontWeight','bold',...
                'HorizontalAlignment','center',...
                'VerticalAlignment','bottom')
        end
        
        plot3([0 0],[0 0],[-25 25],'--k','LineWidth',3);
    end
    
    % Translation arrow
    plot3([50 12],[0 0],[0 0],'Color',annot_color,'LineWidth',4);
    scatter3(12,0,0,150,annot_color,'<','filled');  % not yoked to rotation
    
    if cond == 0
        text(30,0,2,'50cm/s',...
            'Color',annot_color,...
            'FontSize',15,...
            'FontWeight','bold',...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom');
    end
end

end




