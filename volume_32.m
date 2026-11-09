%% Cálculo do volume - Modelo 32 marcadores
% por Amanda Piaia Silvatti

function [resv,volumes]=volume_32(mat,t);
resv=zeros(size(mat,1),9);
model=[1 5 21 17 2 6 22 18;
    5 9 25 21 6 10 26 22;
    9 13 29 25 10 14 30 26; 
    2 6 22 18 3 7 23 19;
    6 10 26 22 7 11 27 23;
    10 14 30 26 11 15 31 27;
    3 7 23 19 4 8 24 20;
    7 11 27 23 8 12 28 24;
    11 15 31 27 12 16 32 28];

for m=1:9;
    a=model(m,1); b=model(m,2); c=model(m,3);d=model(m,4);e=model(m,5);f=model(m,6);g=model(m,7);h=model(m,8);
    for i=1:size(mat,1);
        p1=mat(i,a*3-1:a*3+1);
        p2=mat(i,b*3-1:b*3+1);
        p3=mat(i,c*3-1:c*3+1);
        p4=mat(i,d*3-1:d*3+1);
        p5=mat(i,e*3-1:e*3+1);
        p6=mat(i,f*3-1:f*3+1);
        p7=mat(i,g*3-1:g*3+1);
        p8=mat(i,h*3-1:h*3+1);
%         vt(i)=vol(p1,p2,p3,p4,p5,p6,p7,p8);
        vt(i)=vol32(p1,p2,p3,p4,p5,p6,p7,p8);
    end
    resv(:,m)=vt';
end
    resv=resv;
    
    RCp=resv(:,1)+resv(:,2)+resv(:,3); % tórax superior - txs
%     [B,A]=butter(2,0.3);
    ST_curve=RCp;
    
    RCa=resv(:,4)+resv(:,5)+resv(:,6); % tórax inferior - txi
%     [B,A]=butter(2,0.3);
    IT_curve=RCa;
    
    AB=resv(:,7)+resv(:,8)+resv(:,9); % abdomên - abs
%     [B,A]=butter(2,0.3);
    AB_curve=AB;
    
    vtx=ST_curve+IT_curve;
    vab=AB_curve;
    
    VT=vtx+vab;
    
    volumes=[VT ST_curve IT_curve AB_curve];

    