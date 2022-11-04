close all
clc

% Abrir imagem
th = 100;
im = imread('sinalCedencia.png');
im_gray = rgb2gray(im);
im_red = im(:,:,2);
imshow(im_red);
