function cellvalues = cellCompactFormat(values)

if isa(values,'cell')
    cellvalues = values;
elseif isa(values,'double')
    format = tesp.support.compactFormat(values);
    cellvalues = cell(size(values));
    for i = 1:length(values)
        cellvalues{i} = sprintf(format,values(i));
    end
else
    cellvalues = {values};
end
