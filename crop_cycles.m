function [ST, IT, AB, VT, ST_s, IT_s, AB_s, VT_s, locs] = crop_cycles(ST_curve, IT_curve, AB_curve, VT_curve, fs)
% CROP_CYCLES Detecta início de ciclos respiratórios e segmenta as curvas
%
% Criado por Ana Luiza Lopes
% Encontra os picos mínimos, corta as curvas.
% Depois é feita uma análise detalhada das curvas e retirado os outliers
%
% Input:
%   ST_curve, IT_curve, AB_curve, VT_curve - curvas de volume
%   fs - frequência de amostragem do sinal
%
% Output:
%   ST, IT, AB, VT       - curvas normalizadas (100 pontos, 1 coluna por ciclo)
%   ST_s, IT_s, AB_s, VT_s - curvas não-normalizadas (tamanho variável, NaN-padded)
%   locs                 - índices dos vales detectados (inícios de inspiração)

%% Detecção de mínimos (inícios de inspiração)
min_dist_frames = round(1.0 * fs);
% Estima uma proeminência mínima razoável com base na variabilidade do sinal
min_prom = 0.15 * (max(VT_curve) - min(VT_curve));  % ajuste esse fator conforme necessário

[~, locs] = findpeaks(-VT_curve, ...
    'MinPeakDistance', min_dist_frames, ...
    'MinPeakProminence', min_prom);

if length(locs) < 2
    error('Segment_cycles:NotEnoughCycles', ...
        'Menos de 2 vales detectados. Verifique o sinal ou a frequência de amostragem.');
end

% Plot de checagem
figure
plot(VT_curve); hold on
plot(locs, VT_curve(locs), 'r*')
title('Vales detectados (inícios de inspiração)')
xlabel('Frames'); ylabel('VT')

%% Corte
n_cycles = length(locs) - 1;

cycle_lengths = diff(locs);
max_len = max(cycle_lengths);

ST   = nan(100, n_cycles);
IT   = nan(100, n_cycles);
AB   = nan(100, n_cycles);
VT   = nan(100, n_cycles);
ST_s = nan(max_len, n_cycles);
IT_s = nan(max_len, n_cycles);
AB_s = nan(max_len, n_cycles);
VT_s = nan(max_len, n_cycles);

for i = 1:n_cycles
    idx = locs(i):locs(i+1);
    L = length(idx);

    % Não-normalizado: copia o trecho e deixa o resto NaN
    ST_s(1:L, i) = ST_curve(idx);
    IT_s(1:L, i) = IT_curve(idx);
    AB_s(1:L, i) = AB_curve(idx);
    VT_s(1:L, i) = VT_curve(idx);

    % Normalizado: interpola o ciclo inteiro (1 a L) pra 100 pontos
    t_old = linspace(1, L, L);
    t_new = linspace(1, L, 100);   % <-- CORRIGIDO
    ST(:, i) = interp1(t_old, ST_curve(idx), t_new);
    IT(:, i) = interp1(t_old, IT_curve(idx), t_new);
    AB(:, i) = interp1(t_old, AB_curve(idx), t_new);
    VT(:, i) = interp1(t_old, VT_curve(idx), t_new);
end

end