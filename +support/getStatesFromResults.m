function [states,cartesian] = getStatesFromResults(obj,preferCartesian)
if any(obj.columnIndexes(1:2) > 0)
    if preferCartesian
        is = [2 1];
    else
        is = [1 2];
    end
    for i = is
        if obj.columnIndexes(i) > 0
            if i == 1
                states = obj.keplerianStates;
            else
                states = obj.cartesianStates;
            end
            cartesian = i == 2;
            break;
        end
    end
else
    error('The body states could not be retrieved from the provided results object.')
end
