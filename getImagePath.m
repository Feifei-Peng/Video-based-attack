function [ imageFullPath ] = getImagePath()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

[fileName , pathName]= uigetfile({'*.jpg'; '*.jpeg'; '*.png';'*.bmp'},'File Selector'); %disply only images files.

imageFullPath = strcat(pathName,fileName);
end

