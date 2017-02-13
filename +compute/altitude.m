function h = altitude(obj,varargin)
%Determine the altitude [m] from a results object or from a state:
%   h = altitude(tesp.results)
%   h = altitude(keplerianState)
%   h = altitude(cartesianState)
%   h = altitude([X,Y,Z])
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


% Transform to Cartesian components if necessary
if ~cartesian
    states = tesp.transform.keplerianToCartesian(states);
end

% Obtain the altitudes
positions = states(:,1:3);  % Get [x,y,z]
r = tesp.support.normPerRows(positions);  % Obtain the distances from the centre of the central body
h = r - R;

