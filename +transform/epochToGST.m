function gst = epochToGST(epoch)

if isa(epoch,'char')
    epoch = tesp.transform.dateToEpoch(epoch);
end

% From OCDM pages 197-198

% Julian Date for J2000 (from http://aa.usno.navy.mil/data/docs/JulianDate.php)
% J2000 = 12:00 UT, 1 January 2000
JD_J2000 = 2451545;
JD_J1900 = 2415020;
T = (JD_J2000 + epoch/tesp.constants.secondsInOne.day - JD_J1900)/36525;

% UT (in h)
UT = mod(12 + epoch/tesp.constants.secondsInOne.hour, 24);

% Greenwich sidereal time (in deg)
gst = mod(99.690983 + 36000.768925*T + 0.000387*T.^2 + 360/24*UT, 360);
