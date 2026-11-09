function phase_angle = coord_phase_angle(ST, IT, AB)
% PHASE_ANGLE Calcula o ângulo de fase de coordenação torácico-abdominal
% Variáveis derivadas - Coordenação
% Input:
%   ST, IT, AB - Curvas médias (normalizadas) de tórax superior, tórax
%                inferior e abdômen. Cada coluna representa um ciclo.
%
% Output:
%   phase_angle - vetor [angTSxTI, angTSxAB, angTIxAB] concatenado
%                 (ângulos de fase para cada par de curvas, em graus)

%% Coordenação Ângulo de Fase - Curvas médias
num_colunas = size(ST, 2);

% Pré-alocação dos vetores
TSr    = zeros(1, num_colunas);
TIr    = zeros(1, num_colunas);
ABr    = zeros(1, num_colunas);
minTS  = zeros(1, num_colunas);
minTI  = zeros(1, num_colunas);
minAB  = zeros(1, num_colunas);
CTS    = zeros(1, num_colunas);
CTI    = zeros(1, num_colunas);
mmTS   = zeros(1, num_colunas);
mmTI   = zeros(1, num_colunas);

mm1TSxTI = zeros(1, num_colunas);
mm2TSxTI = zeros(1, num_colunas);
mm1TSxAB = zeros(1, num_colunas);
mm2TSxAB = zeros(1, num_colunas);
mm1TIxAB = zeros(1, num_colunas);
mm2TIxAB = zeros(1, num_colunas);

mTSxTI = zeros(1, num_colunas);
mTSxAB = zeros(1, num_colunas);
mTIxAB = zeros(1, num_colunas);

angTSxTI = zeros(1, num_colunas);
angTSxAB = zeros(1, num_colunas);
angTIxAB = zeros(1, num_colunas);

for j = 1:num_colunas
    % Amplitude das curvas
    TSr(j) = range(ST(:, j));
    TIr(j) = range(IT(:, j));
    ABr(j) = range(AB(:, j));
    minTS(j) = min(ST(:, j));
    minTI(j) = min(IT(:, j));
    minAB(j) = min(AB(:, j));

    [~, CTS(j)] = max(ST(:, j)); % encontra o pico da curva
    [~, CTI(j)] = max(IT(:, j));

    mmTS(j) = (TSr(j) / 2) + minTS(j); % y de referência para ST
    mmTI(j) = (TIr(j) / 2) + minTI(j); % y de referência para TI

    % Interpolação para obter os valores de X correspondentes ao Y referência
    mm1TSxTI(j) = interp1(ST(1:CTS(j), j), IT(1:CTS(j), j), mmTS(j));
    mm2TSxTI(j) = interp1(ST(CTS(j):end, j), IT(CTS(j):end, j), mmTS(j));
    mm1TSxAB(j) = interp1(ST(1:CTS(j), j), AB(1:CTS(j), j), mmTS(j));
    mm2TSxAB(j) = interp1(ST(CTS(j):end, j), AB(CTS(j):end, j), mmTS(j));
    mm1TIxAB(j) = interp1(IT(1:CTI(j), j), AB(1:CTI(j), j), mmTI(j));
    mm2TIxAB(j) = interp1(IT(CTI(j):end, j), AB(CTI(j):end, j), mmTI(j));

    % Cálculo dos ângulos para cada coluna
    mTSxTI(j) = mm2TSxTI(j) - mm1TSxTI(j);
    mTSxAB(j) = mm2TSxAB(j) - mm1TSxAB(j);
    mTIxAB(j) = mm2TIxAB(j) - mm1TIxAB(j);

    angTSxTI(j) = asin(mTSxTI(j) / TIr(j)) * 57.3;
    angTSxAB(j) = asin(mTSxAB(j) / ABr(j)) * 57.3;
    angTIxAB(j) = asin(mTIxAB(j) / ABr(j)) * 57.3;
end

phase_angle = [angTSxTI, angTSxAB, angTIxAB];

%% Figura - Diagramas de Lissajous (compartimento x compartimento)
figure
subplot(1,3,1)
plot(ST, IT)
xlabel('ST'); ylabel('IT')
title('ST x IT')
axis square

subplot(1,3,2)
plot(ST, AB)
xlabel('ST'); ylabel('AB')
title('ST x AB')
axis square

subplot(1,3,3)
plot(IT, AB)
xlabel('IT'); ylabel('AB')
title('IT x AB')
axis square

sgtitle('Diagramas de Lissajous')

end