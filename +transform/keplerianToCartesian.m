function carStates = keplerianToCartesian(kepStates,varargin)
mu = tesp.support.optionalArgument(tesp.constants.standardGravitationalParameter.earth, ...
    'StandardGravitationalParameter',varargin);

tesp.support.assertValidState(kepStates);

% Get elements
a = kepStates(:,1);
e = kepStates(:,2);
i = kepStates(:,3);
omega = kepStates(:,4);
raan = kepStates(:,5);
f = kepStates(:,6);

if e >= 1 % if parabollic or hyperbolic orbit, break
    error('The eccentricity must be smaller than 1.');
end

% Compute needed parameters for the transformation
r = a.*(1 - e.^2)./(1 + e.*cos(f));
rc = r.*cos(f);
rs = r.*sin(f);
H = sqrt(mu*a.*(1 - e.^2));

l1 = cos(raan).*cos(omega) - sin(raan).*sin(omega).*cos(i);
l2 = -cos(raan).*sin(omega) - sin(raan).*cos(omega).*cos(i);
m1 = sin(raan).*cos(omega) + cos(raan).*sin(omega).*cos(i);
m2 = -sin(raan).*sin(omega) + cos(raan).*cos(omega).*cos(i);
n1 = sin(omega).*sin(i);
n2 = cos(omega).*sin(i);

carStates = kepStates;
for j = 1:length(r)
    % Determine position vector
    X = [l1(j) l2(j); m1(j) m2(j); n1(j) n2(j)]*[rc(j); rs(j)];
    carStates(j,1:3) = X;
    
    % Determine velocity vector
    v_x = mu/H(j)*(-l1(j)*sin(f(j)) + l2(j)*(e(j) + cos(f(j))));
    v_y = mu/H(j)*(-m1(j)*sin(f(j)) + m2(j)*(e(j) + cos(f(j))));
    v_z = mu/H(j)*(-n1(j)*sin(f(j)) + n2(j)*(e(j) + cos(f(j))));
    carStates(j,4:6) = [v_x v_y v_z];
end
