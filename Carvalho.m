clear all; close all; clc
%% Captura de Imagem
NumberFrameDisplayPerSecond = 30;% Define o frame rate
% Liberta a camara ao correr o codigo
objects = imaqfind; %find video input objects in memory
delete(objects)

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

% Apaga os objectos criados
stop(TimerData);
delete(TimerData);
stop(vid);
delete(vid);
% apaga as variaveis do tipo persistent
clear functions;
imaqreset;

%% Função Processamento
%esta fun??o ? chamada de x em x segundos, valor estabelecido quando foi
%configurado o timer
function Processamento(obj, event,vidd)
    %cria variaveis do tipo persistent para evitar estar sempre a alocar
    %memoria
    persistent im;
    
    trigger(vidd);%d? um trigger
    im = getdata(vidd,1,'uint8');%l? os dados da imagem

    n = 0; % inicia com o valor 0
    maskRed = 0;
    maskYellow = 0;
    maskBlue = 0;
    im = flip(im ,2); % espelhar a imagem novamente / a camara espelha a imagem real
    
 %% Aplicação das máscaras 
 while n < 3 
    switch n
        case 0 % Amarelo
            m_bin = createMaskYellowHSV(im); % aplicar um threshold
            matrix = strel('square',15);%matriz para percorer a imagem 11x11
            closedIm = imclose(m_bin,matrix); %imagem fechada
            BW2 = imfill(closedIm,'holes');
            % Figuras     
            figure('Name', 'Preencher'), imshow(BW2)
            % Eliminar ruído
            stats =  regionprops(BW2,'PixelIdxList','Area');
            Area = cat(1,stats.Area);
            % Eliminar objetos indesejados / ruído
            [maxValue,index] = max([stats.Area]);
            [rw col]= size(stats);
            for i=1:rw
                if (i~=index)
                    BW2(stats(i).PixelIdxList) = 0; % Remove all small regions except large area index
                end
            end
            if maxValue < 5000 % Sinais de outras cores
                n = n + 1; 
            else  % Se for o sinal com cor correspondente
                maskYellow = 1; 
                n = 3;
            end
        case 1 %Azul
            m_bin = createMaskBlueTesteVideo(im); % aplicar um threshold
            matrix = strel('square',10);%matriz para percorer a imagem 11x11
            closedIm = imclose(m_bin,matrix); %imagem fechada
            BW2 = imfill(closedIm,'holes');
            % Figuras
            figure('Name', 'Preencher'), imshow(BW2)
            % Eliminar ruído
            stats =  regionprops(BW2,'PixelIdxList','Area');
            Area = cat(1,stats.Area);
            % Eliminar objetos indesejados / ruído
            [maxValue,index] = max([stats.Area]);
            [rw col]= size(stats);
            for i=1:rw
                if (i~=index)
                    BW2(stats(i).PixelIdxList) = 0; % Remove all small regions except large area index
                end
            end
            if maxValue < 5000 % Sinais de outras cores
                n = n + 1; 
            else  % Se for o sinal com cor correspondente
                maskYellow = 1; 
                n = 3;
            end
        case 2 % Vermelho
            m_bin = createMaskRedHSV(im); % aplicar um threshold vermelho
            matrix = strel('square',30);%matriz para percorer a imagem 11x11
            closedIm = imclose(m_bin,matrix); %imagem fechada
            BW2 = imfill(closedIm,'holes');
            % Figuras
            figure('Name', 'Preencher'), imshow(BW2)
            % Eliminar ruído
            stats =  regionprops(BW2,'PixelIdxList','Area');
            Area = cat(1,stats.Area);
            % Eliminar objetos indesejados / ruído
            [maxValue,index] = max([stats.Area]);
            [rw col]= size(stats);
            for i=1:rw
                if (i~=index)
                    BW2(stats(i).PixelIdxList) = 0; % Remove all small regions except large area index
                end
            end
            if maxValue < 5000 % Sinais de outras cores
                n = n + 1; 
            else  % Se for o sinal com cor correspondente
                maskYellow = 1; 
                n = 3;
            end
    end
 end
%% Forma do Objeto Principal 
stats =  regionprops(BW2,'PixelIdxList','Area','Centroid','MajorAxisLength','Circularity','MinorAxisLength');
Area = cat(1,stats.Area);
Centroid = cat(1, stats.Centroid);
Ratio = cat(1,stats.MajorAxisLength) / cat(1,stats.MinorAxisLength);
MajorAxis = cat(1,stats.MajorAxisLength);
CircleMetric = cat(1,stats.Circularity);  %circularity metric
SquareMetric = Ratio;
TriangleMetric = NaN(length(CircleMetric),1);

boxArea = m_minbbarea(BW2);

%for each boundary, fit to bounding box, and calculate some parameters
for k=1:length(TriangleMetric),
    TriangleMetric(k) = Area(k)/boxArea(k);  %filled area vs box area
end
%define some thresholds for each metric
%do in order of circle, triangle, square, rectangle to avoid assigning the
%same shape to multiple objects
isCircle =   (CircleMetric > 0.85);
isTriangle = ~isCircle & (TriangleMetric < 0.65);
isSquare =   ~isCircle & ~isTriangle & (SquareMetric < 1) & (TriangleMetric > 0.9);
isRectangle = ~isCircle & ~isTriangle & ~isSquare & (TriangleMetric > 0.9);
isPentagono= ~isCircle & ~isTriangle & ~isSquare & ~isRectangle;%isn't any of these

%assign shape to each object
whichShape = cell(length(TriangleMetric),1);
whichShape(isCircle) = {'Circle'};
whichShape(isTriangle) = {'Triangle'};
whichShape(isSquare) = {'Square'};
whichShape(isRectangle)= {'Rectangle'};
whichShape(isPentagono)= {'Pentagono/hexagono'};
% Mostra na figura o objeto detetado
hold on;
Combined = [CircleMetric, SquareMetric, TriangleMetric];
for k=1:length(TriangleMetric),
    text( Centroid(k,1)-20, Centroid(k,2)+20, whichShape{k});
end

%%  Multiplicar as imagens
multi = uint8(BW2);
submask = im.*multi;
figure('Name', 'Multiplicacao'), imshow(submask);

%% Aplicação da segunda máscara e identificação do sinal
if maskYellow == 1 %se a mascara for amarela
    filter = createMaskRedYellowSign(submask);
    figure('Name','Filtro'), imshow(filter);
    cc = bwconncomp(filter);
    numObj = cc.NumObjects; % get the number os objects
    if numObj ~= 0
        disp("Sinal Aviso de Semaforo")
    else
        disp("Sinal Aviso de Lomba")
    end
elseif maskBlue == 1
    if isCircle ~= 1
        disp("Sem saída")
    else     
        filterWhite = createMaskWhiteHSV(submask);
        figure('Name', 'Isolar Objeto Branco'), imshow(filterWhite)
        matrix = strel('square',5);%matriz para percorer a imagem 11x11
        erodedIm = imerode(filterWhite,matrix); %imagem fechada
        figure('Name', 'Isolar Objeto Branco'), imshow(erodedIm)
        
        ccBlueSign = bwconncomp(erodedIm);
        numObj = ccBlueSign.NumObjects; % get the number os objects
            
        if numObj == 3 
            disp("Rotunda")
        else 
            stats =  regionprops(erodedIm,'PixelIdxList','Area');
            [maxValue,index] = max([stats.Area]);
            [rw col]= size(stats);
            for i=1:rw
                if (i~=index)
                    erodedIm(stats(i).PixelIdxList)=0; % Remove all small regions except large area index
                end
            end
            figure('Name', 'Isolar Objeto'), imshow(erodedIm)
            [rows,columns] = size(erodedIm);
            middleColumn = columns/2;
            leftHalf = nnz(erodedIm(:,1:middleColumn));
            rightHalf = nnz(erodedIm(:,middleColumn+1:end));
            if leftHalf > rightHalf
                disp("Sinal Esquerda")
            else
                disp("Sinal Direita")
            end
        end
    end
elseif maskRed == 1
    if isCircle == 1
        filterBlack = createMaskBlackHSV(submask);
        figure('Name', 'Isolar Objeto Preto'), imshow(filterBlack)
        ccBlack = bwconncomp(filterBlack);
        numObj = ccBlack.NumObjects; % get the number os objects
        if numObj ~= 0
            statsRed =  regionprops(filterBlack,'PixelIdxList','Area');
            maxValue = max([statsRed.Area]);
            if maxValue < 500
                disp('Proibido')
            else
                disp('Proíbido Ultrapassar') 
            end
        else
            disp('Proibido')
        end
    elseif isTriangle == 1
        filterBlack = createMaskBlackHSV(submask);
        figure('Name', 'Isolar Objeto Preto'), imshow(filterBlack)
        stats =  regionprops(filterBlack,'PixelIdxList','Area');
        [maxValue,index] = max([stats.Area]);
        [rw col]= size(stats);
        for i=1:rw
            if (i~=index)
                filterBlack(stats(i).PixelIdxList)=0; % Remove all small regions except large area index
            end
        end
        stats =  regionprops(filterBlack,'PixelIdxList','Area','Centroid');
        middleRow = stats.Centroid(2);
        upperHalf = nnz(filterBlack(1:middleRow,:));
        lowerHalf = nnz(filterBlack(middleRow+1:end,:));
        compare = abs(upperHalf - lowerHalf);
        if compare > 300
            disp('Perigo Lomba')
        else 
            disp('Perigo Neve')
        end
    end
else
   errordlg('Sem objeto');
end
end