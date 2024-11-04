%% Digitalizar Señales
 clear all 
 close all

%%  pedimos al psoc el primer eco que usaremos como referencia, se abre el puerto serial:
%Longitud del vector de datos a recibir 
longitud = 512;
%Frecuencia de muestreo
fs=0.4e6;
Ts=1/fs;
%Se configura el puerto serial y se abre el canal
delete(instrfind);
SerialPort='COM3'; %serial port
fincad = 'CR/LF';
baudios = 115200;
s = serial(SerialPort);
set(s,'BaudRate',baudios,'DataBits', 8, 'Parity', 'none','StopBits', 1,'FlowControl', 'none','Timeout',1);
set(s,'Terminator',fincad);

flushinput(s);
s.BytesAvailableFcnCount = longitud;
s.BytesAvailableFcnMode = 'byte';
%Se abre el puerto de comunicación
fopen(s);

%% Initializing variables - Primer grafico - Eco de la senhal de referencia
flag = 1;
flushinput(s);

            %% Se pide al psoc una nueva medicion
            MaxDeviation = 3;%Maximum Allowable Change from one value to next 
            TimeInterval=0.001;%time interval between each input.
            tiempo = 0;
            senal_original = 0;


            %% Initializing variables - Primer grafico - 

            flushinput(s);
            pause(1)
            fwrite(s,'I') %se pide al psoc que tome una medida de la señal 
            pause(3)
            fwrite(s,'P')%se pide al psoc que envie por el puerto uart la medida tomada 
            longitud = 512;
            senal_original(1)=0;
            tiempo(1)=0;
            count = 1;
            k=0;

            while ~isequal(count,longitud)
             %%Re creating Serial port before timeout  
                k=k+1;  
                if k==longitud
                    fclose(s);
                    delete(s);
                    clear s;        
                    s = serial(SerialPort);
                    set(s,'Terminator',fincad);
                    set(s,'BaudRate',baudios,'Parity','none');
                    fopen(s)     
                    k=0;
                end

            senal_original(count) = str2double(fscanf(s));
            tiempo(count) = count;
            count = count+1;
            end
            
    figure
    title("Señal Filtrada")
    plot(senal_original)
    

%% Initializing variables - SEGUNDO GRAFICO - Eco de la senhal de referencia
flag = 1;
flushinput(s);

            %% Se pide al psoc una nueva medicion
            MaxDeviation = 3;%Maximum Allowable Change from one value to next 
            TimeInterval=0.001;%time interval between each input.
            tiempo = 0;
            senal_filtrada = 0;


            %% Initializing variables - Primer grafico - 

            flushinput(s);
            pause(1)
            fwrite(s,'F')%se pide al psoc que envie por el puerto uart la medida filtrada
            longitud = 512;
            senal_filtrada(1)=0;
            tiempo(1)=0;
            count = 1;
            k=0;

            while ~isequal(count,longitud)
             %%Re creating Serial port before timeout  
                k=k+1;  
                if k==longitud
                    fclose(s);
                    delete(s);
                    clear s;        
                    s = serial(SerialPort);
                    set(s,'Terminator',fincad);
                    set(s,'BaudRate',baudios,'Parity','none');
                    fopen(s)     
                    k=0;
                end

            senal_filtrada(count) = str2double(fscanf(s));
            tiempo(count) = count;
            count = count+1;
            end
            
    figure
    plot(senal_filtrada)
    title("Señal Filtrada")
    
%% Clean up the serial port
flushinput(s);
fclose(s);
delete(s);
clear s;
disp("Puerto serial cerrado")


%% Especificaciones del filtro
fp1 = 800;   % Frecuencia de flanco inferior de la banda de paso (Hz)
fp2 = 1600;  % Frecuencia de flanco superior de la banda de paso (Hz)
fs1 = 400;   % Frecuencia de flanco inferior de la banda de parada (Hz)
fs2 = 2000;  % Frecuencia de flanco superior de la banda de parada (Hz)
Rp = 0.25;   % Rizado en la banda de paso (dB)
Rs = 60;     % Atenuación en la banda de parada (dB)
Fs = 8000;   % Frecuencia de muestreo (Hz)

% Normalización de las frecuencias respecto a la frecuencia de Nyquist
Wp = [fp1 fp2] / (Fs / 2);
Ws = [fs1 fs2] / (Fs / 2);

% Diseño del filtro paso banda elíptico
[n, Wn] = ellipord(Wp, Ws, Rp, Rs);
[b, a] = ellip(n, Rp, Rs, Wn, 'bandpass');
b
a


% Graficar ceros y polos en el plano Z
figure;
zplane(b, a);
title('Diagrama de Polos y Ceros en el Plano Z');


% Graficar la respuesta en frecuencia
figure;
freqz(b, a, Fs, Fs);
title('Respuesta en Frecuencia del Filtro');


% Aplicar el filtro a una señal de prueba
t = 0:1/Fs:1-1/Fs;
x = cos(2*pi*500*t) + cos(2*pi*1200*t) + cos(2*pi*2500*t);
y = filter(b, a, x);

% Graficar señal original y señal filtrada
figure;
subplot(2,1,1);
plot(t, x);
title('Señal Original');
xlabel('Tiempo (s)');
ylabel('Amplitud');

subplot(2,1,2);
plot(t, y);
title('Señal Filtrada');
xlabel('Tiempo (s)');
ylabel('Amplitud');

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
f = (0:N-1)*(5000/N);

% Gráfico de Magnitud
figure;
subplot(2,1,1);
plot(f, magnitude_original, 'b', 'DisplayName', 'Señal Original'); hold on;
plot(f, magnitude_filtrada, 'r', 'DisplayName', 'Señal Filtrada'); hold off;
legend;
title('Comparación de Magnitud');
xlabel('Frecuencia (Hz)');
ylabel('Magnitud');

% Gráfico de Fase
subplot(2,1,2);
plot(f, phase_original, 'b', 'DisplayName', 'Señal Original'); hold on;
plot(f, phase_filtrada, 'r', 'DisplayName', 'Señal Filtrada'); hold off;
legend;
title('Comparación de Fase');
xlabel('Frecuencia (Hz)');
ylabel('Fase (radianes)');


