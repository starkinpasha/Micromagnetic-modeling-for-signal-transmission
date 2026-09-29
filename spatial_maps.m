 clear all;
close all;

% Выбор m00000X нескольких файлов через диалоговое окно 
[files, path] = uigetfile({'m0*.ovf', 'OVF Files'}, 'Выберите файлы для обработки', 'MultiSelect', 'on');

% Проверка, были ли выбраны файлы
if isequal(files, 0)
    disp('Файлы не выбраны.');
    return;
end

% Преобразование выбранных файлов в массив
if iscell(files)
    filenames = files;
else
    filenames = {files};
end

% Проверка наличия файла groundstate_m.ovf в той же папке
filename2 = 'groundstate_m.ovf';
fullpath2 = fullfile(path, filename2);

if ~exist(fullpath2, 'file')
    disp(['Файл ', filename2, ' не найден в директории ', path]);
    return;
end

% Загрузка данных из файла groundstate_m.ovf
datam = oommf2matlab(fullpath2);

% Создание папки для сохранения результатов
outputFolder = fullfile(path, 'ProcessedData');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Процессинг каждого выбранного файла
for k = 1:length(filenames)
    filename1 = filenames{k};
    fullpath1 = fullfile(path, filename1);
    
    % Загрузка данных из файла
    data = oommf2matlab(fullpath1);
    
    % Обработка данных
    zs = 1;
    bmag = zeros(data.xnodes, data.ynodes);
    bph = zeros(data.xnodes, data.ynodes);
    
    for i = 1:data.xnodes
        for j = 1:data.ynodes
            bmag(i,j) = (data.datax(i,j,zs) - datam.datax(i,j,zs))^2 + ...
                        (data.dataz(i,j,zs) - datam.dataz(i,j,zs))^2;
            bph(i,j) = (data.dataz(i,j,zs) - datam.dataz(i,j,zs));
        end
    end
    
    % График фазы
    figure;
    cmin = -5e-4;
    cmax = 5e-4;
    pcolor(bph(:,:)');
    shading interp;
    caxis([cmin cmax]);
    colormap(b2r(cmin, cmax));
    colorbar;
    title(['Фаза для ', filename1]);
    xlabel('X');
    ylabel('Y');
    saveas(gcf, fullfile(outputFolder, ['phase_plot_', strrep(filename1, '.ovf', ''), '.png']));
    close(gcf);
    
    % График интенсивности (логарифмическая шкала)
    figure;
    cmin = -22;
    cmax = -4;
    pcolor(log(bmag(:,:))');
    shading interp;
    caxis([cmin cmax]);
    colormap(jet);
    colorbar;
    title(['Интенсивность (логарифмическая шкала) для ', filename1]);
    xlabel('X');
    ylabel('Y');
    saveas(gcf, fullfile(outputFolder, ['intensity_log_plot_', strrep(filename1, '.ovf', ''), '.png']));
    close(gcf);
end
%%
function [data]=oommf2matlab(fileToRead1)
%This is a function to import vector file archives from oommf into Matlab
%arrays
%
%Oommf vector files must be writen with the output Specifications "text %g"
%instead of the default "binary 4" option. And the type of grid must be
%rectangular.
%
%Vector files will be imported into the object "data" which will have this
%fields:
%           field: current applied magnetic field
%           xmin: minimum x value
%           xnodes: number of nodes used along x
%           xmax: maximum x value
%           ymin: minimum y value
%           ynodes: number of nodes used along y
%           ymax: maximum y value
%           zmin: minimum z value
%           znodes: number of nodes used along z
%           zmax: maximum z value
%           datax: component x of vector on data file
%           datay: component y of vector on data file
%           dataz: component z of vector on data file
%           positionx: x positions of vectors
%           positiony: y positions of vectors
%           positionz: z positions of vectors
%
%   Example:
%       We have created with Oommf the archive test.omf (included on the
%       zip). To open it into "data"
%
%       data=oommf2matlab('test.omf')
%
%       Now we can make a 2D vector field
%
%       quiver(data.positionx,data.positiony,data.datax,data.datay,0.5)
%
%       or calculate the divergence and plot it
%
%       div=divergence(data.positionx,data.positiony,data.datax,data.datay);
%       pcolor(data.positionx,data.positiony,div)
%       shading flat
%       colormap bone
%
%       For more examples, you can see my blog (look for Oommf, to be updated shortly):
%       http://thebrickinthesky.wordpress.com/
%
%  References:
%  [1] Oommf Micromagnetic simulator at NIST,
%      http://math.nist.gov/oommf/
%
%This function was written by :
%                             Hctor Corte
%                             B.Sc. in physics 2010
%                             M.Sc. in Complex physics systems 2012
%                             Ph.D Student between NPL (National Physical Laboratory) and Royal Holloway University of London
%                             London,
%                             United kingdom.
%                             Email: leo_corte@yahoo.es
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%We open the data file and start reading lines. The first lines are the
%header with information about the simulation. On this version not all the
%information is stracted, but is quite easy to do
fileA=fopen(fileToRead1,'r');
linea=fgetl(fileA);
data.xmin=[];


while isempty(strfind(linea,'# Begin: Data Text'))==1
    %The headers ends when the line # Begin: Data Text appears    
    
    %%%%%%%%%%%%%%%%%%%%%%%% Each one of these is going to look for some
    %%%%%%%%%%%%%%%%%%%%%%%% information on the header. This one for the
    %%%%%%%%%%%%%%%%%%%%%%%% applied field
    if isempty(strfind(linea,'# Desc: Applied field (T):'))~=1        
        remain = linea;
        while true
            [str, remain] = strtok(remain);
            if strcmp(str,'(T):')==1
                [str, remain] = strtok(remain);
                data.field(1)=  str2num(str);
                [str, remain] = strtok(remain);
                data.field(2)=  str2num(str);
                [str, remain] = strtok(remain);
                data.field(3)=  str2num(str);
            end
            if isempty(str),  break;  end            
        end        
    end
    %%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%This one is for the simulation grid,
    %%%%%%%%%%%%%%%%%%%%%%%%for the number of nodes on x
    if isempty(strfind(linea,'# xnodes'))~=1        
        remain = linea;        
        [~, remain] = strtok(remain);
        [~, remain] = strtok(remain);
        [str, ~] = strtok(remain);
        data.xnodes=  str2num(str);       
    end    
    %%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%Number of nodes on y
    if isempty(strfind(linea,'# ynodes'))~=1        
        remain = linea;        
        [~, remain] = strtok(remain);
        [~, remain] = strtok(remain);
        [str, ~] = strtok(remain);
        data.ynodes=  str2num(str);        
    end    
    %%%%%%%%%%%%%%%%%%    
    
    %%%%%%%%%%%%%%%%%%%%%%%%Number of nodes on z
    if isempty(strfind(linea,'# znodes'))~=1        
        remain = linea;        
        [~, remain] = strtok(remain);
        [~, remain] = strtok(remain);
        [str, ~] = strtok(remain);
        data.znodes=  str2num(str);        
    end    
    %%%%%%%%%%%%%%%%%%    
    
    %%%%%%%%%%%%%%%%%%%%%%%%Now the min and maximum values of x y and z
    if isempty(strfind(linea,'# xmin:'))~=1        
        remain = linea;        
        [~, remain] = strtok(remain);
        [~, remain] = strtok(remain);
        [str, ~] = strtok(remain);
        data.xmin=  str2num(str);        
    end    
    %%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    if isempty(strfind(linea,'# ymin:'))~=1        
        remain = linea;        
        [~, remain] = strtok(remain);
        [~, remain] = strtok(remain);
        [str, ~] = strtok(remain);
        data.ymin=  str2num(str);
    end    
    %%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    if isempty(strfind(linea,'# zmin:'))~=1        
        remain = linea;        
        [~, remain] = strtok(remain);
        [~, remain] = strtok(remain);
        [str, ~] = strtok(remain);
        data.zmin=  str2num(str);       
    end    
    %%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    if isempty(strfind(linea,'# xmax:'))~=1        
        remain = linea;        
        [~, remain] = strtok(remain);
        [~, remain] = strtok(remain);
        [str, ~] = strtok(remain);        
        data.xmax=  str2num(str);         
    end    
    %%%%%%%%%%%%%%%%%%   
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    if isempty(strfind(linea,'# ymax:'))~=1        
        remain = linea;        
        [~, remain] = strtok(remain);
        [~, remain] = strtok(remain);
        [str, ~] = strtok(remain);
        data.ymax=  str2num(str);        
    end    
    %%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    if isempty(strfind(linea,'# zmax:'))~=1        
        remain = linea;        
        [~, remain] = strtok(remain);
        [~, remain] = strtok(remain);
        [str, ~] = strtok(remain);
        data.zmax=  str2num(str);        
    end    
    %%%%%%%%%%%%%%%%%%    
    linea=fgetl(fileA);    
end
%Now beguins the reading of the vector field values.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Because we already have the data about the grid, size and number of nodes,
%we can create the arrays containing the coordinates of the points on the
%grid. It is necesary here that the simulation grid is rectangular.
x=linspace(data.xmin,data.xmax,data.xnodes);
y=linspace(data.ymin,data.ymax,data.ynodes);
z=linspace(data.zmin,data.zmax,data.znodes);
[X,Y,Z]=meshgrid(x,y,z);
data.datax=0.*permute(X,[2,1,3]);%Gives the proper size to datax
data.datay=0.*permute(Y,[2,1,3]);%Gives the proper size to datay
data.dataz=0.*permute(Z,[2,1,3]);%Gives the proper size to dataz
data.positionx=permute(X,[2,1,3]);
data.positiony=permute(Y,[2,1,3]);
data.positionz=permute(Z,[2,1,3]);
%Now beguins to read the vector field and store their components.
%Since our scan of the file is at the beguining of the data, we can scan for the
%data in the format of '%f \t%f \t%f' The scan will end at the end of the
%file because the format changes again.
s=textscan(fileA,'%f \t%f \t%f');
S=cell2mat(s);
data.datax(:)=S(:,1);
data.datay(:)=S(:,2);
data.dataz(:)=S(:,3);

fclose(fileA);
end