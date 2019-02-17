% $Id: get.m,v 1.1.1.1 2013/12/04 22:43:48 devel Exp $
%
function val = get(E, propName)
% GET Get ecfile properties from the specified object
% and return the value
switch propName
    case 'ID'
        val = E.ID;
    case 'Times'
        val = E.time;  
    case 'Codes'
        val = E.ecode;
    case 'Channels'
        val = E.channel;
    case 'Types'
        val = E.type;
    case 'U'
        val = E.U;
    case 'I'
        val = E.I;
    case 'F'
        val = E.F;
    case 'V'
        val = E.V;
    case 'Values'
        val = E.V;
    otherwise
        error([propName,' Is not a valid ecfile property'])
    end
