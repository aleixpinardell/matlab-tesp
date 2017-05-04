function t = timeToSeconds(t,units)

if nargin == 1
    [~,tok] = regexp(t,'((|[+\-.])[0-9]*\.?[0-9]+(?:[eE][+-]?[0-9]+)?)\s*(.+)','match','tokens');
    t = str2double(tok{1}{1});
    units = tok{1}{2};
end

if any(strcmpi(units,{'s','sec','second','seconds'}))
    % Do nothing, alreay in seconds
elseif any(strcmpi(units,{'min','minute','minutes'}))
    t = t * tesp.constants.secondsInOne.minute;
elseif any(strcmpi(units,{'h','hour','hours'}))
    t = t * tesp.constants.secondsInOne.hour;
elseif any(strcmpi(units,{'sd','sday','sdays','siderealDay','siderealDays'}))
    t = t * tesp.constants.secondsInOne.siderealDay;
elseif any(strcmpi(units,{'d','day','days'}))
    t = t * tesp.constants.secondsInOne.day;
elseif any(strcmpi(units,{'y','year','years','julianYear','julianYears'}))
    t = t * tesp.constants.secondsInOne.julianYear;
elseif any(strcmpi(units,{'sy','syear','syears','siderealYear','siderealYears'}))
    t = t * tesp.constants.secondsInOne.siderealYear;
else
    warning('Could not recognize the specified time units. Seconds will be used.');
end

