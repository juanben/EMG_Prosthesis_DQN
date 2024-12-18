function trainingInfo = trainInterface(agent_id, param_name, param_value)
%trainInterface runs the training with given agent and params.
%trainInterface() is intended to to train an agent via CLI. Training
%progress are stored in disk. View configs.
%
% # USAGE
% >> !matlab -r "trainInterface <agent_id> <param_name> <param_value>" &;
% >> info = trainInterface("00_random", "","");
%
% # INPUTS
%  agent_id   string of the agent name or id.
%  param_name   the agent is parametric in param.
%  param_value  string value of the param. Note, if it is num, it must be
%               converted in agent creation.
%
% # OUTPUTS
%(Also, training progress is stored in disk. View configs.)
%  trainingInfo     output from train, or sim.
%
%

%{
Laboratorio de Inteligencia y Visin Artificial
ESCUELA POLITCNICA NACIONAL
Quito - Ecuador

autor: Jonathan Zea
jonathan.a.zea@ieee.org

"I find that I don't understand things unless I try to program them."
-Donald E. Knuth

03 January 2024
%}

%% Input Validation
arguments
    agent_id        (1, 1) string
    param_name      (1, 1) string
    param_value     (1, 1) string
end

close all
clc
rng('default');

%% Aux and dependent variables
% libs
addpath(genpath('.\src'))
addpath(genpath('.\config'))
addpath(genpath('.\lib'))
addpath(genpath('.\agents'))

configs = configurables();
hardware = definitions();

%% Agent
%if configs.newTraining
if true
    %- creating agent
    observationInfo = Env.defineObservationInfo();
    actionInfo = Env.defineActionDiscreteInfo();

    agent = load_agent(observationInfo, actionInfo, ...
        agent_id, param_name, param_value);
else
    %- loading agent
    try
        aux = load(configs.agentFile, "agent");
        agent = aux.agent;
    catch
        aux = load(configs.agentFile, "saved_agent");
        agent = aux.saved_agent;
    end

    agent_id = configs.agent_id;
end


%% --- training options



% -- saving before training
if configs.flagSaveTraining
    % directory of the agent
    dir_generator = configs.agents_directory;
    agent_dir = dir_generator(agent_id, ...
        sprintf("%s_%s", param_name, param_value));

    mkdir(agent_dir);
    % save(fullfile(agent_dir, '01_env.mat'), "env");
    save(fullfile(agent_dir, '00_configs.mat'), ...
        "configs", "hardware" ...
        , "agent_id", "param_name", "param_value");
else
    agent_dir = [];
end

%% Env
if configs.usePrerecorded
    % --- load prerecorded EMGs
    % when ``usePrerecorded`` is false this line does not have effect
    [emg, glove] = getDataset(configs.dataset, configs.dataset_folder);

    env = Env(agent_dir, true, emg, glove);

    env.log(sprintf("agent dir: %s", agent_dir));

    if iscell(configs.dataset)
        dataset = strjoin(cellstr(configs.dataset));
    else
        dataset = configs.dataset;
    end
    env.log(sprintf("Loading datasets: %s", dataset));
else
    env = Env(agent_dir);
end

% % ---
% % env.prosthesis.goHomePosition(true,true);
% % drawnow;
% pos = env.prosthesis.read();
% env.log(sprintf("Reseting Initial position from [%d %d %d %d] to 0", ...
%     pos(end, 1), pos(end, 2), pos(end, 3), pos(end, 4)));
%
% env.prosthesis.resetEncoder(); % home position at zero
% drawnow

%% run the training or evaluation!
if configs.run_training
    % --- train
    opts = configs.RLtrainingOptions;
    opts.SaveAgentDirectory = agent_dir;

    env.log("Starting training!");
    trainingInfo = train(agent, env, opts);
else
    % --- evaluation
    simpOpts = configs.simOpts;
    env.log("Starting evaluation!");
    trainingInfo = sim(agent, env, simpOpts);
end


%% ---- saving
if configs.flagSaveTraining
    save(fullfile(agent_dir, "training_info.mat"), "trainingInfo");
end

