function [ landmarks, successFlag ] = readLdmkFile(fileName)
%readLdmrkFile: function to read Clement Creusot's '.ldmk' files
%   
%   The files contain manually labelled 3D landmark positions
%
%   Input: 
%       the landmark filename (.ldmk)
%   Outputs:
%       nx3 array of 3D landmarks 
%       flag indicating success/failure to read required number of points
%
%   Note that the landmarks are ordered as they are read from file.
%   Other information, such as the text labels of landmarks is not read.
%   


% Set the required number of 3D landmark position to be read from file.
nRequired=14;
% Storage for the 3D landmarks
landmarks=[];
 
% Open the ASCII file for reading
[fid errorMess] = fopen(fileName,'r');
% Error if we cant open the file
if(fid == -1)
    disp(['readLdmkFile: WARNING: Cant open landmark file: ' fileName]);
    successFlag = 0;    
    
else    

    % Textscan reads all of the text into a 1x1 cell array
    a = textscan(fid,'%s');
    nStrings = size(a{1,1},1);  % How many strings have been read?

    % The required landmarks are after the keyword 'position'
    for i=1:nStrings-1
        if strcmp(a{1,1}{i,1},'position');
            lpos = textscan(a{1,1}{i+1,1},'%f,%f,%f');
            landmarks = [ landmarks ; lpos{1,1} lpos{1,2} lpos{1,3} ];
        end
    end

    % Close the file
    fclose(fid);
end    
 
% How many landmarks have been read?
nLandmarks=size(landmarks,1);

% Check that we have the correct number and set flag
if(nLandmarks < nRequired)
    disp(['readLdmkFile: WARNING: read ' num2str(nLandmarks) ' require ' num2str(nRequired)]);
    successFlag=0;
else
    successFlag=1;
end    


end

