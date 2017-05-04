function format = compactFormat(values)

if isa(values,'double')
    decimals = 0;
    for value = values
        e = 0;
        while true
            v = value*10^e;
            if abs( ceil(v) - v ) < 1e-6
                break;
            end
            e = e + 1;
        end
        decimals = max(decimals,e);
    end
    leadings = max(1,floor(log10(max(values))+1));
    format = sprintf('%%0%g.%gf',leadings+decimals+1-(decimals==0),decimals);
else
    error('Could not determine compact format because the values are not numeric.');
end
