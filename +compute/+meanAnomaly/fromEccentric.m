function M = fromEccentric(E,e)

M = E - e.*sin(E);
M = mod(M,2*pi);