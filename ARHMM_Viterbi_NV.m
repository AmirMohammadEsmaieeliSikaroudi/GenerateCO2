clc
clear

% This code implements a simple Simulated Annealing approach to optimize
% the parameters. At each iteration Vitervi training is used to obtain the
% most likely states.

isContinueLearning=1;% If set to 0, the parameters are initialized randomly, if set to 1, the parameters start from the last run that they were saved as a file

%\/\/\/ LOAD DATASET
rawData=table2array(readtable('syntheticData_threeState_NV.csv'));
lastSaveSuffix="syntheticData";% This is the name of the file to save as a
% checkpoint for the optimized parameters

CO2_ColumnIndex=1;
obs_CO2=rawData(:,CO2_ColumnIndex);
obs_CO2=obs_CO2';
[obs_CO2_smoothed,cost] = tvd_mm(obs_CO2,50,100);
figure(1)
clf
hold on
plot(obs_CO2)
plot(obs_CO2_smoothed)
obs_CO2=obs_CO2_smoothed';
occupancy_ColumnIndex=2;
testOcc=rawData(:,occupancy_ColumnIndex);
testOcc=testOcc';
%^^^ LOAD DATASET


numVars=10;% Even if number of variables are less than actual number of variables, there won't be any problem. It'll extend as it goes.
x(1,numVars)=0;
constraints(2,numVars)=0;

% The range for parameters to search for finding the optimal likelihood.
% First row is the lower bound
% Second row is the upper bound
% IMPORTANT NOTE: HMM is unable to find realistic parameters if it is not
% anchored for some parameters. We assume that CO2 level for unoccupied
% state, CO2 generation for a single person, and occupancy change chances
% are relatively known (narrow range). For instance, we know that a 
% meeting high-likely won't end in a 5 minutes. If a large range is
% selected for the mentioned two parameters, HMM may find an unrealistic
% solution.
constraints(1,1)=0.01;% p1
constraints(2,1)=0.2;
constraints(1,2)=0.01;% p2
constraints(2,2)=0.2;
constraints(1,3)=0.01;% p3
constraints(2,3)=0.2;
constraints(1,4)=0.01;% p4
constraints(2,4)=0.2;
constraints(1,5)=0.01;% p5
constraints(2,5)=0.2;
constraints(1,6)=0.01;% p6
constraints(2,6)=0.2;
constraints(1,7)=20;% half life
constraints(2,7)=200;
constraints(1,8)=395;% unoccupied CO2 level
constraints(2,8)=405;
constraints(1,9)=590;% single occupied CO2 level
constraints(2,9)=610;
constraints(1,10)=20;% Sigma (variation in the observation due to noise)
constraints(2,10)=50;

if isContinueLearning==0% Checks if we continue from last best solution or start from random solution
    for i=1:size(constraints,2)
        x(1,i)=constraints(1,i)+rand(1,1)*(constraints(2,i)-constraints(1,i));% Make random numbers between lower bound and upper bound.
    end
    if x(1,8)>x(1,9)% Swap unoccupied and single occupancy CO2 parameters if single occupancy is smaller
        temp=x(1,8);
        x(1,8)=x(1,9);
        x(1,9)=temp;
    end
    bestX=x;% Just assume that the initial parameters are the best parameters we have so far
else
    load(strcat('lastSolution',lastSaveSuffix,'.mat'))% Load parameters from a file we saved before
    x=bestX;
end
maxLL=-inf;% The best likelihood value is initially -infinity
temperature=0.4;% This is used in Simulated Annealing Meta-Heuristic for optimizing the parameters
maxIter=120;% The number of iterations to run Simulated Annealing
occNoises(1,maxIter)=0;% Varaible to store noise in estimated occupancies
temps(1,maxIter)=0;% Variable to store the temperature in Simulated Annealing
for iter=1:maxIter
    if iter>1
        x=genSol(constraints,temperature,bestX);% Generate a new set of parameters based on temperature and previous best solution
    end
    % The parameters are separated from the vector of parameters in x
    pOcc=[x(1,1) x(1,2) x(1,3) x(1,4) x(1,5) x(1,6)];
    hl=x(1,7);
    CO2_uocc=x(1,8);
    CO2_socc=x(1,9);
    sigma=x(1,10);

    % Run the viterbi algorithm here to get the best sequence given the fixed parameters
    [generatedCO2s,generatedOcc,llValue]=inference_Viterbi_NV(pOcc, hl, CO2_uocc, CO2_socc, sigma, obs_CO2);
    occ_state=generatedOcc;
    occ_state(occ_state>2)=2; % Convert the number of occupants into 3 states
    occStateSmoothed=[];
    occStateSmoothed(1,size(occ_state,2))=0;% Smooth the output by a sliding window
    windowSize=4;% Window size
    for i=1:size(occ_state,2)
        if i>=windowSize+1 && i<=size(occ_state,2)-windowSize-1
            occStateSmoothed(1,i)=mode(occ_state(1,i-windowSize:i+windowSize));% Take mode of the values in the window
        else
            occStateSmoothed(1,i)=occ_state(1,i);
        end
    end

    occNoise=occNoiseMeasure(occStateSmoothed,6);% Calculate the noise of occupancy vector
    occNoises(1,iter)=occNoise;

    if maxLL<llValue% If the likelihood value current parameter set is better than best likelihood value
        bestX=x;% Store best parameter set
        bestOccState=occ_state;% Store the best occupancy sequence
        bestCO2s=generatedCO2s;% Store the best CO2 values
        maxLL=llValue% Store the best likelihood value
    end
    
    if temperature<0.01% If temperature is less than a small value, reset the temperature
        temperature=temperature+0.9;
        disp('Still Occ has not converged!!!')
    end
    if temperature>0.4% Use different temperature reduction schemes
        temperature=temperature*0.92;
    elseif temperature>0.1
        temperature=temperature*0.94;
    else
        temperature=temperature*0.95;
    end
    temps(1,iter)=temperature;

    % Show plots of likelihood and temperature
    figure(4)
    clf
    hold on
    plot(occNoises)
    figure(5)
    clf
    hold on
    plot(temps)
end

% Plot final Occupancy states and CO2
figure(2)
clf
hold on
plot(bestCO2s)
plot(bestOccState*100+300)
% plot(bestWinState*100+550)
plot(obs_CO2)
plot(testOcc*120+340)

confusionmat(testOcc,bestOccState)% Calculte confusion matrix

bestOccStateSmoothed(1,size(bestOccState,2))=0;% Smooth the final occupancy sequence
windowSize=8;
for i=1:size(bestOccState,2)
    if i>=windowSize+1 && i<=size(bestOccState,2)-windowSize-1
        bestOccStateSmoothed(1,i)=mode(bestOccState(1,i-windowSize:i+windowSize));
    else
        bestOccStateSmoothed(1,i)=bestOccState(1,i);
    end
end

plot(bestOccStateSmoothed*130+340)% Plot smoothed occupancy states
legend('CO2 generated','occ generated','CO2 obs','occ obs','occ gen smoothed')
cfm=confusionmat(testOcc,bestOccStateSmoothed)% Recalculate confusion matrix
acc=sum(diag(cfm))/sum(sum(cfm))% Report the accuracy
save(strcat('lastSolution',lastSaveSuffix,'.mat'),"bestX")% Save the best parameter values on a file
x=bestX;

% The parameters are separated from the vector of parameters in x just to
% see them in the workspace
pOcc=[x(1,1) x(1,2) x(1,3) x(1,4) x(1,5) x(1,6)];
hl=x(1,7);
CO2_uocc=x(1,8);
CO2_socc=x(1,9);
sigma=x(1,10);