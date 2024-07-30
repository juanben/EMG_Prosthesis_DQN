% Enhanced Wavelength
function EWL=WMoos_F8(X)
L=length(X); EWL=0;
for i=2:L
    if i >= 0.2*L && i <= 0.8*L
        p=0.75;
    else
        p=0.5;
    end
    EWL=EWL+abs((X(i)-X(i-1))^p);
end
end