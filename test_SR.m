clc
clear

CO2_socc=414.5874;
CO2_uocc=368.1877;
hl=42.47;
sigma=1.374;
p1=0.002;
p2=0.002;
p3=0.01;
p4=0.001;
p5=0.01;
p6=0.01;
[genExtraCO2,occPatterns]=genExtraDataSR(10000,p1,p2,p3,p4,p5,p6,hl,CO2_uocc,CO2_socc,sigma);
figure(1)
clf
hold on
plot(genExtraCO2)
plot(occPatterns*20+CO2_uocc)


CO2_socc=385.8327;
CO2_uocc=361.34;
hl=58.45;
sigma=1.048;
p1=0.002;
p2=0.002;
p3=0.01;
p4=0.001;
p5=0.01;
p6=0.01;
[genExtraCO2,occPatterns]=genExtraDataSR(10000,p1,p2,p3,p4,p5,p6,hl,CO2_uocc,CO2_socc,sigma);
figure(2)
clf
hold on
plot(genExtraCO2)
plot(occPatterns*20+CO2_uocc)