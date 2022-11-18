clear all
close all
clc

%% Declaração de variáveis 
im = imread('sinalLomba.png');  % carregar imagem
n = 0; % inicia com o valor 0
maskRed = 0;
maskYellow = 0;
maskBlue = 0;

%% Aplicação de máscaras 
while n < 3 
    switch n
        case 0 % Amarelo
            m_bin = createMaskYellowHSV(im); % aplicar um threshold
            %figure, imshow(m_bin)
            BW2 = imfill(m_bin,'holes');
            % Algoritmo que diz o número de objetos e conectividade
            cc = bwconncomp(m_bin);
            numObj = cc.NumObjects; % get the number os objects
            % Se não for amarelo passa para o próximo
            if numObj == 0
                n = n + 1; 
            else  % Se for amarelo termina o loop
                n = 3;
                maskYellow = 1; 
            end
        case 1 % Vermelho
            m_bin = createMaskRedHSV(im); % aplicar um threshold
            %figure, imshow(m_bin)
            BW2 = imfill(m_bin,'holes');
            cc = bwconncomp(BW2);
            numObj = cc.NumObjects; % get the number os objects
            if numObj == 0
                n = n + 1;  
            else  % Se for amarelo termina o loop
                n = 3;
                maskRed = 1;
            end
        case 2 % Azul
            m_bin = createMaskBlueHSV(im); % aplicar um threshold
            %figure, imshow(m_bin)
            BW2 = imfill(m_bin,'holes');
            maskBlue = 1;
            n = n + 1;
    end
end

%%  Multiplicar as imagens
multi = uint8(BW2);
submask = im.*multi;

filterBlack = createMaskBlackHSV(submask);
multi2 = uint8(submask);
submask2 = im.*multi2;
% Algoritmo que diz o número de objetos e conectividade

figure, imshow(filterBlack)

cc = bwconncomp(filterBlack);
numObj = cc.NumObjects; % get the number os objects
disp(numObj) % check the number of objects

% Aceder ao objeto
m_obj = cc.PixelIdxList{numObj};

% Colocar a imagem a 0 - preto
% 1 - x / 2 - y ImageSize: [408 410]
m_final = zeros(size(filterBlack,1), size(filterBlack,2));

% Isolar o objeto
m_final(m_obj) = 0;

figure, imshow(m_final)
objectMask = m_final; % mudar aqui para alterar regionprops


%% RegionProps
stats =  regionprops(objectMask,'Centroid','BoundingBox', 'Circularity','MajorAxisLength','MinorAxisLength','Area');
Centroid = cat(1, stats.Centroid);
Area = cat(1,stats.Area);
Ratio = cat(1,stats.MajorAxisLength) / cat(1,stats.MinorAxisLength);
MajorAxis = cat(1,stats.MajorAxisLength);
CircleMetric = cat(1,stats.Circularity);  %circularity metric
SquareMetric = Ratio;
TriangleMetric = NaN(length(CircleMetric),1);

boxArea = m_minbbarea(objectMask);

%for each boundary, fit to bounding box, and calculate some parameters
for k=1:length(TriangleMetric),
    TriangleMetric(k) = Area(k)/boxArea(k);  %filled area vs box area
end
disp(Area)

%% Shape Identification 
%define some thresholds for each metric
%do in order of circle, triangle, square, rectangle to avoid assigning the
%same shape to multiple objects
isCircle =   (CircleMetric > 0.95);
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
RGB = label2rgb(bwlabel(objectMask));
%figure, imshow(RGB); 
hold on;
pause(1)
Combined = [CircleMetric, SquareMetric, TriangleMetric];
for k=1:length(TriangleMetric),
    %display metric values and which shape next to object
    %Txt = sprintf('C=%0.3f S=%0.3f T=%0.3f',  Combined(k,:));
   %text( Centroid(k,1)-20, Centroid(k,2), Txt);
    text( Centroid(k,1)-20, Centroid(k,2)+20, whichShape{k});
end
% Fazer BBox
rectangle('Position',[stats.BoundingBox(1),stats.BoundingBox(2),stats.BoundingBox(3),stats.BoundingBox(4)],...
'EdgeColor','b','LineWidth',2)
hold off

%% Signal Identification
if isRectangle == 1
    if numObj > 1
        disp("Semaforo")
    end
elseif isCircle == 1
    if maskRed == 1
        if numObj ~= 0
            disp("Proibido Ultrapassar")
        else
            disp("Proibido")
        end
    elseif maskBlue == 1
        cc = bwconncomp(m_bin);
        numObj = cc.NumObjects; % get the number os objects
        if numObj == 3
            disp("Rotunda")
        end
    end
    
elseif isSquare == 1
     disp("Semaforo")
elseif isPentagono == 1
     disp("Semaforo")
elseif isTriangle == 1   
    if Area >= 19000
        disp("Neve");
    elseif numObj > 2
        disp("Cedencia");
    else
        disp("Lomba");
    end                 
end



