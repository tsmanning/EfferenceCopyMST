function [fit_params,r_sqr,output_info,bandwidth]=von_mises_fit(angles,data,inclskew,plots,degs)

% Fits data to von Mises (circular gaussian) function via OLS and fmincon's
% 'interior-point' algorithm

% Inputs should be FR data and matching heading angles
% If input angles are degrees, set degs flag to 1

if degs==1
    angles=angles.*(pi/180);    % calculations done in radians
end

angle_spacing=diff(angles(1:2));

% Create von Mises function

% Build vector of parameters to fit:
% x(1)=amplitude
% x(2)=bandwidth factor
% x(3)=preferred heading azimuth
% x(4)=skew factor
% x(5)=response baseline

% Uncorrected
% vonmises=@(x,angles)(x(1)*exp(-2.*(1-cos(angles-x(2)))/(x(3))^2)+x(4));

% Corrected for sigma effects on offset/amplitude
vonmises=@(x,angles)(x(1)/(1-exp(-4/x(3)^2)))*(exp(-2.*(1-cos(angles-x(2)))/(x(3))^2)-exp(-4/x(3)^2))+x(4);

% Corrected for sigma effects on offset/amplitude + skew parameter
% vonmises=@(x,angles)(x(1)/(1-exp(-2*x(2)))).*(exp(-x(2).*(1-cos(angles-x(3)-x(5).*(1-cos(angles-x(3))))))-exp(-2*x(2)))+x(4);

% Set up seeds for fitting

[dat_max,max_ind]=max(mean(data,1));
[dat_min,~]=min(min(data));
minamp=dat_max-dat_min;

amplitude=dat_max;  % Set gain factor
band=pi;   % Roughly approximate
theta_pref=angles(max_ind);  % Initially approximate function mean/center by angle corresponding to peak of data
r_off=min(data);
%skew=0;

%x0=[  x(1)       x(2)    x(3)  x(4)  x(5)];
%x0=[amplitude theta_pref band r_off skew];
x0=[amplitude theta_pref band r_off];

% Fit to data

vm_sumsquares = @(x) sum(sum((data - vonmises(x,angles)).^2,'omitnan'));
% vm_sumsquares=@(x)sum((vonmises(x,angles)-data).^2);    % Set up fitting as minimization of squared residuals
opts = optimoptions('fmincon','Display','off');     % Let matlab's script build the option set for you

lb=[minamp theta_pref-angle_spacing 1.5*diff(angles(1:2)) 0];
ub=[dat_max*1.15 theta_pref+angle_spacing Inf r_off];

% if incskew==1
% lb=[minamp 0 theta_pref-(pi/4) -0.75 0];  % Constrain parameters fits [0 mean_0-(pi/4) 0 0]
% ub=[dat_max*1.25 Inf theta_pref+(pi/4) 0.75 dat_max]; % preferred theta has largest effect
% else
% lb=[minamp 0 theta_pref-(pi/4) 0 0];
% ub=[dat_max*1.25 Inf theta_pref+(pi/4) 0 dat_max];
% end

% fmincon(fun,x0,A,b,Aeq,beq,lb,ub,nonlcon,options)
[fit_params,ss_res,~,output_info]=fmincon(vm_sumsquares,x0,[],[],[],[],lb,ub,[],opts);

if plots==1
    % Plot fit to check
    
    figure(2);hold on;
    scatter(angles.*(180/pi),data,20,'k','filled');
    
    func_angles=linspace(min(angles),max(angles),1000);
    func=vonmises(fit_params,func_angles);
    
    plot(func_angles.*(180/pi),func);
    
    s = sprintf(char(176));
    x_min=min(angles.*(180/pi));x_max=max(angles.*(180/pi));
    xlabel(['Heading Direction (',s,' Azimuth)'],'FontSize',15);
    ylabel('Firing Rate (Hz)','FontSize',15);
    set(gca,'XLim',[x_min,x_max],'Box','off','FontSize',12);
end

% Find Bandwidth (FWHM)

theta_half=acos(1+(fit_params(3)^2/2)*log(0.5+0.5*exp(-4/fit_params(3)^2)))+fit_params(2);
bandwidth=2*(theta_half-fit_params(2));

% [bandwidth]=vonmises_fwhm(fit_params(3),fit_params(2),fit_params(4));

% Convert bandwidth to degrees
if degs==1
    bandwidth=bandwidth.*(180/pi);
end

% Find R squared/coefficient of determination

dat_mean = mean(mean(data));
% for i = 1:length(data)
%     sqr_dat(i) = (data(i)-dat_mean)^2;
% end
sqr_dat = (data - dat_mean).^2;
ss_tot = sum(sum(sqr_dat,'omitnan'));  

r_sqr = 1-(ss_res/ss_tot);

end