
classdef TCPController < handle
    properties
        tcp % MATLAB tcpclient object
        ip  % Local IP (127.0.0.1)
        port % Port number (must match the Python server)
    end
    methods
        function obj = TCPController(ip, port)
            obj.ip = ip;
            obj.port = port;
            obj.tcp = tcpclient(ip, port);
            pause(1); % wait for connection stabilization
        end
        
        function sendCommand(obj, cmd)
            % Ensure cmd ends with a newline
            if ~endsWith(cmd, newline)
                cmd = [cmd newline];
            end
            writeline(obj.tcp, cmd);
        end
        
        function data = readData(obj)
            % Read one line from the TCP server
            data = readline(obj.tcp);
        end
        
        function delete(obj)
            clear obj.tcp;
        end
    end
end