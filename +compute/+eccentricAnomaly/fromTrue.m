function E = fromTrue(f,e)

E = 2*atan(tan(f/2).*sqrt((1-e)./(1+e)));
E = mod(E,2*pi);