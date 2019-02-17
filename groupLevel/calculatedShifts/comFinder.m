function [CoMx,CoMy,Z] = comFinder(Vr,Vt,SD,plotOn)

% Plot x component of Centers of Motion for each depth plane in stimulus
% (in screen coordinates - cm)
%
% Usage: [] = comFinder(Vr,Vt)
%        [] = comFinder([Rx,Ry,Rz],[az,el,speed])

Z = 50:150;
T = [sin(Vt(1)*(pi/180))*cos(Vt(2)*(pi/180)),...
     sin(Vt(2)*(pi/180)),...
     cos(Vt(1)*(pi/180))*cos(Vt(2)*(pi/180))].*Vt(3);

R = Vr*(pi/180);

% vx_func = @(x,y,Z,T,R,screen_dist)...
%               (-T(1)*screen_dist + x.*T(3))./Z ...
%             + R(1).*x.*y.*(1/screen_dist)...
%             - R(2).*(screen_dist + (x.^2)./screen_dist) ...
%             + R(3).*y;
      
% Equation for vertical component of center of motion
yCom = @(Ty,SD,xCom,Z,Ry,Tz) ...
           (-Ty*SD^2)/(xCom*Z*Ry - SD*Tz);

CoMx = nan(numel(Z),1);
CoMy = nan(numel(Z),1);

% Find CoM location on screen in cm
for i = 1:numel(Z)
    % Solve quadratic to find horizontal component
    a = -R(2)/SD;
    b = T(3)/Z(i);
    c = -(T(1)*SD)/Z(i) - R(2)*SD;
    r = roots([a b c]);
    
    % Check if CoM exists
    if length(r) > 1
        % choose second root if it is real (i.e. exists)
        if isreal(r(2)) && a ~= 0
            CoMx(i,1) = r(2);
        elseif ~isreal(r(2)) && a ~= 0
            CoMx(i,1) = nan;
        end
    else
        CoMx(i,1) = (SD*T(1))/T(3);
    end
    
%     % choose second root if it is real (i.e. exists)
%     if isreal(r(1))
%         CoMx(i,2) = atand(r(1)/50);
%     else
%         CoMx(i,2) = nan;
%     end
    
    CoMy(i,1) = yCom(T(2),SD,CoMx(i,1),Z(i),R(2),T(3));
end

if plotOn        
    f = figure;
    f.Position = [300 300 630 535];
    hold on
    plot(atand(CoMx(:,1)/50),Z,'k','LineWidth',2);
    
    set(gca,'XLim',[-70 70],'ylim',[Z(1) Z(end)],'FontSize',20,'xtick',-50:10:50,'ytick',50:20:150);
%     xlabel('Center of Motion (cm)');
    xlabel('Center of Motion (\circ)');
    ylabel('Plane Distance (cm)');
end

end