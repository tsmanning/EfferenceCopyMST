function v = bcodeValue(e, ind)

    t = get(e, 'Types');
    if ((ind < 1) || (ind > size(t, 1))), 
        error('bcodeValue: ind must be a positive integer, less than size of ecfile');
    end
    
    switch t(ind),
        case 4352
            t = get(e, 'Times');
            v = double(t(ind));
        case 4608
            u = get(e, 'U');
            v = double(u(ind));
        case 5120
            i = get(e, 'I');
            v = double(i(ind));
        case 6144
            f = get(e, 'F');
            v = double(f(ind));
        otherwise
            c = get(e, 'Codes');
            v = double(c(ind));
    end
    
    return;
end

            