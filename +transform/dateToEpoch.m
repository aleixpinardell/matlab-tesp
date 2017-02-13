function epoch = dateToEpoch(date)
if ~isa(date,'datetime')
    date = datetime(date);
end
epoch = ( juliandate(date) - juliandate(2000,1,1,12,0,0) ) * 86400.0;
