function [varargout] = bcodes(varargin)
%function [channels, letters] = bcodes()
% bcodes()      Britten lab-specific channel number map.
%
% [channels, letters] = bcodes();
% The return values can be used when creating MappedECAData. 
% bcodes('W');
% bcodes('WM');
% bcodes(1509);
% bcodes(1509, 1505);
% bcodes([1509, 1505]);
% Prints letter, channel, and description(s) for the given
% channels/letters.
%
% The channels and their meaning are as follows:
%
% 1509  W   WENT
% 1505  M   Missed frame, issued prior to next available WENT. 
% 1560  D   Dots on
% 1561  S   Translation start
% 1562  A   Pursuit pause
% 1563  C   Pursuit pre-start
% 1564  P   Pursuit start
% 1565  B   Pursuit blink start
% 1566  G   Pursuit blink end
% 1166  T   Trial Start
% 1167  E   Trial End
% 1180  X   Break fixation
% 1181  Y   Trial completed successfully
% 1184  F   Fixation
% 1030  R   Reward
% 1570  I   EVLOOP Wait 
% 1571  J   EVLOOP Fill
% 1572  K   EVLOOP Saccade
% 1573  L   EVLOOP Delay
% 65537 H   REX Saccade identified - Horizontal
% 65538 V   REX Saccade identified - Vertical
% 65546 N   End Data collection
% 1     a   Trial condition
% 2     b   heading azimuth
% 3     c   heading elevation
% 4     d   heading speed
% 5     e   pursuit angle
% 6     f   pursuit speed
% 7     g   translation type (0:None, 1:Translation)
% 8     h   pursuit type     (0:None, 1:Pursuit, 2:Simulated, 3:RetStab)
% 21    i   cam position x
% 22    j   cam position y
% 23    k   cam position z
% 24    l   looking direction A0
% 25    m   looking direction A1
% 26    n   looking direction A2
% 27    o   looking direction type
% 28    p   pursuit transform PHI
% 29    q   pursuit transform BETA
% 30    r   pursuit transform RHO
% 31    s   EV OK
% 32    t   EV X
% 33    u   EV Y
% 34    v   Retinal correction - azimuth
% 35    w   Retinal correction - elevation
% 170   x   Timestamp for original stabilization trial
% 601   Z   Spike
% Unspecified: 800 801
% 65540     O   Start data collection
% 1003      A   (?)
% 0         y   (takes initial code then returns 0)


    channels = int32([1509 1505 1560 1561 1562 1563 1564 1565 1566 1166 ...
                      1167 1180 1181 1184 1030 1570 1571 1572 1573 65537 ...
                      65538 65546 1 2 3 4 5 6 7 8 21 22 23 24 25 26 27 28 ...
                      29 30 31 32 33 34 35 170 601]);
                  
    shortchannels = int32([1509 1505 1560 1561 1562 1563 1564 1565 1566 1166 ...
                      1167 1180 1181 1184 1030 65546 1 2 3 4 5 6 7 8 21 22 ...
                      23 24 25 26 27 28 29 30 31 32 33 34 35 170]);
                  
    letters = 'WMDSACPBGTEXYFRIJKLHVNabcdefghijklmnopqrstuvwxZ';
    
    shortletters = 'WMDSACPBGTEXYFRNabcdefghijklmnopqrstuvwx';
    
    desc{1} = 'Went';   % 1509
    desc{2} = 'Missed frame, issued prior to next available WENT';   % 1505
    desc{3} = 'Dots on';    % 1560
    desc{4} = 'Translation start';  % '1561
    desc{5} = 'Pursuit pause';  % 1562
    desc{6} = 'Pursuit pre start';  % 1563
    desc{7} = 'Pursuit start';  % 1564
    desc{8} = 'Pursuit blink start'; % 1565
    desc{9} = 'Pursuit blink end';  % 1566
    desc{10} = 'Trial start';   % 1166
    desc{11} = 'Trial end'; % 1167
    desc{12} = 'Break fixation'; % 1180
    desc{13} = 'Trial completed successfully'; % 1181
    desc{14} = 'Fixation'; % 1184
    desc{15} = 'Reward';    % 1030
    desc{16} = 'EVLOOP Wait';  % 1570
    desc{17} = 'EVLOOP Fill';  % 1571
    desc{18} = 'EVLOOP Saccade';  % 1572
    desc{19} = 'EVLOOP Delay';  % 1573
    desc{20} = 'REX Saccade identified - Horizontal';  % 65537
    desc{21} = 'REX Saccade identified - Vertical';  % 65538
    desc{22} = 'End Data collection';  % 65546
    desc{23} = 'Trial condition';  % 1
    desc{24} = 'heading azimuth';  % 2
    desc{25} = 'heading elevation';  % 3
    desc{26} = 'Heading speed (units/frame)';  % 4
    desc{27} = 'Rho (pursuit angle)';  % 5
    desc{28} = 'Pursuit speed (deg/frame)';  % 6
    desc{29} = 'translation type (0:None, 1:Translation)';  % 7
    desc{30} = 'pursuit type (0:None, 1:Pursuit, 2:Simulated, 3:RetStab)';  % 8
    desc{31} = 'cam position x';  % 21
    desc{32} = 'cam position y';  % 22
    desc{33} = 'cam position z';  % 23
    desc{34} = 'looking direction A0';  % 24
    desc{35} = 'looking direction A1';  % 25
    desc{36} = 'looking direction A2';  % 26
    desc{37} = 'looking direction type';  % 27
    desc{38} = 'pursuit transform PHI';  % 28
    desc{39} = 'pursuit transform BETA';  % 29
    desc{40} = 'pursuit transform RHO';  % 30
    desc{41} = 'eye velocity OK';  % 31
    desc{42} = 'eye velocity x';  % 32
    desc{43} = 'eye velocity y';  % 33
    desc{44} = 'Retinal correction - azimuth';  % 34
    desc{45} = 'Retinal correction - elevation';  % 35
    desc{46} = 'Stabilization trial timestamp'; % 170
    desc{47} = 'Spike'; % 601

    shortOut = false;
    
    for i = 1:nargin
        if ischar(varargin{i})
            if strcmp(varargin{i},'short')
                % kludge life
                shortOut = true;
            else
                for cc = 1:length(varargin{i})
                    ind = find(letters == varargin{i}(cc));
                    if isempty(ind)
                        fprintf(1, 'letter "%s" No such letter found\n', varargin{i}(cc));
                    else
                        fprintf(1, 'letter "%s" channel %d desc: %s \n', varargin{i}(cc), channels(ind), desc{ind});
                    end
                end
            end
        elseif isscalar(varargin{i})
            ind = find(channels==varargin{i});
            if isempty(ind)
                fprintf(1, 'channel %d: No such channel found\n', varargin{i});
            else
                fprintf(1, 'letter "%s" channel %d desc: %s\n', letters(ind), varargin{i}, desc{ind});
            end
        elseif isnumeric(varargin{i}) && isvector(varargin{i})
            for cc=1:length(varargin{i})
                ind = find(channels==varargin{i});
                if isempty(ind)
                    fprintf(1, 'channel %d: No such channel found\n', varargin{i});
                else
                    fprintf(1, 'letter "%s" channel %d desc: %s\n', letters(ind), varargin{i}, desc{ind});
                end
            end
        end
    end
    
    switch nargout
        case 0
            if nargin==0
                % special case
                for i=1:length(channels)
                    fprintf(1, 'letter "%s" channel %d desc: %s \n', letters(i), channels(i), desc{i});
                end
            end
        case 1
            if shortOut
                varargout{1} = shortchannels;
            else
                varargout{1} = channels;
            end
        case 2
            if shortOut
                varargout{1} = shortchannels;
                varargout{2} = shortletters;
            else
                varargout{1} = channels;
                varargout{2} = letters;
            end
        otherwise
            error('bcodes requires 0, 1, or 2 outputs');
    end

return;