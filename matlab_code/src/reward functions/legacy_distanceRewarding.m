function [reward, rewardVector, action] = legacy_distanceRewarding(this, action)

persistent previousPosFlex inactiveSteps

if isempty(previousPosFlex)
    previousPosFlex = zeros(size(action)); % Inicializa el registro de posición
end
if isempty(inactiveSteps)
    inactiveSteps = 0; % Inicializa el contador de inactividad
end

%% Configuración de recompensas
opts.k = 3; % Penalización suavizada por distancia
rewards.dirInverse = -5; % Penalización por moverse en dirección incorrecta
rewards.wrongStop = -15; % Penalización por detenerse incorrectamente
rewards.goodMove = 15; % Recompensa por moverse en la dirección correcta
rewards.goodMove2 = 1;
rewards.inactivityPenalty = -2; % Penalización base por inactividad
rewards.moveIncentive = 5; % Incentivo por moverse
rewards.precisionBonus = 10; % Bonificación por precisión
rewards.smoothnessPenalty = -3; % Penaliza cambios bruscos
rewards.efficiencyBonus = 3; % Bonificación por movimientos suaves

rewardVector = zeros(1, 4);

%% Lectura del estado actual
if this.c == 1
    flexConv = this.flexJoined_scaler(reduceFlexDimension(this.flexData));
else
    flexConv = this.flexConvertedLog{this.c - 1};
end
pos = this.motorData(end, :);
posFlex = this.flexJoined_scaler(encoder2Flex(pos));
% disp('posision motor')
% disp(pos)
% disp('previousPosFlex')
% disp(previousPosFlex)
% disp('posFlex')
% disp(posFlex)
% disp('flexConv')
% disp(flexConv)
%% Evaluación de recompensa por cada motor
for i = 1:length(action)
    if posFlex(i) < flexConv(end, i)
        correctAction = 1;  % Mover hacia adelante
    elseif posFlex(i) > flexConv(end, i)
        correctAction = -1; % Mover hacia atrás
    else
        correctAction = 0;  % Mantenerse en su lugar
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

    % Calcular la pendiente del movimiento
    slope = (posFlex(i) - previousPosFlex(i));
    
    % Penalizar cambios bruscos con menor impacto
    rewardVector(i) = rewardVector(i) + rewards.smoothnessPenalty * sqrt(abs(slope));
    
    % Bonificar movimientos eficientes con menor impacto
    if abs(slope) > 0.01 && abs(slope) < 0.5
        rewardVector(i) = rewardVector(i) + rewards.efficiencyBonus;
    end
end

% Actualizar el registro de posición
previousPosFlex = posFlex;

%% Penalizacion acumulada por inactividad
if all(action == 0) && correctAction ~= 0  % Si todas las acciones son cero (no movimiento)
    inactiveSteps = inactiveSteps + 1; % Incrementar el contador de inactividad
    penalty = rewards.inactivityPenalty * inactiveSteps; % Penalización acumulada
    rewardVector = rewardVector + penalty; % Aplicar la penalización acumulada
else
    inactiveSteps = 0; % Reiniciar el contador de inactividad si se mueve
end

% Incentivar movimiento si el agente no se queda inactivo
if any(action ~= 0)
    rewardVector = rewardVector + rewards.moveIncentive;
end

% Penalización más moderada por distancia usando raíz cuadrada
distance = abs(posFlex - flexConv(end, :));
rewardVector = rewardVector - sqrt(distance) .* opts.k;

% Bonificación suavizada si la distancia es menor a un umbral
precisionMask = distance < 0.05; % Si la distancia es menor a 5% del rango
rewardVector(precisionMask) = rewardVector(precisionMask) + rewards.precisionBonus / 2;

% Calcular la recompensa total con menor varianza
reward = mean(rewardVector);

end
