% gcData3D.m
% Function to manage/filter Grand Challenge 3D data in ABS format
% Essentially takes a data structure in and manages its content according
% to a the paraneters passed in varargin
%

function data3D = gcData3D(data3D,varargin)


% Process the variable argument string
nparam=length(varargin);
skip=0;
for i=1:nparam
    
    % Do we need to skip an argument, because it is not an option?
    if(skip)
        skip=0;
        continue;
         
    % List should be 'scanline-wise
    % Array should always be rows x cols
    elseif(strcmp(varargin{i},'list2array'))
        
        if(~isfield(data3D,'vlist'))
            error('processData3D: no vlist field');
        elseif( size(data3D.vlist,1) ~= (data3D.rows*data3D.cols))
            error('processData3D: vlist is wrong size')
        end

        % The abs data is read in along scan rows...
        % ...so need to carve off sets of 'ncols'
              
        varrayTransp = reshape(data3D.vlist,[data3D.cols,data3D.rows,3]);
        
        % transpose it to get to a 'rows x cols x3' array
        data3D.varray = zeros(data3D.rows,data3D.cols,3);
        data3D.varray(:,:,1) = varrayTransp(:,:,1)';
        data3D.varray(:,:,2) = varrayTransp(:,:,2)';
        data3D.varray(:,:,3) = varrayTransp(:,:,3)';
       
           
        % reshape the flags array
        farrayTransp = reshape(data3D.flist,[data3D.cols,data3D.rows]);
        % transpose it to get 'rows x cols' array
        data3D.farray = farrayTransp';
        
    elseif(strcmp(varargin{i},'clearList'))     % Used to reduce memory/disk usage
        
        data3D.vlist=[];
        data3D.flist=[];
        
       
     elseif(strcmp(varargin{i},'array2list'))
        
        if(~isfield(data3D,'varray'))
            error('processData3D: no varray field');
        end
        
        % Need to transpose, because reshape operates columnwise ...
        varrayTransp = zeros(data3D.cols,data3D.rows,3);
              
        varrayTransp(:,:,1) = data3D.varray(:,:,1)';
        varrayTransp(:,:,2) = data3D.varray(:,:,2)';
        varrayTransp(:,:,3) = data3D.varray(:,:,3)';
        
        
        % ...and rehape
        data3D.vlist = reshape(varrayTransp,[size(varrayTransp,1)*size(varrayTransp,2),3]);
        
        % Need to transpose, because reshape operates columnwise ...
        farrayTransp = data3D.farray';
         % ...and rehape
        data3D.flist = reshape(farrayTransp,[size(farrayTransp,1)*size(farrayTransp,2),1]);   
        
    elseif(strcmp(varargin{i},'clearArray'))     % Used to reduce memory/disk usage
        
        data3D.varray=[];
        data3D.farray=[];    
        
        
    elseif(strcmp(varargin{i},'downSample3Darray'))
        data3D.dsFactor=varargin{i+1};
        skip=1;
        
        if( (data3D.dsFactor ~= 2) &  (data3D.dsFactor ~= 4) & (data3D.dsFactor ~= 8) & (data3D.dsFactor ~= 16) & (data3D.dsFactor ~= 32) )
            error('processData3D: bad dsFactor');
        end
       
        % Number of down sampled vertices (fully packed)
        data3D.ndvert = (data3D.rows*data3D.cols)/(data3D.dsFactor*data3D.dsFactor);
        
        vdataDownSampledList = zeros(data3D.ndvert,3);
        flagDownSampledList = zeros(data3D.ndvert,1,'uint8');

        k=1;
        for i=1:data3D.dsFactor:data3D.rows
            for j=1:data3D.dsFactor:data3D.cols
                vdataDownSampledList(k,:) = data3D.varray(i,j,:); 
                flagDownSampledList(k,1) = data3D.farray(i,j);
                k=k+1;
            end
        end    
        
        % These are the outputs
        data3D.cols = data3D.cols/data3D.dsFactor;
        data3D.rows = data3D.rows/data3D.dsFactor;
        data3D.vlist = vdataDownSampledList;
        data3D.flist = flagDownSampledList;
        
               
       
    elseif(strcmp(varargin{i},'stripZeroFlaggedVertsFromList'))
        data3D.indData = uint32(find(data3D.flist));
        data3D.vlist =  data3D.vlist(data3D.indData,:);
        data3D.nrvert = size(data3D.vlist,1);   % Number of raw vertices
        
        
    elseif(strcmp(varargin{i},'packNaNsToList'))        
        vlist=ones(data3D.rows*data3D.cols,3)*NaN;
        vlist(data3D.indData,:)=data3D.vlist;
        data3D.vlist=vlist;
        
    % Generating this array allows us to find neighbourhood points in vertex list
    elseif(strcmp(varargin{i},'genIndexArray'))
       k=1; 
       data3D.iarray=zeros(data3D.rows,data3D.cols,'uint32');
       data3D.alist=zeros(data3D.nrvert,2,'uint32');
       for i=1:data3D.rows
            for j=1:data3D.cols
               if(data3D.farray(i,j)) 
                   data3D.iarray(i,j)=k;
                   data3D.alist(k,:)=[i j];
                   k=k+1;
               end
            end
       end
                   
        
        
    elseif(strcmp(varargin{i},'findNeighbours'))
        win=varargin{i+1};
        
        skip=1;
        
        
        maxNumNeighbours=512;                           % The maximum number of neighbours that a point can have in a neighbourhood
        nvert = size(data3D.vlist,1);
        data3D.nBlockStore=zeros(nvert,maxNumNeighbours,'uint32'); % This is a list that stores the indices of neighbours in the raw data list
        data3D.nBlockNeighbours=zeros(nvert,1,'uint32');
        
        if(nvert > 4294967295)                              % index via uint32 for lower memory use.
            error('Number of vertices is too large for uint32 representation');
        end
        
        for i=1:data3D.rows
            for j=1:data3D.cols
                
                if(data3D.farray(i,j))
                    loi=max(1,i-win);
                    hii=min(data3D.rows,i+win);
                    loj=max(1,j-win);
                    hij=min(data3D.cols,j+win);
                    
                    dataBlock=data3D.iarray(loi:hii,loj:hij);
                    dataBlock=reshape(dataBlock,[size(dataBlock,1)*size(dataBlock,2),1]);
                    dbi=find(dataBlock);
                    neighbourInds=dataBlock(dbi);
                    nNeighbours=size(neighbourInds,1);
                    
                    if(nNeighbours > maxNumNeighbours)
                        error(['Too many neighbours in local block: ' num2str(nNeighbours)]);
                    end
                                        
                    data3D.nBlockStore(data3D.iarray(i,j),1:nNeighbours)=neighbourInds';
                    data3D.nBlockNeighbours(data3D.iarray(i,j),1)=nNeighbours;
              
                    
                end
                
            end
        end
        
    
    elseif(strcmp(varargin{i},'addNoiseFlagsToFlags'))
        bitmask=varargin{i+1};                  % The passed bitmask relates to the compressed vlist (NaNs removed)
        skip=1;
        
        % Initialise as ones : i.e. no points culled.
        cullFlagArray=ones(data3D.rows,data3D.cols);
        
        
        % Find the vlist indices that are to be culled
        vlistCullInds=find(~bitmask);
        
            
        for k = 1 : size(vlistCullInds,1)
            pos = data3D.alist(vlistCullInds(k,1),:);
            cullFlagArray(pos(1,1),pos(1,2))=0;
        end
        
        
        data3D.farray = data3D.farray & cullFlagArray;
        data3D.flist = reshape(data3D.farray,[size(data3D.farray,1)*size(data3D.farray,2),1]); 

        
    % Put index in array : a procedure to help us build the triangulation mesh
    elseif(strcmp(varargin{i},'putListIndicesIntoArray'))       
        data3D.listIndArray = zeros(data3D.rows,data3D.cols,'uint32');
        k=1;
        for i=1:data3D.rows
            for j=1:data3D.cols
                data3D.listIndArray(i,j) = k;
                k=k+1;
            end
        end
        
    % For each array position we need a CUMULative HOLE CouNT :  how many holes there are to allow us to build the mesh
    elseif(strcmp(varargin{i},'compactIndices'))       
         data3D.cumulHoleCnt=zeros(data3D.rows,data3D.cols,'uint32');
         k=0;
         for i=1:data3D.rows
            for j=1:data3D.cols
                if(~data3D.farray(i,j))
                    k=k+1;
                end
                data3D.cumulHoleCnt(i,j)=k;
            end
         end
         data3D.compInd = data3D.listIndArray - data3D.cumulHoleCnt;  % Compute compacted indices
        
        
    % Do a simple triangulation, based on known structure
    elseif(strcmp(varargin{i},'triangulate'))        
        data3D.tri = zeros((data3D.rows-1)*(data3D.cols-1)*2,3,'uint32');   % up to 2 triangles per vertex
        k=1;
        for i=1:data3D.rows-1
            for j=1:data3D.cols-1
     
                if(~data3D.farray(i,j) || ~data3D.farray(i+1,j+1))
                    continue;
                elseif(data3D.farray(i+1,j) || data3D.farray(i,j+1) )
                    % shorthand
                    ia=data3D.compInd(i,j);
                    ib=data3D.compInd(i,j+1);
                    ic=data3D.compInd(i+1,j);
                    id=data3D.compInd(i+1,j+1);
                    
                    delad = data3D.vlist(ia,:) - data3D.vlist(id,:);
                    deladSq = delad(1,1)^2 + delad(1,2)^2 +delad(1,3)^2;
                       
                end
                
                % Max length of diagonal mesh link = 20 mm (20x20=400)
                if(data3D.farray(i+1,j)  && (deladSq < 400) )
                    data3D.tri(k,:) = [ia ic id];
                    k=k+1;
                end
                if(data3D.farray(i,j+1) && (deladSq < 400))
                    data3D.tri(k,:) = [ia id ib];
                    k=k+1;
                end
            end
        end
        data3D.tri = data3D.tri(1:k-1,:);
         
        
       
        
    else
        error('parameter not recognised');
  
                    
    end
     
    


end



