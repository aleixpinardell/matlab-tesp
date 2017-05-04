function f = fromEccentric(E,e)

f = 2*atan(tan(E/2).*sqrt((1+e)./(1-e)));
f = mod(f,2*pi);