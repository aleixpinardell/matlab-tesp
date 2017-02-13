function L = longitudeSubsatellitePoint(arg1,arg2)
%Determine the longitude of the subsatellite point of a spacecraft:
%   L = longitudeSubsatellitePoint(tesp.results)
%   L = longitudeSubsatellitePoint(epoch,state)
%   L = longitudeSubsatellitePoint([epoch state])
%The longitude is given in degrees East from the Greenwich meridian.

if isa(arg1,'tesp.results')
    epochs = arg1.epochs;
    [states,cartesian] = tesp.support.getStatesFromResults(arg1,1);
else
    if nargin == 1
        epochs = arg1(:,1);
        states = arg1(:,2:end);
    elseif nargin == 2
        epochs = arg1(:);
        states = arg2;
    end
    [~,m] = size(states);
    if m == 2 || m == 3
        cartesian = true;
    else
        tesp.support.assertValidState(states);
        cartesian = tesp.support.isCartesianState(states);
    end
end

% Transform to Cartesian if provided in Keplerian
if ~cartesian
    states = tesp.transform.keplerianToCartesian(states);
end

L = mod( mod(atan2d(states(:,2),states(:,1)),360) - tesp.transform.epochToGST(epochs), 360);
