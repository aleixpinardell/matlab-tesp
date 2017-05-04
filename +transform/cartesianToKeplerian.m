function kepStates = cartesianToKeplerian(carStates,varargin)
mu = tesp.support.optionalArgument(tesp.constants.standardGravitationalParameter.earth, ...
    'StandardGravitationalParameter',varargin);

tesp.support.assertValidState(carStates);

% Get elements
X = carStates(:,1:3);
V = carStates(:,4:6);

r = normh(X);
v = normh(V);
kepStates = carStates;

for j = 1:length(r)
    h = cross(X(j,:),V(j,:));
    N = cross([0;0;1],h);

    a = 1/(2/r(j) - v(j)^2/mu);
    e = 1/mu*cross(V(j,:),h) - X(j,:)/r(j);
    i = acos(h(3)/norm(h));
    Nxy = sqrt(N(1)^2 + N(2)^2);
    raan = atan2(N(2)/Nxy,N(1)/Nxy);

    NN = N/norm(N);
    ee = e/norm(e);
    omega = sign(dot(cross(NN,e),h))*real(acos(dot(ee,NN)));
    f = sign(dot(cross(e,X(j,:)),h))*real(acos(dot(X(j,:)/r(j),ee)));

    e = norm(e);
    if isnan(raan) % If the raan is not defined, assign (arbitrary) 0 value
        raan = 0;
    else
        raan = mod(raan,2*pi);
    end
    if isnan(omega) % If omega is not defined, assign (arbitrary) 0 value
        omega = 0;
    else
        omega = mod(omega,2*pi);
    end
    f = mod(f,2*pi);

    kepStates(j,1) = a;
    kepStates(j,2) = e;
    kepStates(j,3) = i;
    kepStates(j,4) = omega;
    kepStates(j,5) = raan;
    kepStates(j,6) = f;
end
