%esta fun??o ? chamada de x em x segundos, valor estabelecido quando foi
%configurado o timer
function Processamento(obj, event,vidd)
%cria variaveis do tipo persistent para evitar estar sempre a alocar
%memoria
persistent IM;
persistent HSV;
persistent H;
persistent S;
persistent V;
persistent out1;
persistent out2;
persistent out3;
persistent out;
 
trigger(vidd);%d? um trigger
IM=getdata(vidd,1,'uint8');%l? os dados da imagem
 
%processamento
HSV = rgb2hsv(IM);
H= HSV (:,:,1);
S= HSV (:,:,2);
V= HSV (:,:,3); 
out1=roicolor(H,200/360,247/360);    
out2=roicolor(S,0/100,100/100);
out3=roicolor(V,0/100,100/100);

out=out3.*out2.*out1;

%mostras as imagens
subplot(1,2,1);imshow(IM);
subplot(1,2,2);imshow(out);
