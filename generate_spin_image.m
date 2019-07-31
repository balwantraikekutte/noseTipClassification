function spin = generate_spin_image(vertex, faces, indVertex, med)
%[vertex, faces] = read_off(namefile);
%med = computeMedianEdge(namefile);
tr = triangulation(double(faces),vertex);
normal = vertexNormal(tr);
normal = normal';
binSize = med;
W = 50;
angleSupport = pi;
imageWidth = W*binSize;
vertex = vertex';
p = vertex(:,indVertex);
numVertices = size(vertex,2);
%alpha = zeros(numVertices,1);
%beta = zeros(numVertices,1);
spin = zeros(W,W);

for i=1:numVertices
    x = vertex(:,i);
    if acos(sum(normal(:,indVertex).*normal(:,i))) < angleSupport
        alpha = sqrt(sum((x - p).^2) - (sum(normal(:,indVertex).*(x-p))).^2);
        beta = sum(normal(:,indVertex).*(x-p));
        is = floor((imageWidth/2 - beta)/binSize);
        js = floor(alpha/binSize);
        a = alpha/binSize - js;
        b = (imageWidth/2-beta)/binSize - is;
        if is >=1 && is <=(W-1) && js >=1 && js <=(W-1)
            spin(is,js) = spin(is,js) + (1-a)*(1-b);
            spin(is+1,js) = spin(is+1,js) + a*(1-b);
            spin(is, js+1)= spin(is,js+1) + (1-a)*b;
            spin(is+1,js+1) = spin(is+1,js+1) + a*b;
        end
    end
end
spin=mapminmax(spin);
%  figure;
% spin = log(1+spin);
% spin = max(max(spin)) - spin;
% imshow(spin, []);
