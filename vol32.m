function [V]=vol32(a,b,c,d,e,f,g,h);
V1=tetra32(a,e,f,h);
V2=tetra32(a,b,f,h);
V3=tetra32(a,b,d,h);
V4=tetra32(b,c,d,h);
V5=tetra32(b,c,g,h)
V6=tetra32(b,f,g,h);
V=V1+V2+V3+V4+V5+V6;
