function [Volamp_TOT, Contribution, RC_percent] = volume_variables(ST, IT, AB)
% VOLUME_VARIABLES Calcula variáveis derivadas de volume
%
% Variáveis derivadas - Volume
% por Ana Luiza Lopes
%
% Tidal volume inspiratório (Volamp_TOT)
% Percentual de contribuição inspiratório (Contribution)
% Percentual de contribuição da Caixa Torácica (RC_percent)
%
% Input:
%   ST, IT, AB - Ciclos normalizados (ou não-normalizados) de tórax
%                superior, tórax inferior e abdômen (1 coluna por ciclo)
%
% Output:
%   Volamp_TOT   - volume corrente total (amplitude ST+IT+AB) por ciclo
%   Contribution - percentual de contribuição inspiratório [ST IT AB] (colunas)
%   RC_percent   - percentual de contribuição da Caixa Torácica (ST+IT) por ciclo

n_cycles = size(ST, 2);

%% Tidal volume inspiratório
ST_max   = zeros(1, n_cycles);
IT_max   = zeros(1, n_cycles);
AB_max   = zeros(1, n_cycles);
ST_min   = zeros(1, n_cycles);
IT_min   = zeros(1, n_cycles);
AB_min   = zeros(1, n_cycles);
Volamp_ST  = zeros(1, n_cycles);
Volamp_IT  = zeros(1, n_cycles);
Volamp_AB  = zeros(1, n_cycles);
Volamp_TOT = zeros(1, n_cycles);

for j = 1:n_cycles
    % Valor máximo
    ST_max(j) = max(ST(:, j));
    IT_max(j) = max(IT(:, j));
    AB_max(j) = max(AB(:, j));

    % Valor mínimo
    ST_min(j) = min(ST(:, j));
    IT_min(j) = min(IT(:, j));
    AB_min(j) = min(AB(:, j));

    % Amplitude
    Volamp_ST(j)  = ST_max(j) - ST_min(j);
    Volamp_IT(j)  = IT_max(j) - IT_min(j);
    Volamp_AB(j)  = AB_max(j) - AB_min(j);
    Volamp_TOT(j) = Volamp_ST(j) + Volamp_IT(j) + Volamp_AB(j);
end

%% Percentual de contribuição inspiratório
vts  = zeros(1, n_cycles);
vti  = zeros(1, n_cycles);
vab  = zeros(1, n_cycles);
vtot = zeros(1, n_cycles);

for i = 1:n_cycles
    vts(i) = max(ST(:, i)) - ST(1, i);
    vti(i) = max(IT(:, i)) - IT(1, i);
    vab(i) = max(AB(:, i)) - AB(1, i);
    vtot(i) = vts(i) + vti(i) + vab(i);
end

Contribution = [((vts ./ vtot)' * 100), ((vti ./ vtot)' * 100), ((vab ./ vtot)' * 100)];

%% Percentual de contribuição da Caixa Torácica
% Essa variável diz quantos porcento do tórax contribui para o volume total
RC = vts + vti;
RC_percent = (RC ./ vtot) * 100;

%% Figura 1 - Volume corrente total e por compartimento, por ciclo
figure
plot(Volamp_ST, '-o'); hold on
plot(Volamp_IT, '-o');
plot(Volamp_AB, '-o');
plot(Volamp_TOT, '-ok', 'LineWidth', 1.5);
title('Volume corrente por ciclo')
xlabel('Ciclo')
ylabel('Amplitude de volume')
legend('ST', 'IT', 'AB', 'TOTAL')
grid on

%% Figura 2 - Percentual de contribuição inspiratório (ST, IT, AB)
figure
bar(Contribution, 'stacked')
title('Percentual de contribuição inspiratório por ciclo')
xlabel('Ciclo')
ylabel('Contribuição (%)')
legend('ST', 'IT', 'AB', 'Location', 'eastoutside')
ylim([0 100])
grid on

%% Figura 3 - Percentual de contribuição da Caixa Torácica (RC%)
figure
plot(RC_percent, '-o'); hold on
yline(mean(RC_percent), '--r', 'Média');
title('Percentual de contribuição da Caixa Torácica (RC%)')
xlabel('Ciclo')
ylabel('RC (%)')
grid on

end