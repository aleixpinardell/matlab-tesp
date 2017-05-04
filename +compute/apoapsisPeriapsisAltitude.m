function [ha,hp] = apoapsisPeriapsisAltitude(obj,varargin)
%Determine the perigee and apogee altitude [m] from a results object or from a state:
%   [ha,hp] = perigeeApogeeAltitude(tesp.results)
%   [ha,hp] = perigeeApogeeAltitude(keplerianState)
%   [ha,hp] = perigeeApogeeAltitude(cartesianState)
%   [ha,hp] = perigeeApogeeAltitude([X,Y,Z])
%Optional arguments: 'Radius', 'StandardGravitationalParameter'.
%By default the Earth's are used.

R = tesp.support.optionalArgument(tesp.constants.radius.earth,'Radius',varargin);
mu = tesp.support.optionalArgument(tesp.constants.standardGravitationalParameter.earth, ...
    'StandardGravitationalParameter',varargin);

% Load the states from a results object or directly from the first input argument
if isa(obj,'tesp.results')
    [states,cartesian] = tesp.support.getStatesFromResults(obj,1);
else
    states = obj;
    [~,m] = size(states);
    if m == 3
        cartesian = true;
    else
        tesp.support.assertValidState(states);
        cartesian = tesp.support.isCartesianState(states);
    end
end


% Transform to Keplerian components if necessary
if cartesian
    states = tesp.transform.cartesianToKeplerian(states,'StandardGravitationalParameter',mu);
end

% Obtain the apo and peri altitudes
a = states(:,1);
e = states(:,2);
hp = a.*(1-e) - R;
ha = a.*(1+e) - R;

