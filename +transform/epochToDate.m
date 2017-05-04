function date = epochToDate(epoch,format,sinceDate)
if nargin < 3
    sinceDate = '2000-01-01 12:00:00';
    if nargin < 2
        format = 'yyyy-MM-dd HH:mm:ss';
    end
end
date = datetime(epoch,'ConvertFrom','epochtime','Epoch',sinceDate,'Format',format);
