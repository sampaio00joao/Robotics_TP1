function realVideo
NumberFrameDisplayPerSecond=20;% Define o frame rate
 
hFigure=figure(1);% Abre uma figura
 
% Set-up da entrada de video

try
        vid = videoinput('winvideo', 1, 'MJPG_1280x720'); % para windows
catch
   try
       vid = videoinput('macvideo', 1); % para macs.
   catch
      errordlg('No webcam available');
   end
end
 
% define os parametros para o video
set(vid,'FramesPerTrigger',1);% adquire apenas um frame
set(vid,'TriggerRepeat',Inf);% adquire em continuo
set(vid,'ReturnedColorSpace','RGB');%adquire imagem do tipo RGB
triggerconfig(vid, 'Manual');
 
% cria um timer que chama a fun??o Processamento
TimerData=timer('TimerFcn', {@Processamento,vid},'Period',1/NumberFrameDisplayPerSecond,'ExecutionMode','fixedRate','BusyMode','drop');
 
start(vid); % inicia o video 
start(TimerData); % inicia o timer 
 
%  activa a fun??o enquanto a janela da figura estiver aberta
 uiwait(hFigure);

% Apaga os objectos criados
stop(TimerData);
delete(TimerData);
stop(vid);
delete(vid);
% apaga as variaveis do tipo persistent
clear functions;
imaqreset;







