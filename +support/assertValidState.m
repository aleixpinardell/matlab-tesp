function assertValidState(states,nc)
if nargin < 2
    nc = 6;
end
[~,s] = size(states);
assert(any(s==nc),'State vectors must be row-arrays with %g columns. ',nc);
