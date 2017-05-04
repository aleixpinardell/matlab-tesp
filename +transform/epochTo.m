function t = epochTo(t,units)

if strcmpi(units,'date')
    t = tesp.transform.epochToDate(t);
else
    t = tesp.transform.secondsTo(t-t(1),units);
end
