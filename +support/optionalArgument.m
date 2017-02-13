function val = optionalArgument(default,name,fargs)

val = default;

nargs = length(fargs);
assert(mod(nargs,2)==0,'One of the optional arguments names does not have an associated value.');
for i = 1:2:nargs
    if strcmpi(name,fargs{i})
        val = fargs{i+1};
    end
end
