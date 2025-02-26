%using_tics runs the recorded glove using tics
% valid unitl commit 4c7c979

%{
Laboratorio de Inteligencia y Visión Artificial
ESCUELA POLITÉCNICA NACIONAL
Quito - Ecuador

autor: Laboratorio IA
jonathan.a.zea@ieee.org

"I find that I don't understand things unless I try to program them."
-Donald E. Knuth

01 April 2024
%}

cc
%% Configs
configs.dataset_folder = '.\data\datasets\Denis Dataset\';
configs.dataset = {"BLANCA", "CECILIA", "DENIS", "EMILIA", "GABI", "GABRIEL", "IVANNA", "JOE", "JONATHAN", "KHAROL", "MATEO", "SANDRA"}; % or a cell of names.

[emg, gloveDataset] = getDataset(configs.dataset, configs.dataset_folder);

%% Aux and dependent variables
% libs
addpath(genpath('src'))


%% 
glove_sample = gloveDataset{14};
glove = RecordedGlove(glove_sample)
glove.resetBuffer
pause(1)
rr = glove.read

figure,
plot([glove_sample.indexUp])

figure,
plot([rr.indexUp])