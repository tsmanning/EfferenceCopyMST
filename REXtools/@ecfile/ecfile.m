% $Id: ecfile.m,v 1.1.1.1 2013/12/04 22:43:48 devel Exp $
%
function E = ecfile(varargin)
% ECFILE High level parsing of ReX ecode files. 
% E = ecfile(filename)

switch nargin
    case 1
        s = efile(varargin{1});
        E = class(s, 'ecfile');
    otherwise
        error('Wrong number of input arguments.');
    end
return;

