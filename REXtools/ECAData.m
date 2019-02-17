classdef ECAData < handle
    %ECAData Event or Coded data, and analog timeseries data.
    %   This class holds event data (a timestamp and a type) and/or value
    %   data (a timestamp, type and value).
    
    properties (SetAccess=private)
        Times=[];        % time
        Channels=[];     % channel number
        Values=[];       % value associated with each event, or NaN if none
        Adata=containers.Map;   % map of timeseries containing analog data
    end
    
    methods
        function obj = ECAData(t, c, v)
            obj.Times = t;
            obj.Channels = c;
            obj.Values = v;
        end
        
        function ev = events(this, indices)
            %events     Returns events at the given indices.
            %   This method returns an nx4 matrix of event data. Each event
            %   is a row in the matrix, with columns
            %   1: time
            %   2: value (if any, may be NaN)
            %   3: channel (ecode if this is an ecode, or bcode channel)
            %   4: 0 (used when ECMap returns events)
            %
            if ~iscell(indices) 
                if isnumeric(indices) && isvector(indices)
                    ev = this.makeevents(indices);
                else
                    error('input arg should be nx1 numeric array or cell array of nx1 numeric arrays');
                end
            else
                for i=1:length(indices)
                    if ~isnumeric(indices{i}) || ~ismatrix(indices{i}) || size(indices{i}, 2)~=1
                        error('input arg should be nx1 numeric array or cell array of nx1 numeric arrays');
                    end
                end
                ev = cell(length(indices));
                for i=1:length(indices)
                    ev{i} = this.makeevents(indices{i});
                end
            end
            return;
        end
    end
    
    methods (Access=private)
        
        function ev = makeevents(this, indices)
        % makeEvents  Construct event matrices for the given indices.
        %   Makes event matrices for the given event indices. The event
        %   matrices are nx4, with the 4 columns being time, value (if any,
        %   may be NaN), event channel. Column 4 is 0 when this function is
        %   called - ECMaps that call makeEvents will put the char for each
        %   event into this column.
        %
            if isnumeric(indices) && isvector(indices)
                ev = zeros(length(indices), 4);
                ev(1:end, 1) = this.Times(indices);
                ev(1:end, 2) = this.Values(indices);
                ev(1:end, 3) = this.Channels(indices);
            else
                error('indices must be an nx1 numeric array');
            end
            return;
        end
    end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
end

