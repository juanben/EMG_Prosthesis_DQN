function agent = agent_00_oldy(observationInfo, actionInfo)
%agent_00_oldy() creates the agent trained in prosthesis v1.
%
%

%{
Laboratorio de Inteligencia y Visión Artificial
ESCUELA POLITÉCNICA NACIONAL
Quito - Ecuador

autor: Jonathan Zea
jonathan.a.zea@ieee.org

"I find that I don't understand things unless I try to program them."
-Donald E. Knuth

03 January 2024
%}


%%
%numHiddenUnits = 14;
hL = @tanhLayer;

%% newtork
criticNetwork = [
    featureInputLayer(44, "Name", "observation") % Entrada con 44 características
    fullyConnectedLayer(128, "Name", "fc_1")    % Capa completamente conectada con 128 unidades
    hL("Name", "hL1")                           % Capa de activación tanh
    fullyConnectedLayer(128, "Name", "fc_2")    % Segunda capa completamente conectada con 128 unidades
    hL("Name", "hL2")                           % tanh
    fullyConnectedLayer(64, "Name", "fc_3")     % Tercera capa completamente conectada con 64 unidades
    hL("Name", "hL3")                           % tanh
    fullyConnectedLayer(32, "Name", "fc_4")     % Cuarta capa completamente conectada con 32 unidades
    hL("Name", "hL4")                           % tanh
    fullyConnectedLayer(81, "Name", "output")]; % Capa de salida con 81 unidades

 % ,'UseDevice','gpu'
opt = rlRepresentationOptions( ...
    'LearnRate', 1e-4, ... % default 0.01
    'L2RegularizationFactor', 1e-4... % default 1e-4
    , 'Optimizer', 'adam' ... % default adam
  );

% for adam
% opt.OptimizerParameters.GradientDecayFactor = 0.99; % Default 0.9
% for sgdm
opt.OptimizerParameters.Momentum = 0.85; % default 0.9

critic = rlQValueRepresentation(criticNetwork, observationInfo, ...
    actionInfo, 'Observation', {'observation'}, opt);

%% agent options
agentOptions = rlDQNAgentOptions(...
    'UseDoubleDQN', false, ... % default
    'SequenceLength', 1, ... % default, Maximum batch-training trajectory length when using a recurrent neural network for the critic, specified as a positive integer. This value must be greater than 1 when using a recurrent neural network for the critic and 1 otherwise.
    'TargetSmoothFactor',1e-4, ... % Smoothing factor for target critic updates, specified as a positive scalar less than or equal to 1.
    'TargetUpdateFrequency', 2, ... %def
    'ResetExperienceBufferBeforeTraining', false,...
    'SaveExperienceBufferWithAgent', true, ... % not default
    'MiniBatchSize', 32, ...
    'NumStepsToLookAhead', 1, ...
    'ExperienceBufferLength', 5000, ... % default
    'DiscountFactor', 0.998);% default

agentOptions.EpsilonGreedyExploration.EpsilonDecay = 5e-5;
agentOptions.EpsilonGreedyExploration.Epsilon = 1; % default
agentOptions.EpsilonGreedyExploration.EpsilonMin = 0.15; % default

agent = rlDQNAgent(critic, agentOptions);
