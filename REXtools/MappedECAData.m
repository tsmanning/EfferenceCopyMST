classdef MappedECAData
    %MappedECAData This class provides a mapping from channels to characters.
    % 
    %   This class presents a view of a set of events (ecodes/bcodes and
    %   their times and associated value, if any) and is backed by a
    %   particular data file. The events are all mapped to a particular set
    %   of characters, and the getMatches (which returns another ECMap) 
    %   and getEvents methods (which returns event arrays) use those 
    %   characters in pattern matching.
    
    properties(SetAccess=private)
        Channels=[];
        Letters='';
        Str='';
        Strind=[];
        TokenIndices={};
        Ecad;
    end
    
    methods
        function obj = MappedECAData(varargin)
            if length(varargin) >= 3
                % check that channels is 1xn
                if size(varargin{1}, 1) ~= 1 || ndims(varargin{1}) ~= 2
                    error('Channels arg must be 1xn');
                elseif length(varargin{1}) ~= length(varargin{2})
                    error('channels and letters must have same number of elements');
                elseif ~isa(varargin{3}, 'ECAData')
                    error('third arg must be ECAData object');
                end
            end
            if length(varargin) >= 5
                if length(varargin{4}) ~= length(varargin{5})
                    error('When supplying str and strind args, they must be the same length');
                end
            end
            if length(varargin) == 6
                if ~isnumeric(varargin{6})
                    error('When supplying token indices, sixth arg must be Nx2 array');
                end
            end
            
            switch length(varargin)
                case 6
                    obj.Channels = varargin{1};
                    obj.Letters = varargin{2};
                    obj.Ecad = varargin{3};
                    obj.Str = varargin{4};
                    obj.Strind = varargin{5};
                    obj.TokenIndices = varargin{6};
                case 5
                    obj.Channels = varargin{1};
                    obj.Letters = varargin{2};
                    obj.Ecad = varargin{3};
                    obj.Str = varargin{4};
                    obj.Strind = varargin{5};
                case 3
                    obj.Channels = varargin{1};
                    obj.Letters = varargin{2};
                    obj.Ecad = varargin{3};
                    [obj.Str, obj.Strind] = ecencode(int32(obj.Ecad.Channels), int32(obj.Channels), obj.Letters);
                case 0
                    % nothing here, this allows calling constructor with no
                    % args.
                otherwise
                    error('MappedECAData requires 3, 5, or 6 input args.');
            end
        end
        
        function ev = events(this, varargin)
            %events   Returns event information for a given set of events.
            %
            % When called with an empty arg list, all events in this map
            % are returned. 
            % If the arg is a numeric vector, then the vector is assumed to
            % have the indices, into this object's event string, of the
            % events of interest. Event information for just those events
            % is returned. 
            %
            % Event information is returned as an Nx4 array. The columns
            % are as follows:
            % (:, 1) - time
            % (:, 2) - value (if any)
            % (:, 3) - channel number of this event
            % (:, 4) - character of this event (converted to int)
            indices = [];
            if length(varargin) == 0
                indices = [1:length(this.Strind)];
            else
                indices = varargin{1};
            end
            m = containers.Map(this.Channels, int32(this.Letters));
            ev = this.Ecad.events(this.Strind(indices));
            num2cell(ev(:, 3));
            ev(:, 4) = cell2mat(m.values(num2cell(ev(:,3))));
        end
        

        function a = match(this, varargin)
            % match  applies a regex to the event string in this object and
            % returns the matches as a MappedECAData object array unless an
            % ECAMatchFormat object is provided with the 'Format' arg. the
            % ECAMatchFormat object specifies the arrangement of times and
            % values from the matches, with each instance of a match
            % making up a single row in the resulting array. If the
            % 'Timeseries' arg is provided, it should correspond to the
            % column which holds the time values. All remaining columns in
            % the ECAMatchFormat are used as data in the timeseries. 
            %
            % If the input arg is a string, it is treated as a regular
            % expression and matched against the event string. Each
            % resulting match is used to create a MappedECAData object in
            % the resulting array of objects. 
            a = [];
            
            % Parse input
            p = inputParser;
            p.FunctionName = 'match';
            p.addRequired('Pattern', @(x) ischar(x));
            p.addParamValue('Format', [], @(x) isa(x, 'ECAMatchFormat'));
            p.addParamValue('Timeseries', 0, @(x) isnumeric(x) && isscalar(x));
            p.parse(varargin{:});

            [firstind lastind tokenind] = regexp(this.Str, p.Results.Pattern, 'start', 'end', 'tokenExtents');


            % if no format requested we create an array of objects, one for
            % each match
            if isempty(p.Results.Format)
                if length(firstind) > 0
                    % Create empty array of objects
                    a=MappedECAData.empty(length(firstind), 0);

                    % Now create each object
                    for i=1:length(firstind)
                        a(i) = MappedECAData(this.Channels, this.Letters, this.Ecad, this.Str(firstind(i):lastind(i)), this.Strind(firstind(i):lastind(i)), tokenind{i}-firstind(i)+1);
                    end
                end
            else
                fmt = p.Results.Format;
                a = zeros(length(firstind), length(fmt.Token));
                % Each match is a row in the result
                for i=1:length(firstind)
                    % each item in fmt is a column in the result
                    for j=1:length(fmt.Token)
                        % the value of tokenind{i} is an Nx2 array, where N
                        % is the number of tokens in the input expression.
                        ind = tokenind{i}(fmt.Token(j), 1) + fmt.Position(j) - 1;
                        event = this.events(ind);
                        switch fmt.Type{j}
                            case 'value'
                                a(i, j) = event(2);
                            case 'time'
                                a(i, j) = event(1);
                            case 'char'
                                a(i, j) = event(4);
                            case 'channel'
                                a(i, j) = event(3);
                            otherwise
                                error('Unknown value type in ECAMatchFormat.');
                        end
                    end
                end
                if p.Results.Timeseries > 0
                    % value of timeseries arg is the column from the
                    % ECAMatchFormat to use as the time value. The
                    % remaining column(s) are the data.
                    b = timeseries(a(:, [1:p.Results.Timeseries-1, p.Results.Timeseries+1:end]), a(:, p.Results.Timeseries));
                    a = b;
                end
            end
        end
        
        function mecad = subset(this, varargin)
            %subset  Creates a subset of this object with events of given
            %types.
            %
            % Returns a MappedECAData object which includes or excludes
            % specific types. 
            %subset('Include', 'types')  Include only 'types' in subset
            %subset('Exclude', 'types')  Exclude only 'types' from subset
            
            mecad=[];
            ind=[];

            % Parse input.
            p = inputParser;
            p.FunctionName = 'subset';
            p.addParamValue('Include', '', @(x) ischar(x)); % only one of these allowed!
            p.addParamValue('Exclude', '', @(x) ischar(x));
            p.parse(varargin{:});

            if length(p.Results.Include) > 0 && length(p.Results.Exclude) > 0
                error('Cannot specify both Include and Exclude options.');
            end


            % map of characters to channel numbers. Will be used to
            % re-create channel map arrays.
            m = containers.Map(cellstr(this.Letters'), this.Channels);
            newchannels = [];
            newletters = '';

            % Handle included types.
            % Use array indexes to accomplish this.
            % The array ind will be the ultimate result...
            if length(p.Results.Include) > 0
                ind = [];
                for i=1:length(p.Results.Include)
                    tmp = (this.Str==p.Results.Include(i));
                    if isempty(ind)
                        ind = tmp;
                    else
                        ind = ind|tmp;
                    end
                end
                newletters = p.Results.Include;
                newchannels = cell2mat(m.values(cellstr(p.Results.Include')))';
            end    
            
            % now get rid of Excluded stuff.
            if length(p.Results.Exclude) > 0
                ind = [];
                for i=1:length(p.Results.Exclude)
                    tmp = this.Str~=p.Results.Exclude(i); 
                    if isempty(ind)
                        ind = tmp;
                    else 
                        ind = ind&tmp;
                    end
                end
                % use the map m to get list of letters and channels. 
                % m is initialized with original object values this.Letters
                % and this.Channels.
                m.remove(cellstr(p.Results.Exclude'));
                newletters = cell2mat(m.keys);
                newchannels = cell2mat(m.values);
            end
            
            % ind has the indices to keep in the new MappedECAData.
            if sum(ind)>0
                mecad = MappedECAData(newchannels, newletters, this.Ecad, this.Str(ind), this.Strind(ind));
            else
                mecad = MappedECAData(newchannels, newletters, this.Ecad, '', []);
                warning('Creating MappedECAData with no elements.');
            end
        end

        function lim = limits(this)
            %limits    Gets min and max times of events in this object.
            %
            % Returns a 2 element vector with the time of the first (1) and
            % last (2) event in this object.
            
            e0 = this.Ecad.events(this.Strind(1));
            e1 = this.Ecad.events(this.Strind(end));
            lim = [e0(1), e1(1)];
        end

        function c = decode(this)
            % decode   Converts letters back to codes.
            %
            % Returns a vector with the channels corresponding to the
            % letters in this match.
            
            c=zeros(1, length(this.Str));
            for i=1:length(this.Str)
                c(i) = this.Channels(this.Letters == this.Str(i));
            end
            return;
        end
        
        function an = analog(this, varargin)
            %analog    Get analog data
            %
            % analog('type')
            % This function returns a timeseries object with the analog
            % data of the type given in 'type'. The value of 'type' should
            % match one of the analog types in the underlying ECAData
            % object. When called with no additional arguments, the
            % timeseries is limited to the same time span delimited by the
            % first and last events in this MappedECAData object. 

            % Parse input
            p = inputParser;
            p.FunctionName = 'analog';
            p.addRequired('Type', @(x) ischar(x));
            p.addParamValue('Limits', [], @(x) isvector(x) && length(x)==2);
            p.parse(varargin{:});
            
            an=[];
            if ~this.Ecad.Adata.isKey(p.Results.Type)
                error('Request for unknown analog data type ''%s''', p.Results.Type);
            end
            if isempty(p.Results.Limits)
                limits = this.limits();
            else
                limits = p.Results.Limits;
            end
            ts = this.Ecad.Adata(p.Results.Type);
            an = timeseries(ts.Data(ts.Time >= limits(1) & ts.Time <= limits(2)), ts.Time(ts.Time >= limits(1) & ts.Time <= limits(2)));
        end
    end    
end

