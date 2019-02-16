function [ecad,trials_ecad,mappedEcad,spikes,trials,idata] = bh_dataex(path,filename)

varargin = {strcat(path,'/',filename)};

% Parse inputs
parser = inputParser;   % Create input object
parser.addRequired('efile_or_base', @ischar);   % look char arrays in inputs, place under p.Results.efile_or_base
parser.addOptional('afile', 'NO_AFILE', @ischar);   % looks for another input. add optional 'afile' to look for, defaults to 'NO_AFILE'
parser.parse(varargin{:});

if strcmp(parser.Results.afile, 'NO_AFILE') % check if afile field defaults to nothing
    EFILE = strcat(parser.Results.efile_or_base,'E');
    AFILE = strcat(parser.Results.efile_or_base,'A');
else    % if more than one input found (i.e. not just inputting base name, assign 'em as E and AFILE)
    EFILE = parser.Results.efile_or_base;
    AFILE = parser.Results.afile;
end

% Get ecfile object for EFILE:
e = ecfile(EFILE);

% Create eca object
ecad = ECAData(get(e, 'Times'), get(e, 'Channels'), get(e, 'Values'));

% Obtain bcodes and bcode letter representation
% [channels, letters] = bcodes();
[shortchannels, shortletters] = bcodes('short');

% TSM 27 Jun 2018 - just modified bcodes to output
% shortchannels/shortletters without this hack

% DJS - remove eyetracking codes and create a second set of [channels,
% letters]. 
% This is inherently dangerous, because it relies on a specific ordering of
% the str returned from bcodes. The best way would be to remove these char:
% 'IJKLHVZ', and their associated channel numbers. 
% FYI - bcodes at this writing returns IJKLHV in a single clump, and Z
% tacked on the end of the string - the indices used in strcat and the
% array construction reflect this. 

% shortletters = strcat(letters(1:strfind(letters, 'IJK')-1), letters(strfind(letters, 'IJK')+6:end-1));
% shortchannels = [channels(1:strfind(letters, 'IJK')-1) channels(strfind(letters, 'IJK')+6:end-1)];

% Call MappedECAData to sort extracted efile into trials
mappedEcad = MappedECAData(shortchannels, shortletters, ecad);

% Find successful trials strings without fixation break, new trial start,
% missed frames, nor end data collection ECode
%trials_ecad = mappedEcad.match('(Tabcdefgh)[^XTMN]*(Y)');
trials_ecad = mappedEcad.match('(Tabcdefgh)[^XTN]*(Y)'); %need to fix missed frames problem

% Get spike times
spike_letters = 'S';
spike_codes = int32([601]);
[spike_str, spike_ind] = ecencode(int32(get(e, 'Channels')), spike_codes, spike_letters);

clear s;
s = struct;
s(1).a = 0;
s(1).b = -1;
s(1).c = 's';

spikes = makeseries(struct(e), spike_str, spike_ind-1, 'S', s);

% Get trials
% DJS use modified version of channels and letters
% DJS ORIGINAL LINE: 
% [str, strind] = ecencode(int32(get(e, 'Channels')), channels, letters);
[str, strind] = ecencode(int32(get(e, 'Channels')), shortchannels, shortletters);

strials = struct;
strials(1).a = 1;
strials(1).b = -1;
strials(1).c = 'T';
strials(2).a = 1;
strials(2).b = 1;
strials(2).c = 'a';
strials(3).a = 1;
strials(3).b = 2;
strials(3).c = 'b';
strials(4).a = 1;
strials(4).b = 3;
strials(4).c = 'c';
strials(5).a = 1;
strials(5).b = 4;
strials(5).c = 'd';
strials(6).a = 1;
strials(6).b = 5;
strials(6).c = 'e';
strials(7).a = 1;
strials(7).b = 6;
strials(7).c = 'f';
strials(8).a = 1;
strials(8).b = 7;
strials(8).c = 'g';
strials(9).a = 1;
strials(9).b = 8;
strials(9).c = 'h';
strials(10).a = 2;
strials(10).b = -1;
strials(10).c = 'Y';

%trials = makeseries(struct(e), str, strind-1, '(Tabcdefgh)[^XTMN]*(Y)', strials);
trials = makeseries(struct(e), str, strind-1, '(Tabcdefgh)[^XTN]*(Y)', strials); %need to fix missed frames problem
% break_fix_trials = makeseries(struct(e), str, strind-1, '(Tabcdefgh)[^T]*(X)', strials);

errors = 0;

% If statement below only true for Pursuit trials. 
if sum(trials(:,9)) == size(trials,1)
    % Check for trials of abnormal length (e.g. happens if trial started before
    % saving data)
    chktrls = trials(:,10)-trials(:,1);
    errtrls = find(chktrls>4000);
    passtrls = find(chktrls<4000);
    
    if ~isempty(errtrls)
        warning(['(',filename,') ','Removing the following trials with abnormal length(s): ',num2str(errtrls')]);
    end
    
    error_trials = trials(errtrls,:);
    trials = trials(passtrls,:);
    trials_ecad = trials_ecad(1,passtrls);
    
    errors = 1;
end

% Extract adata
adata = mrdr('-c', '-a', '-d', AFILE, '-s', '1166');
atrials = Trial(adata);

% Sort raw analog data into trials
found = 0;
maxsize = 0;
startIndex = zeros(1, length(trials(:, 1)));
endIndex = zeros(1, length(trials(:, 1)));
whichTrial = zeros(1, length(trials(:, 1)));

for i = 1:length(trials(:, 1))    % Increment through ecode data
    found = 0;
    j = 1;
    while found == 0 && j <= length(atrials)   % Increment through atrials
        % Find which a trials fall within time window defined by ecodes
        if trials(i, 1) < aEndTime(atrials(j)) && trials(i, 10) > aStartTime(atrials(j))
            found = 1;
            
            whichTrial(i) = j;
            startIndex(i) = trials(i,1)-aStartTime(atrials(j))+1;   % method for atrial object
            endIndex(i) = trials(i,10)-aStartTime(atrials(j))+1;
            thissize = endIndex(i)-startIndex(i)+1;
            
            if thissize > maxsize
                maxsize = thissize;
            end
        end
        j = j + 1;
    end
    
    % Print error if
    if found == 0
        fprintf('warning! fix period for trial %d not contained in a (rex)trial!\n', i);
    end
end

idata = zeros(maxsize, 3, length(trials(:, 1)));

for i = 1:length(startIndex)
    if whichTrial(i) > 0
        signals = Signals(atrials(whichTrial(i)));
        len = endIndex(i)-startIndex(i)+1;
        idata(1:len, 1, i) = signals(1).Signal(startIndex(i):endIndex(i))';
        idata(1:len, 2, i) = signals(2).Signal(startIndex(i):endIndex(i))';
        idata(1:len, 3, i) = [aStartTime(atrials(whichTrial(i))) ...
            + startIndex(i) - 1:aStartTime(atrials(whichTrial(i))) + endIndex(i) - 1]';
    else
        idata(:, :, i) = nan;
    end
end

% Save files in path

save([path,'/ecad'],'ecad');
save([path,'/trials_ecad'],'trials_ecad');
save([path,'/mappedEcad'],'mappedEcad');
save([path,'/spikes'],'spikes');
save([path,'/trials'],'trials');
save([path,'/idata'],'idata');

% save([path,'/break_fix_trials'],'break_fix_trials');

if errors
    save([path,'/error_trials'],'error_trials');
end

end