function [t]= tetra(v1,v2,v3,v4); %a,b,c,d,e,f,g,h ovvero p1 p2 p3 p4 p5 p6 p7 p8
 u=v2-v1;
 v=v3-v2;
 w=v4-v1;
 t=norm((dot(cross(u,v),w))/6);
 
 % restituisce il prodotto scalare normalizzato 
 % con il comando cross si effettua un prodotto tra due vettori 3D e si
 % ottiene come risultato un vettore che ? perpendicolare ad entrambi.
 
 
%1 dei 6 volumi(i) del vol