%% Declara  o de vari veis 

%im = imread('TESTE.jpg'); %ler a imagem gerada na camara
%im = imread('sinalNeve.png'); 
%im = imread('sinalSemSaida.png'); 
%im = imread('sinallAvisoLomba.png');
%im = imread('sinalRotunda.png');
%im = imread('sinalEsquerda.png');
%im = imread('sinalDireita.png');
%im = imread('sinalUltrapassagem.png');
%im = imread('sinalProibido.png');

%% Captura de Imagem
function realVideo
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
    
 %% Aplicação das máscaras 
 while n < 3 
    switch n
        case 0 % Amarelo
            m_bin = createMaskYellowTestVideo(im); % aplicar um threshold
            matrix = strel('disk',15);%matriz para percorer a imagem 11x11
            closedIm = imclose(m_bin,matrix); %imagem fechada
            BW2 = imfill(closedIm,'holes');
            figure('Name', 'Imagem Binária'), imshow(m_bin)
            figure('Name', 'Fecho'), imshow(closedIm)
            figure('Name', 'Preencher'), imshow(BW2)
            
            % Algoritmo que diz o n mero de objetos e conectividade
            cc = bwconncomp(BW2);
            numObj = cc.NumObjects; % get the number os objects
            % Se n o for amarelo passa para o pr ximo
            if numObj == 0
                n = n + 1; 
            else  % Se for amarelo termina o loop
                maskYellow = 1; 
                n = 3;
            end
        case 1 %Azul
            %Fechar a linha de azul
            matrix = strel('square',20);%matriz para percorer a imagem 11x11
            closedIm = imclose(im,matrix); %imagem fechada
            m_bin = createMaskBlueHSV(closedIm); % aplicar um threshold
            BW2 = imfill(m_bin,'holes');
            %figure('Name','FILL'), imshow(BW2);
            cc = bwconncomp(m_bin);
            numObj = cc.NumObjects; % get the number os objects
            if numObj == 0
                n = n + 1;  
            else 
                maskBlue = 1;
                n = 3;
            end
        case 2 % Vermelho
            matrix = strel('square',20);%matriz para percorer a imagem 11x11
            closedIm = imclose(im,matrix); %imagem fechada
            %imshow(closedIm);
            m_bin = createMaskRedHSV(closedIm); % aplicar um threshold
            figure, imshow(m_bin)
            BW2 = imfill(m_bin,'holes');
            cc = bwconncomp(BW2);
            numObj = cc.NumObjects; % get the number os objects
          if numObj == 0
                n = n + 1;  
          else 
                maskRed = 1;
                n = 3;   
          end
    end
 end

    %mostras as imagens
    %subplot(1,2,1);imshow(im);
    %subplot(1,2,2);imshow(HSV);

%% Forma do Objeto Principal 

statsMainObj =  regionprops(BW2,'PixelIdxList','Area');
AreaMainObj = cat(1,statsMainObj.Area);

[maxValue,index] = max([statsMainObj.Area]);

[rw col]= size(statsMainObj);
for i=1:rw
    if (i~=index)
       BW2 (statsMainObj(i).PixelIdxList)=0; % Remove all small regions except large area index
    end
end
figure('Name', 'Eliminar Ruido'), imshow(BW2)

statsMainObj =  regionprops(BW2,'Centroid','BoundingBox', 'Circularity','MajorAxisLength','MinorAxisLength');
CentroidMainObj = cat(1, statsMainObj.Centroid);
RatioMainObj = cat(1,statsMainObj.MajorAxisLength) / cat(1,statsMainObj.MinorAxisLength);
MajorAxisMainObj = cat(1,statsMainObj.MajorAxisLength);
CircleMetricMainObj = cat(1,statsMainObj.Circularity);  %circularity metric
SquareMetricMainObj = RatioMainObj;
TriangleMetricMainObj = NaN(length(CircleMetricMainObj),1);

boxAreaMainObj = m_minbbarea(BW2);

%for each boundary, fit to bounding box, and calculate some parameters
for k=1:length(TriangleMetricMainObj),
    TriangleMetricMainObj(k) = AreaMainObj(k)/boxAreaMainObj(k);  %filled area vs box area
end

%define some thresholds for each metric
%do in order of circle, triangle, square, rectangle to avoid assigning the
%same shape to multiple objects
isCircleMainObj =   (CircleMetricMainObj > 0.95);
isTriangleMainObj = ~isCircleMainObj & (TriangleMetricMainObj < 0.65);
isSquareMainObj =   ~isCircleMainObj & ~isTriangleMainObj & (SquareMetricMainObj < 1) & (TriangleMetricMainObj > 0.9);
isRectangleMainObj = ~isCircleMainObj & ~isTriangleMainObj & ~isSquareMainObj & (TriangleMetricMainObj > 0.9);
isPentagonoMainObj = ~isCircleMainObj & ~isTriangleMainObj & ~isSquareMainObj & ~isRectangleMainObj;%isn't any of these

%assign shape to each object
whichShapeMainObj = cell(length(TriangleMetricMainObj),1);
whichShapeMainObj(isCircleMainObj) = {'Circle'};
whichShapeMainObj(isTriangleMainObj) = {'Triangle'};
whichShapeMainObj(isSquareMainObj) = {'Square'};
whichShapeMainObj(isRectangleMainObj)= {'Rectangle'};
whichShapeMainObj(isPentagonoMainObj)= {'Pentagono/hexagono'};
% Mostra na figura o objeto detetado
RGB = label2rgb(bwlabel(BW2));
pause(2)
CombinedMainObj = [CircleMetricMainObj, SquareMetricMainObj, TriangleMetricMainObj];
for k=1:length(TriangleMetricMainObj),
    text( CentroidMainObj(k,1)-20, CentroidMainObj(k,2)+20, whichShapeMainObj{k});
end

%%  Multiplicar as imagens

multi = uint8(BW2);
submask = im.*multi;
figure('Name', 'Multiplicacao'), imshow(submask);
%filterBlack = submask;
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
%   statsSecObj =  regionprops(BW2,'PixelIdxList','Area');
%     AreaSecObj = cat(1,statsSecObj.Area);
%     [maxValue,index] = max([statsSecObj.Area]);
%     [rw col]= size(statsSecObj);
%     for i=1:rw
%         if (i~=index)
%             filter(statsSecObj(i).PixelIdxList)=0; % Remove all small regions except large area index
%         end  
%     end
elseif maskBlue == 1
     filter = createMaskBlackHSVBlue(submask);
     figure('Name', 'Isolar Objeto'), imshow(filter)
else
    filter = createMaskBlackHSV(submask);
    figure('Name', 'Isolar Objeto'), imshow(filter)
end

% %% Forma dos objetos do interior
% 
% stats =  regionprops(objectMask,'Centroid','BoundingBox', 'Circularity','MajorAxisLength','MinorAxisLength','Area','Orientation');
% Centroid = cat(1, stats.Centroid);
% Area = cat(1,stats.Area);
% Ratio = cat(1,stats.MajorAxisLength) / cat(1,stats.MinorAxisLength);
% MajorAxis = cat(1,stats.MajorAxisLength);
% CircleMetric = cat(1,stats.Circularity);  %circularity metric
% SquareMetric = Ratio;
% TriangleMetric = NaN(length(CircleMetric),1);
% 
% boxArea = m_minbbarea(objectMask);
% 
% %for each boundary, fit to bounding box, and calculate some parameters
% for k=1:length(TriangleMetric),
%     TriangleMetric(k) = Area(k)/boxArea(k);  %filled area vs box area
% end
% 
% %define some thresholds for each metric
% %do in order of circle, triangle, square, rectangle to avoid assigning the
% %same shape to multiple objects
% isCircle =   (CircleMetric > 0.95);
% isTriangle = ~isCircle & (TriangleMetric < 0.65);
% isSquare =   ~isCircle & ~isTriangle & (SquareMetric < 1) & (TriangleMetric > 0.9);
% isRectangle = ~isCircle & ~isTriangle & ~isSquare & (TriangleMetric > 0.9);
% isPentagono= ~isCircle & ~isTriangle & ~isSquare & ~isRectangle;%isn't any of these
% 
% %assign shape to each object
% whichShape = cell(length(TriangleMetric),1);
% whichShape(isCircle) = {'Circle'};
% whichShape(isTriangle) = {'Triangle'};
% whichShape(isSquare) = {'Square'};
% whichShape(isRectangle)= {'Rectangle'};
% whichShape(isPentagono)= {'Pentagono/hexagono'};
% % Mostra na figura o objeto detetado
% RGB = label2rgb(bwlabel(objectMask));
% figure("Name", "Final"), imshow(RGB); 
% %hold on;
% pause(2)
% Combined = [CircleMetric, SquareMetric, TriangleMetric];
% for k=1:length(TriangleMetric),
%     text( Centroid(k,1)-20, Centroid(k,2)+20, whichShape{k});
% end
% % Fazer BBox
% rectangle('Position',[stats.BoundingBox(1),stats.BoundingBox(2),stats.BoundingBox(3),stats.BoundingBox(4)],...
% 'EdgeColor','b','LineWidth',2)
% %hold off
% 
%% Signal Identification
% 
% if isRectangleMainObj == 1
%     if isPentagono == 1 && Area > 78000 && maskYellow == 1
%         disp("Sinal Aviso de Lomba")
%     elseif isTriangle == 1 && Area < 78000 && maskYellow == 1
%         disp("Sinal Aviso de Semaforo")
%     else
%         disp("Sinal Sem Saida")
%     end
%     
% elseif isCircleMainObj == 1
%     if maskRed == 1
%         if numObj == 1
%             disp("Sinal Proibido")
%         elseif numObj > 5
%             disp("Sinal Proibido Ultrapassar")
%         end
%     elseif maskBlue == 1
%         if numObj == 3 && isTriangle == 1
%             disp("Sinal de Rotunda")
%         elseif numObj == 1 && isTriangle == 1
% 
%         end
%     end
%     
% elseif isTriangleMainObj == 1
%     if isTriangle == 1 && Area > 24000 && maskRed == 1
%         disp("Sinal Cedencia");
%     elseif isTriangle == 1 && Area > 19000 && Area < 24000 && maskRed == 1
%         disp("Sinal Neve");
%     elseif isTriangle == 1 && Area < 19000 && maskRed == 1
%         disp("Sinal Lomba");
%     end
% end
end
end