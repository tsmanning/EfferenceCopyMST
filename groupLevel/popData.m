classdef popData
    % This class holds data related to parameter fits from individual cells
    % in a population sample set for the bighead paradigm.
    
    properties
        cellID = [];
        gain_mat = [];
        offset_mat = [];
        band_mat = [];
        tuncent_mat = [];
        mean_gain = [];
        mean_offset = [];
        mean_band = [];
        mean_tuncent = [];
        headcents = [];
        elevation = [];
        centshift_mat = [];
        lr_index = [];
        lr_index_blink = [];
        backforw = [];
        viewing_cond = [];
        numSacc = [];
        pursGain = [];
        HVelError = [];
        VVelError = [];
    end
    
    methods
        function obj = popData(all_params,obj_inds,num_eyes)
            
            num_cells = numel(obj_inds);
            
            if num_eyes == 1
                x = 'monoc';
            elseif num_eyes == 2
                x = 'binoc';
            end
            
            % Initialize
            obj.viewing_cond = num_eyes*ones(num_cells,1);
            obj.gain_mat = zeros(num_cells,7);
            obj.offset_mat = zeros(num_cells,7);
            obj.band_mat = zeros(num_cells,7);
            obj.tuncent_mat = zeros(num_cells,7);
            obj.lr_index = zeros(num_cells,1);
            obj.lr_index_blink = zeros(num_cells,1);
            obj.backforw = zeros(num_cells,1);
            obj.headcents = zeros(num_cells,7);
            obj.elevation = zeros(num_cells,1);
            obj.centshift_mat = zeros(num_cells,7);
            obj.numSacc = zeros(num_cells,7);
            obj.pursGain = zeros(num_cells,7);
            
            % Extract info from all_params
            for i = 1:num_cells
                obj.cellID{i,1} = all_params(obj_inds(i)).cellID;
                obj.gain_mat(i,:) = all_params(obj_inds(i)).(x).gains(:)';
                obj.offset_mat(i,:) = all_params(obj_inds(i)).(x).offsets(:)';
                obj.band_mat(i,:) = all_params(obj_inds(i)).(x).bandwidth(:)';
                obj.tuncent_mat(i,:) = all_params(obj_inds(i)).(x).az_tuning(:)';
                obj.elevation(i,1) = all_params(obj_inds(i)).(x).elevation;
                obj.lr_index(i,1) = all_params(obj_inds(i)).lr_index;
                obj.lr_index_blink(i,1) = all_params(obj_inds(i)).lr_index_blink;
                obj.backforw(i,1) = all_params(obj_inds(i)).backforw;
                
                obj.numSacc(i,:) = all_params(obj_inds(i)).(x).meanNumSacc;
                obj.pursGain(i,:) = all_params(obj_inds(i)).(x).meanGain;
                obj.HVelError(i,1) = all_params(obj_inds(i)).(x).meanHVelError;
                obj.VVelError(i,1) = all_params(obj_inds(i)).(x).meanVVelError;
            end
            
            obj.mean_gain = nanmean(obj.gain_mat);
            obj.mean_offset = nanmean(obj.offset_mat);
            
            % Find mean bandwidths & tuning centers with circular stats
            obj.band_mat = obj.band_mat.*(pi/180);    % convert all to radians
            obj.tuncent_mat = obj.tuncent_mat.*(pi/180);
            
            for i = 1:7
                bands = obj.band_mat(:,i);
                tuncents = obj.tuncent_mat(:,i);
                
                obj.mean_band(i,1) = circ_mean(bands(~isnan(bands)));
                obj.mean_tuncent(i,1) = circ_mean(tuncents(~isnan(tuncents)));
            end
            
            obj.mean_band = obj.mean_band.*(180/pi);  % convert all back to degrees
            obj.mean_tuncent = obj.mean_tuncent.*(180/pi);
            obj.band_mat = obj.band_mat.*(180/pi);
            obj.tuncent_mat = obj.tuncent_mat*(180/pi);
            
            % Find tuning shifts from heading only condition
            obj.headcents = obj.tuncent_mat(:,1);
            obj.centshift_mat = obj.tuncent_mat(:,2:7);
            
            for i = 1:num_cells
                obj.centshift_mat(i,:) = obj.centshift_mat(i,:) - obj.headcents(i);
                for j = 1:6
                    if obj.centshift_mat(i,j) > 180
                        obj.centshift_mat(i,j) = obj.centshift_mat(i,j) - 360;
                    elseif obj.centshift_mat(i,j) < -180
                        obj.centshift_mat(i,j) = obj.centshift_mat(i,j) + 360;
                    end
                end
            end
            
            % Convert heading directions to -180:180deg range
            for i = 1:numel(obj.headcents)
                if obj.headcents(i) > 180
                    obj.headcents(i) = obj.headcents(i) - 360;
                end
            end
        end
        
        function plotparams(obj,path,param)
            obj_name = getobjname(obj);
            
            fig = figure;
            set(fig,'Position',[50 550 1200 500]);   % Define Figure Window Size for 1080i
            
            colors = [0 0 0; 0 0 0.8; 0.8 0 0];
            purs_type = {'Left','Right'}; % 0deg = right, 180deg = left
            param_type = {'gain','offset','band','tuning_shift'};
            
            xlabels = {'Amplitude (Heading Only, sp/sec)',...
                'Offset (Heading Only, sp/sec)',...
                'Bandwidth (Heading Only, deg)',...
                'Tuning Center (Heading Only, deg)'};
            ylabels = {'Amplitude (Pursuit Conditions, sp/sec)',...
                'Offset (Pursuit Conditions, sp/sec)',...
                'Bandwidth (Pursuit Conditions, deg)',...
                'Center Shift (Pursuit Conditions, deg)'};
            
            if param < 4
                paramfield = [param_type{param},'_mat'];
                paramdat = obj.(paramfield);
                
                param_max = max(max([paramdat; paramdat]));
                param_max = round(param_max*1.1,-1);
                
                xlimit = [0 param_max];
                xtick = 0:param_max/2:param_max;
                ylimit = [0 param_max];
                ytick = 0:param_max/2:param_max;
            else
                paramdat = [obj.headcents obj.centshift_mat];
                
                xlimit = [-180 180];
                xtick = -180:180:180;
                ylimit = [-90 90];
                ytick = -90:15:90;
            end
            
            for i=1:2
                figure(fig); subplot(1,2,i); hold on;
                
                for j=1:3
                    scatter(paramdat(:,1),paramdat(:,j+1+3*(i-1)),50,colors(j,:),'filled');
                end
                
                if param < 4
                    plot(xlimit,ylimit,'--k');
                else
                    plot(xlimit,[0 0],'--k');
                end
                set(gca,'XLim',xlimit,'XTick',xtick,'YLim',ylimit,'YTick',ytick,'Box','off','FontSize',20);
                title([purs_type{i},' Pursuit'],'FontSize',20);
                xlabel(xlabels{param},'FontSize',15);
                ylabel(ylabels{param},'FontSize',15);
            end
            
            hgsave(fig,[path,'scatterplots/',param_type{param},'_',obj_name]);
        end
    end
end

