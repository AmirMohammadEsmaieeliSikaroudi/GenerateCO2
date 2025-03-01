function [outputCO2,outputOcc,bestLoss]=inference_Viterbi_NV(pOcc, hl, CO2_uocc, CO2_socc, sigma, obs_CO2)
numStates=10;% Maximum number of occupants is # - 1

% Construct the transition matrix
arrMat=[1-pOcc(1,1)-pOcc(1,2),  pOcc(1,1),              pOcc(1,2);
    pOcc(1,3),              1-pOcc(1,3)-pOcc(1,4),  pOcc(1,4);
    pOcc(1,5),              pOcc(1,6),              1-pOcc(1,5)-pOcc(1,6)];

% Ensure the transition matrix is valud
for i=1:size(arrMat,1)
    for j=1:size(arrMat,2)
        arrMat(i,j)=abs(arrMat(i,j));
    end
    rSum=sum(arrMat(i,:));
    arrMat(i,:)=arrMat(i,:)/rSum;
end

% Calculate the cimulative probability for each row of the transition matrix
stateProbCum(size(arrMat,1),size(arrMat,2))=0;
for r=1:size(arrMat,1)
    stateProbCum(r,1)=arrMat(r,1);
    for i=2:size(arrMat,2)
        stateProbCum(r,i)=stateProbCum(r,i-1)+arrMat(r,i);
    end
end

T=size(obs_CO2,2);% Sequence length

S=numStates;% Number of steps

P_states(S,T)=0;% Matrix for tracing back in Viterbi
F_values(S,T)=0;% Matrix for forward pass
F_values(1:S,1)=1;% The initial values for time step 1
Full_path(1,T)=0;% The final occupancy sequences
Full_path(1,1)=1;% Assuming that the first time step has 0 occupancy
y(S,T)=0;% The CO2 values for each state and time step
y(1:S,1)=CO2_uocc;% Assuming that the first time step has fixed CO2 value for unoccupied
for t=2:T
    for occVal=1:numStates
        % for winVal=1:2
        F_valuesTemp=[];
        F_valuesTemp(S,1)=0;% Initializing the stage values calculated from previous stage
        internalYValues=[];
        internalYValues(S,1)=0;% Initializing the CO2 values for each combination of stage recursion
        for s=1:S
            prevOcc=mod(s-1,numStates)+1;

            alpha_socc=(CO2_socc-CO2_uocc);

            d=1-2^(-1/(hl));

            expectedCO2=CO2_uocc+(alpha_socc)*(occVal-1);

            if t>1
                val=y(s,t-1);
                y_t=val+d*(expectedCO2-(val));
            else
                y_t=CO2_uocc;
            end
            CO2s_val=randn(1)*sigma+y_t;
            likelihoodCO2=exp(-0.5 * ((obs_CO2(1,t) - y_t)./sigma).^2) ./ (sqrt(2*pi) .* sigma);

            occValD=occVal;
            if occValD>3
                occValD=3;
            end
            if prevOcc>3
                prevOcc=3;
            end
            likelihoodOcc=arrMat(prevOcc,occValD);

            likelihoodTotal=likelihoodCO2*likelihoodOcc+1;% Avoid numerical issues by adding 1

            F_valuesTemp(s,1)=(log(likelihoodTotal))+((F_values(s,t-1)));% Adding previous stage to current stage

            internalYValues(s,1)=y_t;
        end
        currState=occVal;
        [val,bestPrevState]=max(F_valuesTemp(:,1));% Select the maximum value and index
        F_values(currState,t)=val;% Store the likelihood value
        P_states(currState,t)=bestPrevState;% Store the path i.e. from which state we have achieved the current state
        y(currState,t)=internalYValues(bestPrevState,1);% Select the best CO2 value for the next time step calculation
    end
    % end
end

[bestLoss,I]=max(F_values(:,T));% Start from the highest likely state at the end of the sequence
Full_path(1,T)=I;% Store the best state index
prevI=P_states(I,T);% Select the previous state
Full_path(1,T-1)=prevI;
for t=T-1:-1:2% Move backwards to store all states
    prevI=P_states(prevI,t);
    Full_path(1,t-1)=prevI;
end

% Convert states into occupancy values
outputOcc(1,T)=0;
outputCO2(1,T)=0;
outputCO2(1,1)=CO2_uocc;
for t=2:T
    occVal=Full_path(1,t)-1;
    outputOcc(1,t)=occVal;
    outputCO2(1,t)=y(Full_path(1,t),t);
end