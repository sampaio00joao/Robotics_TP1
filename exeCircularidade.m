clear all
close all
clc

im = imread('sinalCedencia.png');  % carregar imagem
n = 0; % inicia com o valor 0
maskRed = 0;
maskYellow = 0;
maskBlue = 0;
while n < 3 
    switch n
        case 0 % Amarelo
            m_bin = createMaskYellowHSV(im); % aplicar um threshold
            figure, imshow(m_bin)
            BW2 = imfill(m_bin,'holes');
            % Algoritmo que diz o número de objetos e conectividade
            cc = bwconncomp(m_bin);
            numObj = cc.NumObjects; % get the number os objects
            disp(numObj) % check the number of objects
            % Se não for amarelo passa para o próximo
            if numObj == 0
                n = n + 1; 
            else  % Se for amarelo termina o loop
                n = 3;
                maskYellow = 1; 
            end
        case 1 % Vermelho
            m_bin = createMaskRedHSV(im); % aplicar um threshold
            figure, imshow(m_bin)
            BW2 = imfill(m_bin,'holes');
            % Algoritmo que diz o número de objetos e conectividade
            cc = bwconncomp(m_bin);
            numObj = cc.NumObjects; % get the number os objects
            disp(numObj) % check the number of objects
            if numObj == 0
                n = n + 1;  
            else  % Se for amarelo termina o loop
                n = 3;
                maskRed = 1;
            end
        case 2 % Azul
            m_bin = createMaskBlueHSV(im); % aplicar um threshold
            figure, imshow(m_bin)
            BW2 = imfill(m_bin,'holes');
            maskBlue = 1;
            n = n + 1;
    end
end
           
figure, imshow(BW2)
stats =  regionprops(BW2,'Centroid', 'Circularity','MajorAxisLength','MinorAxisLength','Area');
Centroid = cat(1, stats.Centroid);
Area = cat(1,stats.Area);
Ratio = cat(1,stats.MajorAxisLength) / cat(1,stats.MinorAxisLength);

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
%now label with results
RGB = label2rgb(bwlabel(BW2));
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

if isRectangle == 1
    if numObj > 1
        disp("Semaforo")
    end
elseif isCircle == 1
    if maskRed == 1
        %ERRADO
        %maskBlack = createMaskBlackHSV(im);
        %figure, imshow(maskBlack)
        %cc = bwconncomp(maskBlack);
        %numObj = cc.NumObjects; % get the number os objects
        % Dizer qual o sinal
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
    %ERRADO
    % Apply black mask
    %figure, imshow(im)
    %maskBlack = createMaskBlackHSV(im);
    %figure, imshow(maskBlack)
    %cc = bwconncomp(maskBlack);
    %numObj = cc.NumObjects; % get the number os objects
    if numObj == 1
        disp("Lomba");
    elseif numObj > 2
        disp("Neve");
    else
        disp("Cedencia");
    end                 
end
