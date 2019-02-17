function shadeplot(mean_in,std_in,horiz_in,color_in,alpha)
    % Plots a filled shaded region instead of error bars or IQRs
    % Usage: shadeplot(mean_in,std_in,horiz_in,oolor_in,alpha)
    
    
    if ishold==0
        holdwasnoton=true;
    else
        holdwasnoton=false;
    end
    
    hold on;
    
    % Check to see if mean/standard deviation do not change with horizontal 
    if isscalar(mean_in)
        F=mean_in.*ones(horiz_in);
    else
        F=mean_in;
    end
    
    if isscalar(std_in)
        F_std=std_in.*ones(horiz_in);
    else
        F_std=std_in;
    end
    
    % Plot std or IQR as a filled polygon: first line follows horiz axis,
    % third follows axis in reverse and lines are connected between end of
    % first and beginning of third, end of third and beginning of first
    
    fill([horiz_in fliplr(horiz_in)],[F+F_std fliplr(F-F_std)],color_in,'FaceAlpha',alpha,'linestyle','none');
    
    % Plot mean or median
    plot(horiz_in,mean_in,'Color',color_in,'linewidth',1.5);
    
    if holdwasnoton
        hold off
    end
    
end