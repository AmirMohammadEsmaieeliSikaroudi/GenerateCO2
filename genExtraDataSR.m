function [CO2s_vals,occPatterns]=genExtraDataSR(T,p1,p2,p3,p4,p5,p6,hl,uco2,suco2,sigma)
rng(1)
occPatterns(1,1:T)=0;
arrMat=[1-p1-p2,    p1,         p2;
    	p3,         1-p3-p4,    p4;
    	p5,         p6,         1-p5-p6];

alpha_socc=(suco2-uco2);
d1=1-2^(-1/(hl));

y(1,T)=0;% The CO2 values for each state and time step
y(1,1)=uco2;% Assuming that the first time step has fixed CO2 value for unoccupied

CO2s_vals(1,1:T)=0;
CO2s_vals(1,1)=uco2;

lastHigherThan3Occ=2;
for t=2:T
    occ_rnd=rand(1,1);
    prevOcc=occPatterns(1,t-1);
    if prevOcc>1
        prevOcc=2;
    end
	if occ_rnd<arrMat(prevOcc+1,1)
		occPatterns(1,t)=0;
	elseif occ_rnd<arrMat(prevOcc+1,1)+arrMat(prevOcc+1,2)
		occPatterns(1,t)=1;
    else
        if occPatterns(1,t-1)>1
            occPatterns(1,t)=lastHigherThan3Occ;
        else
		    lastHigherThan3Occ=round(rand(1,1)*3)+2;
            occPatterns(1,t)=lastHigherThan3Occ;
        end
    end

	expectedCO2=uco2+(alpha_socc)*(occPatterns(1,t));

	val1=y(1,t-1);
    y_t=val1+d1*(expectedCO2-(val1));

	CO2s_val=randn(1)*sigma+y_t;

    y(1,t)=y_t;

	CO2s_vals(1,t)=CO2s_val;
end
