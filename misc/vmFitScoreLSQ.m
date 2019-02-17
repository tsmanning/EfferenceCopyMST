function [ SSR ] = vmFitScoreLSQ(x,spikes,angles)
% LSQ objective function for von Mises fit
%
% Usage: [ score ] = vmFitScoreLSQ(x,spikes,angles) 

    % Define expected values for each stimulus presented
    expectedV = (x(1)/(1-exp(-4/x(3)^2))) * ...
        (exp(-2.*(1-cos(angles-x(2)))/(x(3))^2) - exp(-4/x(3)^2)) + x(4);
    
    if size(spikes,2) > 1
       if iscolumn(expectedV)
          expectedV = expectedV';
       end
       
       expectedV = repmat(expectedV,size(spikes,1),1); 
    end
    
    % Get sum of squared residuals
    SSR = sum(sum((spikes - expectedV).^2,'omitnan'),'omitnan');
end