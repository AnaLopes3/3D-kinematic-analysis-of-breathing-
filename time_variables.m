function [Tempo_resp, Tempo_insp, Duty_cicle, Difftime, Phaseshift] = time_variables(ST_s, IT_s, AB_s, VT_s, fs)
% TIME_VARIABLES Calcula variáveis temporais dos ciclos respiratórios
%
% Analisidati_new - PARA AS VARIÁVEIS TEMPORAIS
% Criado por Ana Luiza Lopes
%
% Na ordem:
%   Tempo total do ciclo (Tempo_resp)
%   Tempo inspiratório (Tempo_insp)
%   Tempo inspiratório/tempo total (Duty_cicle)
%   Defasagem dos picos respiratórios em frames (Difftime)
%   Defasagem em relação ao tempo total do ciclo, em graus (Phaseshift)
%
% Input:
%   ST_s, IT_s, AB_s, VT_s - ciclos respiratórios NÃO normalizados (NaN-padded)
%   fs - frequência de amostragem do sinal
%
% Output:
%   Tempo_resp - tempo total de cada ciclo (s)                    [n_cycles x 1]
%   Tempo_insp - tempo até o pico de cada compartimento (s)       [n_cycles x 4] (ST IT AB VT)
%   Duty_cicle - tempo inspiratório / tempo total                 [n_cycles x 4] (ST IT AB VT)
%   Difftime   - defasagem entre picos, em frames                 [n_cycles x 3] (STxIT STxAB ITxAB)
%   Phaseshift - defasagem entre picos, em graus                  [n_cycles x 3] (STxIT STxAB ITxAB)

n_cycles = size(ST_s, 2);

%% Calcular os tempos respiratórios de cada ciclo
column_sizes = zeros(1, n_cycles); % número de elementos não-NaN em cada coluna
for u = 1:n_cycles
    column_sizes(u) = sum(~isnan(ST_s(:, u)));
end

Ttot = zeros(1, n_cycles);
for y = 1:n_cycles
    Ttot(y) = column_sizes(y) / fs;
end

%% Tempo inspiratório compartimental e Duty Cicle (tempo insp/tempo tot)
maxSTi = zeros(1, n_cycles);
maxITi = zeros(1, n_cycles);
maxABi = zeros(1, n_cycles);
maxVTi = zeros(1, n_cycles);

ST_Ti = zeros(1, n_cycles);
IT_Ti = zeros(1, n_cycles);
AB_Ti = zeros(1, n_cycles);
VT_Ti = zeros(1, n_cycles);

ST_dutycicle = zeros(1, n_cycles);
IT_dutycicle = zeros(1, n_cycles);
AB_dutycicle = zeros(1, n_cycles);
VT_dutycicle = zeros(1, n_cycles);

for e = 1:n_cycles
    [~, maxSTi(e)] = max(ST_s(:, e));
    [~, maxITi(e)] = max(IT_s(:, e));
    [~, maxABi(e)] = max(AB_s(:, e));
    [~, maxVTi(e)] = max(VT_s(:, e));

    ST_Ti(e) = maxSTi(e) / fs;
    IT_Ti(e) = maxITi(e) / fs;
    AB_Ti(e) = maxABi(e) / fs;
    VT_Ti(e) = maxVTi(e) / fs;

    ST_dutycicle(e) = ST_Ti(e) / Ttot(e);
    IT_dutycicle(e) = IT_Ti(e) / Ttot(e);
    AB_dutycicle(e) = AB_Ti(e) / Ttot(e);
    VT_dutycicle(e) = VT_Ti(e) / Ttot(e);
end

Tempo_resp = Ttot';
Tempo_insp = [ST_Ti', IT_Ti', AB_Ti', VT_Ti'];
Duty_cicle = [ST_dutycicle', IT_dutycicle', AB_dutycicle', VT_dutycicle'];

%% Tlag dos ciclos respiratórios (defasagem em frames)
Tlag_STxIT = zeros(1, n_cycles);
Tlag_STxAB = zeros(1, n_cycles);
Tlag_ITxAB = zeros(1, n_cycles);

for e = 1:n_cycles
    Tlag_STxIT(e) = maxSTi(e) - maxITi(e);
    Tlag_STxAB(e) = maxSTi(e) - maxABi(e);
    Tlag_ITxAB(e) = maxITi(e) - maxABi(e);
end

Difftime = [Tlag_STxIT', Tlag_STxAB', Tlag_ITxAB'];

%% Phase shift (defasagem em graus)
Phaseshift_STxIT = zeros(1, n_cycles);
Phaseshift_STxAB = zeros(1, n_cycles);
Phaseshift_ITxAB = zeros(1, n_cycles);

for w = 1:n_cycles
    Phaseshift_STxIT(w) = ((Tlag_STxIT(w) / fs) / Ttot(w)) * 180;
    Phaseshift_STxAB(w) = ((Tlag_STxAB(w) / fs) / Ttot(w)) * 180;
    Phaseshift_ITxAB(w) = ((Tlag_ITxAB(w) / fs) / Ttot(w)) * 180;
end

Phaseshift = [Phaseshift_STxIT', Phaseshift_STxAB', Phaseshift_ITxAB'];

%% Figura 1 - Tempo total do ciclo respiratório
figure
plot(Tempo_resp, '-o k'); hold on
yline(mean(Tempo_resp), '--r', 'Média');
title('Tempo total do ciclo respiratório')
xlabel('Ciclo')
ylabel('Tempo (s)')
grid on

%% Figura 2 - Tempo inspiratório compartimental
figure
plot(Tempo_insp(:,1), '-o'); hold on
plot(Tempo_insp(:,2), '-o');
plot(Tempo_insp(:,3), '-o');
plot(Tempo_insp(:,4), '-ok', 'LineWidth', 1.5);
title('Tempo inspiratório por compartimento')
xlabel('Ciclo')
ylabel('Tempo até o pico (s)')
legend('ST', 'IT', 'AB', 'VT')
grid on

%% Figura 3 - Duty cicle compartimental
figure
plot(Duty_cicle(:,1), '-o'); hold on
plot(Duty_cicle(:,2), '-o');
plot(Duty_cicle(:,3), '-o');
plot(Duty_cicle(:,4), '-ok', 'LineWidth', 1.5);
title('Duty cicle (tempo insp / tempo total)')
xlabel('Ciclo')
ylabel('Duty cicle')
legend('ST', 'IT', 'AB', 'VT')
grid on

%% Figura 4 - Defasagem entre picos (frames)
figure
plot(Difftime(:,1), '-o'); hold on
plot(Difftime(:,2), '-o');
plot(Difftime(:,3), '-o');
yline(0, '--k');
title('Defasagem entre picos (Difftime)')
xlabel('Ciclo')
ylabel('Defasagem (frames)')
legend('STxIT', 'STxAB', 'ITxAB')
grid on

%% Figura 5 - Phase shift (graus)
figure
plot(Phaseshift(:,1), '-o'); hold on
plot(Phaseshift(:,2), '-o');
plot(Phaseshift(:,3), '-o');
yline(0, '--k');
title('Phase shift entre compartimentos')
xlabel('Ciclo')
ylabel('Defasagem (graus)')
legend('STxIT', 'STxAB', 'ITxAB')
grid on

end