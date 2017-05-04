function bool = isCartesianState(states)
bool = any( any( states < 0 ) ) || any( states(:,2) > 1 ) || any( any( states(:,3:6) > 2*pi ) ) || ...
    any( sqrt(states(:,4).^2 + states(:,5).^2 + states(:,6).^2 ) > sqrt(3)*2*pi );

