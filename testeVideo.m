%% Função Video
function realVideo
    NumberFrameDisplayPerSecond = 30;% Define o frame rate
    % Liberta a camara ao correr o codigo
    objects = imaqfind; %find video input objects in memory
    delete(objects)
    
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
end
%% Função Processamento
%esta fun??o ? chamada de x em x segundos, valor estabelecido quando foi
%configurado o timer
function Processamento(obj, event,vidd)
    %cria variaveis do tipo persistent para evitar estar sempre a alocar
    %memoria
    persistent IM;
    persistent HSV;
    
    trigger(vidd);%d? um trigger
    IM = getdata(vidd,1,'uint8');%l? os dados da imagem

    %processamento
    HSV = createMaskYellowTestVideo(IM);
    
    %mostras as imagens
    subplot(1,2,1);imshow(IM);
    subplot(1,2,2);imshow(HSV);
end
