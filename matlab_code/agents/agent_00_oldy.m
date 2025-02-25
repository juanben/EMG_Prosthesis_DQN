function agent = agent_00_oldy(observationInfo, actionInfo)
% Configuración de Red Neuronal con Dropout para Regularización
hL = @reluLayer;  % Activación tanh
numActions = numel(actionInfo.Elements);
disp(numActions)
criticNetwork = [
    featureInputLayer(44, "Name", "observation")  % Entrada con 44 características
    fullyConnectedLayer(64, "Name", "fc_1")
    hL("Name", "hL1")  % Tanh
    dropoutLayer(0.1, "Name", "dropout1") % Apaga el 20% de las neuronas
    fullyConnectedLayer(32, "Name", "fc_2")
    hL("Name", "hL2")
    dropoutLayer(0.1, "Name", "dropout2") 
    fullyConnectedLayer(32, "Name", "fc_3")
    hL("Name", "hL3")
    fullyConnectedLayer(numActions, "Name", "output") % 81 acciones posibles
];

% Opciones del optimizador ajustadas
opt = rlRepresentationOptions( ...
    'LearnRate', 1e-4, ... % Reducimos la tasa de aprendizaje
    'L2RegularizationFactor', 5e-5, ... % Regularización ligera
    'Optimizer', 'adam' ...
);

% Configuración del optimizador Adam
opt.OptimizerParameters.GradientDecayFactor = 0.95;
opt.OptimizerParameters.Momentum = 0.95;

critic = rlQValueRepresentation(criticNetwork, observationInfo, ...
    actionInfo, 'Observation', {'observation'}, opt);

%% Opciones del Agente DQN
agentOptions = rlDQNAgentOptions(...
    'UseDoubleDQN', true, ...
    'SequenceLength', 1, ...
    'TargetUpdateMethod','smoothing', ...
    'TargetSmoothFactor', 0.05, ...
    'TargetUpdateFrequency', 3, ...
    'ResetExperienceBufferBeforeTraining', false,...
    'SaveExperienceBufferWithAgent', true, ...
    'MiniBatchSize', 32, ...
    'NumStepsToLookAhead', 2, ...
    'ExperienceBufferLength', 5000, ...
    'DiscountFactor', 0.995);

% Exploración-Explotación ajustada
agentOptions.EpsilonGreedyExploration.EpsilonDecay =15e-5;
agentOptions.EpsilonGreedyExploration.Epsilon = 1;
agentOptions.EpsilonGreedyExploration.EpsilonMin = 0.001;

agent = rlDQNAgent(critic, agentOptions);
end
