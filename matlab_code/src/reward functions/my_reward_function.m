function [reward, rewardVector, action] = improved_distanceRewarding(this, action)

persistent previousPosFlex

if isempty(previousPosFlex)
    previousPosFlex = zeros(size(action)); % Inicializa el registro de posición
end

%% Configuración de recompensas
opts.k = 10; % Penalización por distancia (más suave que antes)
rewards.dirInverse = -10; % Más severa para evitar movimientos incorrectos
rewards.wrongStop = -5; % Mantiene una penalización equilibrada
rewards.goodMove = 20; % Reduce la recompensa, pero sigue favoreciendo el buen movimiento
rewards.goodMove2 = 10;
rewards.inactivityPenalty = -2; % Penaliza menos la inactividad
rewards.moveIncentive = 2; % Reduce incentivo por moverse sin razón
rewards.precisionBonus = 15; %  

rewardVector = zeros(1, 4);

%% Lectura del estado actual
if this.c == 1
    flexConv = this.flexJoined_scaler(reduceFlexDimension(this.flexData));
else
    flexConv = this.flexConvertedLog{this.c - 1};
end
pos = this.motorData(end, :);
posFlex = this.flexJoined_scaler(encoder2Flex(pos));

%% Evaluación de recompensa por cada motor
for i = 1:length(action)

    % Determinar la acción correcta
    if previousPosFlex(i) < posFlex(i)
        correctAction = 1;
    elseif previousPosFlex(i) > posFlex(i)
        correctAction = -1;
    else
        correctAction = 0;
    end

    % Aplicar recompensas y penalizaciones
    if action(i) == correctAction
        if action(i) ~= 0
            rewardVector(i) = rewards.goodMove;
        else
            rewardVector(i) = rewards.goodMove2;
        end
    elseif action(i) == 0
        rewardVector(i) = rewards.wrongStop;
    else
        rewardVector(i) = rewards.dirInverse;
    end
end

% Actualizar el registro de posición
previousPosFlex = posFlex;

% Incentivar movimiento si el agente no se queda inactivo
if any(action ~= 0)
    rewardVector = rewardVector + rewards.moveIncentive;
end

% Penalización más moderada por distancia
distance = abs(posFlex - flexConv(end, :));
rewardVector = rewardVector - distance .* opts.k;

%Bonificación si la distancia es menor a un umbral
precisionMask = distance < 0.05; % Si la distancia es menor a 5% del rango
rewardVector(precisionMask) = rewardVector(precisionMask) + rewards.precisionBonus;

% Calcular la recompensa total
reward = mean(rewardVector);

end
