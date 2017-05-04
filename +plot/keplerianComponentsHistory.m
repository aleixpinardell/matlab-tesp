function fig = keplerianComponentsHistory(obj,varargin)

mu = tesp.support.optionalArgument(tesp.constants.standardGravitationalParameter.earth, ...
    'StandardGravitationalParameter',varargin);

t_units = tesp.support.optionalArgument('date','TimeUnits',varargin);

% Support for plotting multiple cases
if isa(obj,'cell')
    objs = obj;
else
    objs = {obj};
end

% Load the states from a results object or directly from the first input argument
for i = 1:length(objs)
    obj = objs{i};
    if isa(obj,'tesp.results')
        t = obj.epochs;
        [states,cartesian] = tesp.support.getStatesFromResults(obj,0);
    else
        t = obj(:,1);
        states = obj(:,2:7);
        tesp.support.assertValidState(states);
        cartesian = tesp.support.isCartesianState(states);
    end
    
    % Transform to Keplerian components if necessary
    if cartesian
        states = tesp.transform.cartesianToKeplerian(states,'StandardGravitationalParameter',mu);
    end
    
    % Convert time
    t = tesp.transform.epochTo(t,t_units);
    if strcmpi(t_units,'date')
        xl = '';
    else
        xl = sprintf('Time [%s]',t_units);
    end
        
    subplot(2,3,1);
    hold on;
    plot(t,states(:,1)/1e3);
    grid on;
    xlabel(xl);
    ylabel('Semi-major axis [km]');
    
    subplot(2,3,2);
    hold on;
    plot(t,states(:,2));
    grid on;
    xlabel(xl);
    ylabel('Eccentricity [-]');
    
    subplot(2,3,3);
    hold on;
    plot(t,rad2deg(states(:,3)));
    grid on;
    xlabel(xl);
    ylabel('Inclination [deg]');
    
    subplot(2,3,4);
    hold on;
    plot(t,rad2deg(states(:,4)));
    grid on;
    xlabel(xl);
    ylabel('Argument perigee [deg]');
    
    subplot(2,3,5);
    hold on;
    plot(t,rad2deg(states(:,5)));
    grid on;
    xlabel(xl);
    ylabel('Longitude ascending node [deg]');
    
    subplot(2,3,6);
    hold on;
    plot(t,rad2deg(states(:,6)));
    grid on;
    xlabel(xl);
    ylabel('True anomaly [deg]');
end

fig = gcf;
