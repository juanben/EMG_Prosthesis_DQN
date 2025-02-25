% classdef Controller < handle
%     %Controller is a class that handles communication with Wemos D1 ESPR32
%     %via Bluetooth or serial.
% 
%     %{
%     Laboratorio de Inteligencia y Visión Artificial
%     ESCUELA POLITÉCNICA NACIONAL
%     Quito - Ecuador
% 
%     autor: ztjona!
%     jonathan.a.zea@ieee.org
% 
%     "I find that I don't understand things unless I try to program them."
%     -Donald E. Knuth
%     %}
% 
%     %%
%     properties (Access=public)
%         device (1,1) {isa(device, 'bluetooth')}% bluetooth object
%     end
% 
%     properties (Hidden=true)
%         isConnected = false;
%         port;
%         baudRate;
%     end
% 
%     properties (Hidden=true, Constant)
%         timeout = 2; % in seconds to wait bluetooth message
%         terminatorRead = 'CR/LF'; % carriage return, line feed
%         terminatorWrite = 'LF'; % line feed
%         motorsPosDir = {'A', 'B', 'C', 'D'};
%         motorsNegDir = {'a', 'b', 'c', 'd'};
%     end
% 
%     methods
%         %% Constructor
%         % -----------------------------------------------------------------
%         function obj = Controller(bluetoothFlag,blName,COMport,baudRate)
%             %Controller(...) constructor, connects with Bluetooth device by
%             %name
%             %
%             %# Inputs
%             %*ble       -bool, flag to determine type of connection.
%             %* blName   -char with the name of the bluetooth device, by
%             %           default is 'prosthesisEPN'.
%             %
%             %# Outputs
%             %
% 
%             % # ---- Data Validation
%             arguments
%                 bluetoothFlag (1,1) logical = false;
%                 blName   (1, :) char = 'Prosthesis_EPN_v2';
%                 COMport (1, :) char = 'COM5';
%                 baudRate (1, 1) double = 250000;
%             end
% 
%             % #
%             if bluetoothFlag
%                 % bluetooth connection
%                 obj.device = bluetooth(blName);
%                 obj.device.Timeout = obj.timeout;
%                 obj.device.configureTerminator(...
%                     obj.terminatorRead, obj.terminatorWrite);
% 
%             else
%                 % serial connection
%                 obj.port = COMport;
%                 obj.baudRate = baudRate;
%                 obj.connect_serial();
%             end
% 
%             pause(10)
%         end
%         %%
%         % -----------------------------------------------------------------
%         function completed = closeHand(obj)
%             %obj.closeHand() sends the close hand command.
%             %
%             %# Inputs
%             %
%             %# Outputs
%             %* completed    -bool when true was correct, otherwise false.
%             %
%             completed = obj.send("C:");
%         end
% 
%         %%
%         % -----------------------------------------------------------------
%         function completed = openHand(obj)
%             %obj.openHand() sends the open hand command.
%             %
%             %# Inputs
%             %
%             %# Outputs
%             %* completed    -bool when true was correct, otherwise false.
%             %
%             completed = obj.send("C:");
%         end
% 
% 
%         %%
%         % -----------------------------------------------------------------
%         function completed = sendAllSpeed(obj, pwm1, pwm2, pwm3, pwm4)
%             %obj.sendAllSpeed() sends via Bluetooth the 4 pwm commands
%             %
%             %# Inputs
%             %* pwm1,2,3,4     -double with PWM speed to motors, negative
%             %                   means reverse direction
%             %
%             %# Outputs
%             %* completed    -bool when true was correct, otherwise false.
%             %
% 
%             % # ---- Data Validation
%             arguments
%                 obj
%                 pwm1 (1,1) double {mustBeInRange(pwm1, -255, 255)}
%                 pwm2 (1,1) double {mustBeInRange(pwm2, -255, 255)}
%                 pwm3 (1,1) double {mustBeInRange(pwm3, -255, 255)}
%                 pwm4 (1,1) double {mustBeInRange(pwm4, -255, 255)}
%             end
% 
%             % # ----
%             mt1 = getMotorCode(obj, 1, pwm1);
%             mt2 = getMotorCode(obj, 2, pwm2);
%             mt3 = getMotorCode(obj, 3, pwm3);
%             mt4 = getMotorCode(obj, 4, pwm4);
%             msj = sprintf('%c%s%c%s%c%s%c%s', ...
%                 mt1, dec2hex(abs(pwm1), 2), ...
%                 mt2, dec2hex(abs(pwm2), 2), ...
%                 mt3, dec2hex(abs(pwm3), 2),...
%                 mt4, dec2hex(abs(pwm4), 2));
% 
%             completed = obj.send(msj);
%         end
% 
%         %%
%         % -----------------------------------------------------------------
%         function completed = sendSpeed(obj, motor, pwm)
%             %obj.sendSpeed() sends via Bluetooth a pwm command of a motor
%             %
%             %# Inputs
%             %* motor          - double between 1 and 4
%             %* pwm            -double with PWM speed to motors, negative
%             %                   means reverse direction
%             %
%             %# Outputs
%             %* completed    -bool when true was correct, otherwise false.
%             %
% 
%             % # ---- Data Validation
%             arguments
%                 obj
%                 motor (1,1) double {mustBeInRange(motor, 1, 4)}
%                 pwm (1,1) double {mustBeInRange(pwm, -255, 255)}
%             end
% 
%             % # ----
%             mtCode = getMotorCode(obj, motor, pwm);
%             msj = sprintf('%c%s', mtCode, dec2hex(abs(pwm), 2));
%             completed = obj.send(msj);
%         end
% 
%         %%
%         % -----------------------------------------------------------------
%         function completed = changePeriod(obj, msPeriod)
%             %obj.changePeriod() sends the new period for
%             %sending the encoders position
%             %
%             %# Inputs
%             %* msPeriod     -double. the ESP32 will send the encoders
%             %               position each period in ms
%             %
%             %# Outputs
%             %* completed    -bool when true was correct, otherwise false.
%             %
% 
%             % # ---- Data Validation
%             arguments
%                 obj
%                 msPeriod (1,1) double {mustBePositive, mustBeInteger}
%             end
% 
%             msj = sprintf('P%d', msPeriod);
%             completed = obj.send(msj);
%         end
% 
%         %%
%         % -----------------------------------------------------------------
%         function completed = resetEncoder(obj, v1, v2, v3, v4)
%             %obj.resetEncoder() resets the encoder values
%             %
%             %# Inputs
%             %* v1,2,3,4  -int the new value for each encoder
%             %
%             %# Outputs
%             %* completed    -bool when true was correct, otherwise false.
%             %
% 
%             % # ---- Data Validation
%             arguments
%                 obj
%                 v1(1,1) double {mustBeInteger} = 0;
%                 v2(1,1) double {mustBeInteger} = 0;
%                 v3(1,1) double {mustBeInteger} = 0;
%                 v4(1,1) double {mustBeInteger} = 0;
%             end
%             if v1 == 0 && v2 == 0&& v3 == 0 && v4 == 0
%                 msj = 'R:';
%             else
%                 msj = sprintf('R%dr%dr%dr%d',v1,v2,v3,v4); % not yet
%             end
%             completed = obj.send(msj);
%         end
%         %%
%         % -----------------------------------------------------------------
%         function completed = stop(obj)
%             %obj.stop() stops all the motors
%             %
%             %# Inputs
%             %
%             %# Outputs
%             %* completed    -bool when true was correct, otherwise false.
% 
%             % # ----
%             msj = 'S:';
%             completed = obj.send(msj);
%         end
% 
%         %%
%         % -----------------------------------------------------------------
%         function completed = stopMotor(obj, idxs)
%             %obj.stop() stops the given motor indexes.
%             %
%             %# Inputs
%             %
%             %# Outputs
%             %* completed    -bool when true was correct, otherwise false.
% 
%             % # ----
%             completed = true;
%             for i = idxs
%                 msj = sprintf('S%d:', i);
%                 completed = completed  && obj.send(msj);
%             end
%         end
% 
%         %%
%         % -----------------------------------------------------------------
%         function resetBuffer(obj)
%             %obj.resetBuffer deletes all the content in the buffer
% 
%             obj.device.flush();
%         end
% 
%         %%
%         % -----------------------------------------------------------------
%         function data = read(obj)
%             %obj.read() returns the buffer of enconder vals
%             %
%             %# Inputs
%             %
%             %# Outputs
%             %* data        -double m-by-4 with m measurements
%             %
% 
%             % # ----
%             data = []; %% assumes data was not received
%             % loop to read all the messages
%             while obj.device.NumBytesAvailable > 0
% 
% 
%                 % count = obj.device.NumBytesAvailable;
%                 % str = obj.device.read(count, 'uint8');
%                 % disp (str)
%                 % str = '';
%                 str = obj.device.readline();
% 
%                 if isempty(str)
%                     continue;
%                 end
% 
%                 % data
%                 expr = '^x(-?\d+)y(-?\d+)z(-?\d+)w(-?\d+)';
%                 [m, isValid] = regexp(str, expr, 'tokens');
%                 if isValid
%                     m1 = cellfun(@(x)str2double(x), m{1});
%                     data = [data; m1];
%                 else
%                     fprintf('[ProsthesisEPNv2] %s\n',str);
%                 end
%             end
%         end
% 
%         %%
%         % -----------------------------------------------------------------
%         connect_serial(obj)
%     end
% 
%     methods (Hidden = true, Access = private)
%         %%
%         % -----------------------------------------------------------------
%         function mtCode = getMotorCode(obj, motor, pwm)
%             %obj.getCode returns the code for the motor and the direction.
%             %
%             %# Inputs
%             %* motor        -int between 1 and 4
%             %* pwm          -double with PWM speed to motors, -255 to 255
%             %
% 
%             % # ---- Data Validation
%             arguments
%                 obj
%                 motor (1,1) double {mustBeInRange(motor, 1, 4)}
%                 pwm (1,1) double {mustBeInRange(pwm, -255, 255)}
%             end
% 
%             % # ----
%             if pwm >= 0 % deciding between A or a (i.e. forward, backward)
%                 % uppercase is forward
%                 mtCode = obj.motorsPosDir{motor};
%             else
%                 % lowercase is backward
%                 mtCode = obj.motorsNegDir{motor};
%             end
%         end
%         %%
%         % -----------------------------------------------------------------
%         function completed = send(obj, msj)
%             %obj.send() the given msj via bluetooth, returns true when
%             %correct
%             %
% 
%             % # ---- Data Validation
%             arguments
%                 obj
%                 msj (1, :) char
%             end
% 
%             % # ----
%             try
%                 obj.device.writeline(msj); % with \n LF
%                 completed = true;
%             catch
%                 completed = false;
%             end
%         end
%     end
% end
classdef Controller < handle
    % Controller is a class that handles communication with the prosthesis
    % via Bluetooth or serial.
    %
    % The new prosthesis accepts commands for each finger as follows:
    %   A[posición] 0–350  (meñique)
    %   B[posición] 0–350  (anular)
    %   C[posición] 0–440  (dedo medio)
    %   D[posición] 0–350  (índice)
    %   E[posición] 0–120  (parte inferior del pulgar)
    %   F[posición] 0–100  (parte superior del pulgar)
    %
    % Movimientos especiales:
    %   O - Abrir la mano.
    %   C - Cerrar la mano.
    %   P - Posición de Spiderman.
    %   R - Posición OK.
    %   X - Calibración.
    %
    % For relative control of fingers A–D, the agent sends deltas (which may be
    % negative). The controller adds these deltas to the stored last positions,
    % clamps them within the allowed ranges, and sends the absolute commands.
    
    %% Public Properties
    properties (Access = public)
        device   % Communication object (bluetooth or serialport)
    end

    %% Hidden Properties
    properties (Hidden = true)
        isConnected = false;
        port;
        baudRate;
        % For relative control on fingers A-D:
        baseline      (1,4) double = [0 0 0 0];  % Encoder baseline (set during calibration)
        lastPositions (1,4) double = [0 0 0 0];  % Current absolute positions for A-D
        % This property sets the initial command used in calibration.
        % For example, "O:" for open hand (expected to yield baseline ~0) or "C:" for closed hand.
        initialCommand (1,1) string = "O:";  % default to open hand
    end

    properties (Hidden = true, Constant)
        timeout = 2;          % in seconds
        terminatorRead = 'CR/LF'; % for Bluetooth
        terminatorWrite = 'LF';   % for Bluetooth
        % Absolute limits for fingers (channels A-D)
        limitsA = [0, 450];
        limitsB = [0, 450];
        limitsC = [0, 540];
        limitsD = [0, 450];
        % Limits for chcannels E and F (not used in relative commands)
        limitsE = [0, 120];
        limitsF = [0, 100];
        % For legacy support of motor direction (not used for absolute commands)
        motorsPosDir = {'A', 'B', 'C', 'D'};
        motorsNegDir = {'a', 'b', 'c', 'd'};
    end

    %% Public Methods
    methods
        %% Constructor
        function obj = Controller(bluetoothFlag, blName, COMport, baudRate)
            % Constructor connects with a Bluetooth device or via serial.
            %
            % Inputs:
            %   bluetoothFlag - logical; if true, use Bluetooth.
            %   blName        - char; Bluetooth device name.
            %   COMport       - char; e.g. 'COM6'
            %   baudRate      - numeric; recommended 115200.
            arguments
                bluetoothFlag (1,1) logical = false;
                blName (1,:) char = 'Prosthesis_EPN_v2';
                COMport (1,:) char = 'COM6';
                baudRate (1,1) double = 115200;
            end
            disp("Controller constructor")
            disp(bluetoothFlag)
            if bluetoothFlag
                % Bluetooth connection
                obj.device = bluetooth(blName);
                obj.device.Timeout = obj.timeout;
                obj.device.configureTerminator(obj.terminatorRead, obj.terminatorWrite);
            else
                % Serial connection
                obj.port = COMport;
                obj.baudRate = baudRate;
                obj.connect_serial();
            end
            pause(5); % Allow connection stabilization
        end

        %% closeHand
        function completed = closeHand(obj)
            % Sends the command to close the hand completely.
            completed = obj.send("C:");
        end

        %% openHand
        function completed = openHand(obj)
            % Sends the command to open the hand completely.
            completed = obj.send("O:");
        end

        %% spiderman
        function completed = spiderman(obj)
            % Sends the command for the Spiderman gesture.
            completed = obj.send("P:");
        end

        %% okGesture
        function completed = okGesture(obj)
            % Sends the command for the OK gesture.
            completed = obj.send("R:");
        end

        %% calibrate
        function completed = calibrate(obj)
            % Calibrate sets the hand to a known state before starting.
            % It sends the command defined in the hidden property 'initialCommand'
            % (e.g. "O:" for open or "C:" for closed) to force a known state.
            % Then it reads the encoder values from fingers A–D and sets these as
            % both the baseline and the current lastPositions.
            completed = obj.send(obj.initialCommand);
            pause(0.5); % Allow time for the hand to settle
            try
                absData = obj.readAbsolute();
                obj.baseline = absData;
                obj.lastPositions = absData;
                fprintf('Calibration complete. Baseline set to: [%d %d %d %d]\n', obj.baseline);
            catch ME
                warning('Calibration failed: %s', ME.message);
            end
        end

        %% stop (Not applicable in the new prosthesis)
        function completed = stop(obj)
            % The stop command is not supported in the new prosthesis.
            % Return a default value.
            completed = true;
        end

        %% sendAllSpeed
        function completed = sendAllSpeed(obj, pwm1, pwm2, pwm3, pwm4)
            % sendAllSpeed sends relative commands for all four fingers (A-D).
            % The input values are treated as deltas (which may be negative)
            % and are added to the stored lastPositions.
            % The resulting absolute positions are clamped within the allowed ranges.
            %
            % Example command: 'A100,B150,C200,D100'
            arguments
                obj
                pwm1 (1,1) double {mustBeInRange(pwm1, -255, 255)}
                pwm2 (1,1) double {mustBeInRange(pwm2, -255, 255)}
                pwm3 (1,1) double {mustBeInRange(pwm3, -255, 255)}
                pwm4 (1,1) double {mustBeInRange(pwm4, -255, 255)}
            end
            disp("Executing sendAllSpeed")
            newA = obj.lastPositions(1) + pwm1;
            newB = obj.lastPositions(2) + pwm2;
            newC = obj.lastPositions(3) + pwm3;
            newD = obj.lastPositions(4) + pwm4;
            
            % Clamp to allowed limits.
            newA = max(obj.limitsA(1), min(newA, obj.limitsA(2)));
            newB = max(obj.limitsB(1), min(newB, obj.limitsB(2)));
            newC = max(obj.limitsC(1), min(newC, obj.limitsC(2)));
            newD = max(obj.limitsD(1), min(newD, obj.limitsD(2)));
            
            msj = sprintf('A%d,B%d,C%d,D%d', newA, newB, newC, newD);
            fprintf('sendAllSpeed sending command: %s\n', msj);
            completed = obj.send(msj);
            if completed
                obj.lastPositions = [newA newB newC newD];
            end
            disp(obj.lastPositions)
        end

        %% sendSpeed
        function completed = sendSpeed(obj, motor, pwm)
            % sendSpeed sends a relative command for one finger.
            % motor: integer 1–4; pwm: relative change.
            arguments
                obj
                motor (1,1) double {mustBeInRange(motor, 1, 4)}
                pwm (1,1) double {mustBeInRange(pwm, -255, 255)}
            end
            
            newPos = obj.lastPositions(motor) + pwm;
            switch motor
                case 1
                    newPos = max(obj.limitsA(1), min(newPos, obj.limitsA(2)));
                    letter = 'A';
                case 2
                    newPos = max(obj.limitsB(1), min(newPos, obj.limitsB(2)));
                    letter = 'B';
                case 3
                    newPos = max(obj.limitsC(1), min(newPos, obj.limitsC(2)));
                    letter = 'C';
                case 4
                    newPos = max(obj.limitsD(1), min(newPos, obj.limitsD(2)));
                    letter = 'D';
            end
            
            msj = sprintf('%s%d', letter, newPos);
            fprintf('sendSpeed sending command: %s\n', msj);
            completed = obj.send(msj);
            if completed
                obj.lastPositions(motor) = newPos;
            end
        end

        %% changePeriod (Not applicable in the new prosthesis)
        function completed = changePeriod(obj, msPeriod)
            % The new prosthesis does not support changing the period via command.
            % Return a default value.
            completed = true;
        end

        %% resetEncoder (Not applicable in the new prosthesis)
        function completed = resetEncoder(obj, v1, v2, v3, v4)
            % The resetEncoder command (as defined in the old prosthesis) is not used.
            % Return a default value.
            completed = true;
        end

        %% stopMotor (Not applicable in the new prosthesis)
        function completed = stopMotor(obj, idxs)
            % The stopMotor command is not needed in the new prosthesis.
            % Return a default value.
            completed = true;
        end

        %% resetBuffer
        function resetBuffer(obj)
            % resetBuffer clears the device buffer.
            flush(obj.device);
        end

        %% moveToPositions
        function completed = moveToPositions(obj, posA, posB, posC, posD)
            % moveToPositions sends a command to move each finger (A-D) to a
            % specified relative position.
            % The provided values are interpreted as deltas to be added to the
            % current positions.
            arguments
                obj
                posA (1,1) double
                posB (1,1) double
                posC (1,1) double
                posD (1,1) double
            end
            
            newA = obj.lastPositions(1) + posA;
            newB = obj.lastPositions(2) + posB;
            newC = obj.lastPositions(3) + posC;
            newD = obj.lastPositions(4) + posD;
            
            newA = max(obj.limitsA(1), min(newA, obj.limitsA(2)));
            newB = max(obj.limitsB(1), min(newB, obj.limitsB(2)));
            newC = max(obj.limitsC(1), min(newC, obj.limitsC(2)));
            newD = max(obj.limitsD(1), min(newD, obj.limitsD(2)));
            
            msj = sprintf('A%d,B%d,C%d,D%d', newA, newB, newC, newD);
            fprintf('moveToPositions sending command: %s\n', msj);
            completed = obj.send(msj);
            if completed
                obj.lastPositions = [newA newB newC newD];
            end
        end

        %% read
        function data = read(obj)
            % read() returns a matrix (m-by-4) with encoder measurements.
            % It reads available data from the serial port and expects each
            % line to be a JSON string that starts with '{' and ends with '}'
            % and that contains the keys "ENCODER_A", "ENCODER_B", "ENCODER_C",
            % and "ENCODER_D". The read data is converted to relative values by
            % subtracting the calibrated baseline.
            data = [0 0 0 0];  % Assume no data initially
            pattern = '^\{.*"ENCODER_A":\s*\d+.*"ENCODER_B":\s*\d+.*"ENCODER_C":\s*\d+.*"ENCODER_D":\s*\d+.*\}$';
            nBytes = obj.device.NumBytesAvailable;
            nTries = 0;
            while nBytes > 0 && nTries < 20
                rawBytes = read(obj.device, nBytes, "uint8");
                rawData = native2unicode(rawBytes, "UTF-8");
                lines = split(rawData, newline);
                disp(length(lines))
                for i = 1:length(lines)
                    line = strtrim(lines{i});
                    if isempty(line)
                        continue
                    end
                    % Check if the received string matches the expected JSON format.
                    if isempty(regexp(line, pattern, 'once'))
                        fprintf('[ProsthesisEPNv2] Incomplete or invalid JSON detected. Retrying to read.\n');
                        nTries = nTries + 1;
                        continue;  % Skip this line if not valid.
                    else
                        nTries = 20;  % Valid line found; break out.
                    end
                    try
                        % Decode the JSON string into a MATLAB struct.
                        jsonData = jsondecode(line);
                        % Extract the desired fields into a row vector.
                        row = [jsonData.ENCODER_A, jsonData.ENCODER_B, jsonData.ENCODER_C, jsonData.ENCODER_D];
                        % Subtract the baseline so that positions are relative.
                        row = row - obj.baseline;
                        data = [data; row];
                        disp(data);
                        break;
                    catch ME
                        fprintf('[ProsthesisEPNv2] Error parsing JSON: %s\n', ME.message);
                        fprintf('[ProsthesisEPNv2] Received: %s\n', line);
                    end
                end
                nBytes = obj.device.NumBytesAvailable;
            end
        end

        %% readAbsolute (Internal)
        function absData = readAbsolute(obj)
            % readAbsolute reads absolute encoder values from channels A-D
            % without subtracting the baseline. It uses a regex-based loop,
            % attempting up to 20 times to obtain a valid JSON string.
            absData = [];
            pattern = '^\{.*"ENCODER_A":\s*\d+.*"ENCODER_B":\s*\d+.*"ENCODER_C":\s*\d+.*"ENCODER_D":\s*\d+.*\}$';
            nBytes = obj.device.NumBytesAvailable;
            nTries = 0;
            while nBytes > 0 && nTries < 20
                rawBytes = read(obj.device, nBytes, "uint8");
                rawData = native2unicode(rawBytes, "UTF-8");
                lines = split(rawData, newline);
                for i = 1:length(lines)
                    line = strtrim(lines{i});
                    if isempty(line)
                        continue
                    end
                    if isempty(regexp(line, pattern, 'once'))
                        nTries = nTries + 1;
                        continue;
                    else
                        nTries = 20;
                    end
                    try
                        jsonData = jsondecode(line);
                        absData = [jsonData.ENCODER_A, jsonData.ENCODER_B, jsonData.ENCODER_C, jsonData.ENCODER_D];
                        return;  % Return the first valid reading.
                    catch ME
                        fprintf('[ProsthesisEPNv2] Error parsing JSON in readAbsolute: %s\n', ME.message);
                        fprintf('[ProsthesisEPNv2] Received: %s\n', line);
                    end
                end
                nBytes = obj.device.NumBytesAvailable;
            end
            if isempty(absData)
                error('Failed to read absolute encoder data after 20 tries.');
            end
        end
    end

    %% Private Methods
    methods (Hidden = true, Access = private)
        %% getMotorCode
        function mtCode = getMotorCode(obj, motor, pwm)
            % getMotorCode returns the code for the motor and the direction.
            % In the new controller, all commands for fingers A-D are sent as
            % absolute values (uppercase), so this function always returns the
            % uppercase letter.
            arguments
                obj
                motor (1,1) double {mustBeInRange(motor, 1, 4)}
                pwm (1,1) double
            end
            mtCode = obj.motorsPosDir{motor};
        end

        %% connect_serial
        function connect_serial(obj)
            obj.isConnected = false;
            try
                obj.device = serialport(obj.port, obj.baudRate);
                configureTerminator(obj.device, obj.terminatorWrite);
                drawnow;
                % Optionally, send an initial ACK to initiate communication.
                obj.send("ACK");
                obj.isConnected = true;
            catch ME
                warning('Could not connect via serial.');
                availablePorts = serialportlist("available");
                fprintf('Available COM ports: %s\n', strjoin(availablePorts, ', '));
                error(ME.message);
            end
        end

        %% send
        function completed = send(obj, msj)
            arguments
                obj
                msj (1,:) char
            end
            try
                writeline(obj.device, msj);
                completed = true;
            catch
                completed = false;
            end
        end
    end
end

