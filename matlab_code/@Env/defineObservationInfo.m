function obsInfo = defineObservationInfo()
%defineObservationInfo() is a static method that retuns the limits and
%dimension of the observation of the environment.
%The observation is defined as the concatenation of EMG features with
%cinematic info. The EMG features is a F-by-1 vector from EMG features.
%The cinematic info is a 4-by-1 vector with the encoder position of every
%motor.
%
% Examples
%   obsInfo = Env.defineObservation()
%

%{
Laboratorio de Inteligencia y Visión Artificial
ESCUELA POLITÉCNICA NACIONAL
Quito - Ecuador

autor: ztjona!
jonathan.a.zea@ieee.org

"I find that I don't understand things unless I try to program them."
-Donald E. Knuth

12 October 2021

Mod 2024/jan/3
%}

%% aux vars
%unpacking
params = configurables();
hardware = definitions();
disp(params)
numEMGFeatures = configurables("numEMGFeatures");
numMotors = hardware.numMotors;

stateLength = configurables("stateLength");
disp("statelength")
class(stateLength)
disp("statelength value")
disp(stateLength)

farMinEncoderValue = 0;
farMaxEncoderValue = 350;

EMGFeaturesMin = -inf;
EMGFeaturesMax = inf;

%% creating observation space
obsInfo = rlNumericSpec([44 1]); % col-wise


%% limits
obsInfo.LowerLimit = [EMGFeaturesMin*ones(numEMGFeatures, 1);
    repmat(farMinEncoderValue, numMotors, 1)];

obsInfo.UpperLimit = [EMGFeaturesMax*ones(numEMGFeatures, 1);
    repmat(farMaxEncoderValue, numMotors, 1)];

obsInfo.Name = 'prosthesis_state';
obsInfo.Description = sprintf(...
    'State defined with %d EMG features and %d encoder positions',...
    numEMGFeatures, numMotors);
