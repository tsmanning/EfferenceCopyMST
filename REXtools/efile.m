function[data] = efile(ecode_file)
% [data] = efile(ecode_file) performs a basic parse of an E-file created by REX. 
%
% The efile 'ecode_file' is opened and translated. The result 'data' is a
% struct array with the following fields:
% time - an Nx1 int32 matrix containing the time values for each ecode as recorded by REX
% ecode - an Nx1 int16 matrix containing the ecode values
% channel - an Nx1 int32 matrix containing channel numbers (see BCODES below)
% type - an Nx1 int16 matrix containing data types (see BCODES below)
% U - an Nx1 uint32 matrix with unsigned int values (see BCODES below)
% I - an Nx1 int32 matrix with int values (see BCODES below)
% F - an Nx1 single matrix with unsigned int values (see BCODES below)
% ID - the paradigm ID for this efile. 
%
% The 'time' and 'ecode' fields accurately represent the raw data found in
% the efile. If your paradigm is NOT using BCODES (see below) you can
% safely ignore all the other fields (though ID is still valid) in your
% analysis. 
%
% BCODES
%
% BCODES represent a scheme used in the Britten lab whereby the ecode is
% used to store 4-byte data values, something which is otherwise not
% possible in REX. In the past, REX users have stored time-dependent
% variable data in ecodes by restricting the dynamic range of the possible
% values to the range allowed by the REX ecode format. In REX, an ecode
% is an 8-byte struct:
% 
% struct ecode {
%    short seqno;   /* sequence number, assigned by REX */
%    short ecode;   /* ecode value */
%    long time;     /* time in ms taken from rex clock */
% };
%
% The ecode facility in REX is designed to allow users to place markers for
% various events in the efile. The markers, or ecodes, are restricted to
% the lower 13 bytes of the ecode, the 3 highest order bytes being reserved
% by REX. This gives users a range of 8192 possible values. In addition,
% REX reserves the codes from 1-1500 for internal use, so users are limited
% to a dynamic range of 8192-1500 = 6692. When recording static ecode
% "markers", for example a marker to indicate that a lever was pressed, a
% single value in the allowed range 1500-8192 is used. If the user wants to
% record an angle, for example, she can restrict it to the range 0-360 and
% add it to a base ecode value, recording the result as an ecode. With care
% that value can be extracted from the efile, assuming the user designs the
% REX experiment so the order of ecodes recorded is known at parse time. 
% 
% This technique has been used successfully for years. In principle the
% only limitation is on the dynamic range of values that may be recorded,
% though with some imagination a user can store a single value in multiple
% ecodes so long as they are willing to expend the effort required to
% correctly parse the values later. 
%
% A more careful examination of the REX code reveals that it is possible to
% record a full 4 bytes of information in an ecode by using the time value.
% Obviously, care must be taken on parsing the values to ensure they are
% correctly interpreted (depending on whether one stores integer, unsigned
% integer, or single-precision floating point values. In addition, extra
% ecodes are recorded so that the time associated with data values is known
% (the time field being used to store data requires that we do this!). 
%
% Bcodes allow for "channels" of data values, which may be one of three
% types: integer, unsigned integer or single precision floating point. All
% are stored in the 4 bytes normally used for the time by REX. The bytes
% 9-13 in the ecode are used to indicate the data type, and the lowest
% order 8 bytes are used to indicate the "channel". Thus an experiment can
% record a joystick response value in channel 1, a computed angular value
% in channel 2, and so on. There is a small library of functions in REX
% which support this functionality. That library also records an extra
% ecode which contains the time associated with channel data, and ensures
% that a time bcode is recorded every time a channel bcode is recorded.
% When the efile is parsed, the parsing algorithm looks backwards in the
% efile to the last recorded time bcode and uses that bcodes' time as the
% time value for a bcode channel value. 
%
% This mex function does all this for you. The struct field 'channel' holds
% the channel values. Non-bcode ecodes stored in the file are assigned to
% channel 0. The struct field 'type' holds a value indicating the data type
% held by that channel. Again, non-bcode ecodes have type=0. For bcode
% data, these are the types:
% float: 0x1800  - data value stored in F
% int: 0x1400 - data value stored in I
% uint: 0x1200 - data value stored in U
% marker: 0x1100 - indicates this is an "extra" bcode to hold the time
%
% All ecodes in the file are returned, regardless of how they were recorded or 
% intended to be used. Time values are not adjusted, even if
% they contain negative time values (i.e. they are pointers into an
% A-file). The sequence numbers are not returned, though
% they are checked when the file is read; a gap in the sequence numbers is
% reported as an error. 
