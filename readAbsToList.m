% Function to read raw data from an ABS file.
% NaN is asigned when flag(i)==0 a
%
% data3D is the 3D data structure
% I is the associated intensity image
% Need to keep NaNs in place, so that we can downsample
% Reads data in from top row, left to right and then down the scan lines.


function [data3D,I] = readAbsToList(absFile, imgFlag)

    %keyboard;

   %fprintf(1,'Reading raw data...');
   [fp errMess] = fopen(absFile,'r');
   if(fp== -1)
       absFile
       disp(errMess);
       pause;
   end
       
   data3D.rows = sscanf(fgetl(fp),'%d %*s');
   data3D.cols = sscanf(fgetl(fp),'%d %*s');
   fgetl(fp);

   data3D.flist = sscanf(fgetl(fp),'%d');
   data3D.flist = uint8(data3D.flist);  % Save memory
   
   X = sscanf(fgetl(fp),'%f');
   Y = sscanf(fgetl(fp),'%f');
   Z = sscanf(fgetl(fp),'%f');
   fclose(fp);
   
   data = [X Y Z];
  
   %disp(['Raw data has ' num2str(size(data,1)) ' vertices.']);
   
   
   ndata = NaN * ones(data3D.cols*data3D.rows, 3);
   indData = find(data3D.flist);

   data3D.nrvert = size(indData,1);     % Number of raw vertices
   
   ndata(indData, :) = data(indData, :);
   
   data3D.vlist = ndata;
   
    
   I=[];                % In case imgFlag is zero
  
   
   if (imgFlag)
      Imgname = strrep(absFile,'.abs','.ppm');
      I = imread(Imgname);
      data3D.imarray = I;  % Load up the registered 2D image into the structure
      
      % Need to transpose, because reshape operates columnwise ...
      imarrayTransp = zeros(data3D.cols,data3D.rows,3);
      imarrayTransp(:,:,1) = data3D.imarray(:,:,1)';
      imarrayTransp(:,:,2) = data3D.imarray(:,:,2)';
      imarrayTransp(:,:,3) = data3D.imarray(:,:,3)';
                
      % ...and reshape
      data3D.imlist = reshape(imarrayTransp,[size(imarrayTransp,1)*size(imarrayTransp,2),3]);
      
      data3D.imlist = data3D.imlist(indData,:);
      
   end
   
  
   
   data3D.dsFactor=1;     % Set the down-sample factor to 1 : there is none!
     
   %fprintf(1,'done. \n');
