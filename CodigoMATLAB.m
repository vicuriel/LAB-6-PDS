%% Digitalizar Señales

clear all
close all

%% Pedimos al PSoC el primer eco que usaremos como referencia, se abre el puerto serial:
% Longitud del vector de datos a recibir
longitud = 512;
% Frecuencia de muestreo
fs = 0.4e6;
Ts = 1/fs;

% Se configura el puerto serial y se abre el canal
delete(instrfind);
SerialPort = 'COM3'; % Puerto serial
fincad = 'CR/LF';
baudios = 115200;
s = serial(SerialPort);
set(s, 'BaudRate', baudios, 'DataBits', 8, 'Parity', 'none', 'StopBits', 1, 'FlowControl', 'none', 'Timeout', 1);
set(s, 'Terminator', fincad);

flushinput(s);
s.BytesAvailableFcnCount = longitud;
s.BytesAvailableFcnMode = 'byte';
% Se abre el puerto de comunicación
fopen(s);

%% Inicializando variables - Primer gráfico - Eco de la señal de referencia
flag = 1;
flushinput(s);

%% Se pide al PSoC una nueva medición
MaxDeviation = 3; % Maximum Allowable Change from one value to next
TimeInterval = 0.001; % Tiempo entre cada medición
tiempo = 0;
senal_original = 0;

flushinput(s);
pause(1)
fwrite(s, 'I') % Se pide al PSoC que tome una medida de la señal
pause(1)
fwrite(s, 'P') % Se pide al PSoC que envíe la medida tomada por el puerto UART

senal_original(1) = 0;
tiempo(1) = 0;
count = 1;
k = 0;

while count ~= longitud
    k = k + 1;
    if k == longitud
        fclose(s);
        delete(s);
        clear s;
        s = serial(SerialPort);
        set(s, 'Terminator', fincad);
        set(s, 'BaudRate', baudios, 'Parity', 'none');
        fopen(s)
        k = 0;
    end
    
    senal_original(count) = str2double(fscanf(s));
    tiempo(count) = count;
    count = count + 1;
end

figure
title("Señal Original")
plot(senal_original)

%% Inicializando variables - Segundo gráfico - Eco de la señal filtrada
flag = 1;
flushinput(s);

%% Se pide al PSoC una nueva medición
MaxDeviation = 3; % Maximum Allowable Change from one value to next
TimeInterval = 0.001; % Tiempo entre cada medición
tiempo = 0;
senal_filtrada = 0;

flushinput(s);
pause(1)
fwrite(s, 'F') % Se pide al PSoC que envíe la medida filtrada por el puerto UART

senal_filtrada(1) = 0;
tiempo(1) = 0;
count = 1;
k = 0;

while count ~= longitud
    k = k + 1;
    if k == longitud
        fclose(s);
        delete(s);
        clear s;
        s = serial(SerialPort);
        set(s, 'Terminator', fincad);
        set(s, 'BaudRate', baudios, 'Parity', 'none');
        fopen(s)
        k = 0;
    end
    
    senal_filtrada(count) = str2double(fscanf(s));
    tiempo(count) = count;
    count = count + 1;
end

figure
plot(senal_filtrada)
title("Señal Filtrada")

%% Comparación de Fase y Magnitud de las señales

% Calcula la FFT de ambas señales
N = length(senal_original);
fft_senal_original = fft(senal_original, N);
fft_senal_filtrada = fft(senal_filtrada, N);

% Calcula magnitud y fase
magnitude_original = abs(fft_senal_original);
phase_original = angle(fft_senal_original);
magnitude_filtrada = abs(fft_senal_filtrada);
phase_filtrada = angle(fft_senal_filtrada);

% Frecuencia normalizada para graficar
f = (0:N-1) * (5000 / N);

% Gráfico de Magnitud
figure;
subplot(2, 1, 1);
plot(f, magnitude_original, 'b', 'DisplayName', 'Señal Original'); hold on;
plot(f, magnitude_filtrada, 'r', 'DisplayName', 'Señal Filtrada'); hold off;
legend;
title('Comparación de Magnitud');
xlabel('Frecuencia (Hz)');
ylabel('Magnitud');

% Gráfico de Fase
subplot(2, 1, 2);
plot(f, phase_original, 'b', 'DisplayName', 'Señal Original'); hold on;
plot(f, phase_filtrada, 'r', 'DisplayName', 'Señal Filtrada'); hold off;
legend;
title('Comparación de Fase');
xlabel('Frecuencia (Hz)');
ylabel('Fase (radianes)');

%% Cerrar el puerto serial
flushinput(s);
fclose(s);
delete(s);
clear s;
disp("Puerto serial cerrado")
