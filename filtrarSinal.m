function [dados, relatorio] = filtrarSinal(dados, modo, fc_usuario)
% filtrarSinal  Filtra todos os marcadores do struct de dados.
%
% -------------------------------------------------------------------------
%  MODOS DE USO:
%
%   dados = filtrarSinal(dados)                  % espectral (padrão)
%   dados = filtrarSinal(dados, 'espectral')     % fc pela média espectral de todos os canais
%   dados = filtrarSinal(dados, 'usuario', fc)   % fc definida pelo usuário em Hz
%
%  ENTRADA:
%   dados        – struct saído de ler_c3d com campos:
%                    .marcadores  [n_frames × 3 × n_marcadores]
%                    .freq_hz     frequência de amostragem (Hz)
%                    .labels      nomes dos marcadores
%                    .tempo       vetor de tempo (s)
%   modo         – 'espectral' | 'usuario'  (padrão: 'espectral')
%   fc_usuario   – frequência de corte em Hz (só para modo 'usuario')
%
%  ANÁLISE ESPECTRAL (modo 'espectral'):
%   Calcula a fc individualmente para cada canal (marcador × eixo),
%   usando o critério de 99% de energia acumulada.
%   fc_final = média de todas as fc individuais (n_marcadores × 3 canais).
%   Assumem-se dados sem NaN (execute preProcessNaN antes).
%
%  FILTRO APLICADO:
%   Butterworth passa-baixa de 4ª ordem, fase zero (filtfilt)
%   → sem distorção de fase → picos de volume não deslocados no tempo
%   → essencial para Tlag e phase angle corretos
%
%  SAÍDA:
%   dados           – struct com .marcadores filtrados (mesma estrutura)
%   relatorio.fc    – frequência de corte usada (Hz)
%   relatorio.modo  – modo utilizado
%   relatorio.fc_canais – vetor com fc de cada canal (modo espectral)
%   relatorio.n_canais  – número de canais usados na média
%
%  Criado para: Breathing Toolbox – pré-processamento cinemática 3D
% -------------------------------------------------------------------------

    %% Validar entrada
    if nargin < 1 || ~isstruct(dados)
        error('filtrarSinal: informe o struct de dados (saída de ler_c3d).');
    end
    if ~isfield(dados, 'marcadores') || ~isfield(dados, 'freq_hz')
        error('filtrarSinal: struct deve conter os campos .marcadores e .freq_hz.');
    end
    if nargin < 2 || isempty(modo)
        modo = 'espectral';
    end

    fs        = dados.freq_hz;
    nyquist   = fs / 2;
    n_frames  = size(dados.marcadores, 1);
    n_marc    = size(dados.marcadores, 3);
    eixos     = {'X', 'Y', 'Z'};

    %  1. DEFINIR FREQUÊNCIA DE CORTE
    switch lower(modo)

        case 'espectral'
            fprintf('\n  Modo espectral: calculando fc media sobre todos os canais...\n');
            [fc, fc_canais] = fcMediaEspectral(dados.marcadores, fs);
            fprintf('  Canais analisados : %d  (%d marcadores x 3 eixos)\n', ...
                    numel(fc_canais), n_marc);
            fprintf('  fc por canal      : min=%.2f  max=%.2f  dp=%.2f Hz\n', ...
                    min(fc_canais), max(fc_canais), std(fc_canais));
            fprintf('  fc final (media)  : %.2f Hz\n', fc);

        case 'usuario'
            if nargin < 3 || isempty(fc_usuario)
                error('No modo ''usuario'' e necessario informar fc_usuario em Hz.');
            end
            fc        = fc_usuario;
            fc_canais = [];
            fprintf('\n  Modo usuario: fc = %.2f Hz\n', fc);

        otherwise
            error('Modo invalido. Use ''espectral'' ou ''usuario''.');
    end

    %% Validar fc
    if fc <= 0 || fc >= nyquist
        error('fc = %.2f Hz invalida. Deve estar entre 0 e Nyquist (%.1f Hz).', fc, nyquist);
    end

    %% 2. DESIGN DO FILTRO

    Wn     = fc / nyquist;
    [b, a] = butter(4, Wn, 'low');

    %%  3. FILTRAR TODOS OS MARCADORES (todos os eixos)
    fprintf('\n========= Filtragem do Sinal =========\n');
    fprintf('  fs     : %.1f Hz\n', fs);
    fprintf('  fc     : %.2f Hz\n', fc);
    fprintf('  Filtro : Butterworth 4a ordem, zero-phase (filtfilt)\n');
    fprintf('  Canais : %d marcadores x 3 eixos = %d canais\n', n_marc, n_marc*3);
    fprintf('--------------------------------------\n');

    for m = 1:n_marc
        for e = 1:3
            sinal = dados.marcadores(:, e, m);
            dados.marcadores(:, e, m) = filtfilt(b, a, sinal);
        end
    end

    fprintf('  [OK] Todos os canais filtrados.\n');
    fprintf('======================================\n\n');

    %%
    %  4. GRÁFICO DIAGNÓSTICO
    plotDiagnostico(dados, fs, fc, modo, fc_canais, b, a, n_frames);

    %% ------------------------------------------------------------------
    %  5. SAÍDA
    % ------------------------------------------------------------------
    relatorio.fc       = fc;
    relatorio.modo     = modo;
    relatorio.fc_canais = fc_canais;
    relatorio.n_canais  = numel(fc_canais);
end


%%  HELPER 1 – fc média sobre todos os canais (marcadores × eixos)

function [fc_media, fc_canais] = fcMediaEspectral(marcadores, fs)

    n_marc   = size(marcadores, 3);
    fc_canais = zeros(1, n_marc * 3);
    k = 0;

    for m = 1:n_marc
        for e = 1:3
            k = k + 1;
            sinal = marcadores(:, e, m);
            fc_canais(k) = fcUmCanal(sinal, fs);
        end
    end

    fc_media = mean(fc_canais);
end


%% HELPER 2 – fc de um único canal (99% energia + 20% margem)

function fc = fcUmCanal(sinal, fs)

    N          = length(sinal);
    ndata      = floor(N / 2);
    resp_fft   = fft(sinal);
    resp_PS    = resp_fft .* conj(resp_fft);
    PSpositive = resp_PS(2 : ndata + 1);
    j_freq     = (fs / 2) / ndata * (1 : ndata);

    cumsumPS = cumsum(PSpositive) / sum(PSpositive) * 100;
    idx      = find(cumsumPS >= 99, 1);
    fc_raw   = j_freq(idx);

    % Margem de segurança de 20%
    fc = min(round(fc_raw * 1.2, 1), (fs / 2) - 0.1);
end


%%  HELPER 3 – Gráfico diagnóstico (3 painéis)

function plotDiagnostico(dados, fs, fc, modo, fc_canais, b, a, n_frames)

    nyquist  = fs / 2;
    n_marc   = size(dados.marcadores, 3);

    % Sinal de referência para os painéis 1 e 3:
    % marcador com maior variância no eixo Z = maior excursão respiratória
    Z_todos      = squeeze(dados.marcadores(:, 3, :));  % [n_frames × n_marc]
    [~, idx_ref] = max(var(Z_todos));
    Z_ref        = Z_todos(:, idx_ref);
    Z_filt       = filtfilt(b, a, Z_ref);

    if isfield(dados, 'labels') && numel(dados.labels) >= idx_ref
        nome_marc_ref = dados.labels{idx_ref};
    else
        nome_marc_ref = sprintf('Marcador %d', idx_ref);
    end
    fprintf('  Marcador de referencia no grafico: %s (maior variancia em Z)\n', nome_marc_ref);

    figure('Name', 'filtrarSinal – Diagnostico', ...
           'NumberTitle', 'off', ...
           'Position', [80 40 600 600]);

    %% ---- Painel 1: Distribuição das fc por canal (modo espectral)
    %%               ou espectro do sinal de referência (modo usuario)
    ax1 = subplot(3, 1, 1);

    if strcmpi(modo, 'espectral') && ~isempty(fc_canais)

        % Histograma das fc individuais de todos os canais
        histogram(ax1, fc_canais, 20, 'FaceColor', [0.3 0.5 0.8], ...
                  'EdgeColor', 'white', 'FaceAlpha', 0.85);
        hold(ax1, 'on');
        xline(ax1, fc, 'r-', 'LineWidth', 2, ...
              'Label', sprintf('fc media = %.2f Hz', fc), ...
              'LabelVerticalAlignment', 'bottom', ...
              'LabelHorizontalAlignment', 'right');
        xline(ax1, mean(fc_canais) - std(fc_canais), 'k--', 'LineWidth', 1);
        xline(ax1, mean(fc_canais) + std(fc_canais), 'k--', 'LineWidth', 1, ...
              'Label', sprintf('+/- 1 DP  (%.2f Hz)', std(fc_canais)), ...
              'LabelVerticalAlignment', 'top');

        xlabel(ax1, 'fc por canal (Hz)');
        ylabel(ax1, 'Contagem de canais');
        title(ax1, sprintf('Distribuicao das fc individuais — %d canais (%d marcadores x 3 eixos)', ...
              numel(fc_canais), n_marc));
        grid(ax1, 'on');

    else
        % Modo usuario — mostra espectro do marcador de referência
        N          = length(Z_ref);
        ndata      = floor(N / 2);
        resp_fft   = fft(Z_ref);
        resp_PS    = resp_fft .* conj(resp_fft);
        PSpositive = resp_PS(2 : ndata + 1);
        j_freq     = (fs / 2) / ndata * (1 : ndata);

        semilogy(ax1, j_freq, PSpositive, 'b', 'LineWidth', 1.2);
        hold(ax1, 'on');
        xline(ax1, fc, 'r--', 'LineWidth', 1.5, ...
              'Label', sprintf('fc = %.2f Hz (usuario)', fc), ...
              'LabelVerticalAlignment', 'bottom');

        xlabel(ax1, 'Frequencia (Hz)');
        ylabel(ax1, 'Power Spectrum (log)');
        title(ax1, sprintf('Espectro de potencia – %s (maior variancia em Z)', nome_marc_ref));
        grid(ax1, 'on');
        ax1.XLim(1) = 0;
    end

    %% Painel 2: Resposta em frequência do filtro 
    ax2 = subplot(3, 1, 2);

    w    = linspace(0, pi, 1024);
    f_hz = w / pi * nyquist;
    H    = freqz(b, a, w);
    H_db = 20 * log10(abs(H) + eps);

    plot(ax2, f_hz, H_db, 'b', 'LineWidth', 1.5);
    hold(ax2, 'on');
    xline(ax2, fc, 'r--', 'LineWidth', 1.5, ...
          'Label', sprintf('fc = %.2f Hz', fc), ...
          'LabelVerticalAlignment', 'bottom');
    yline(ax2, -3, 'k:', 'LineWidth', 1.2, 'Label', '-3 dB');

    xlabel(ax2, 'Frequencia (Hz)');
    ylabel(ax2, 'Magnitude (dB)');
    title(ax2, sprintf('Resposta em Frequencia – Butterworth 4a ordem  |  fc = %.2f Hz', fc));
    grid(ax2, 'on');
    ax2.XLim = [0 nyquist];
    ax2.YLim = [-150 5];

    %% Painel 3: Sinal original vs filtrado 
    ax3 = subplot(3, 1, 3);

    t         = (0 : n_frames - 1) / fs;
    n_mostrar = min(n_frames, round(10 * fs));
    t_plot    = t(1 : n_mostrar);

    plot(ax3, t_plot, Z_ref(1:n_mostrar), ...
         'Color', [0.1 0.1 0.1], 'LineWidth', 1.0);   % preto escuro
    hold(ax3, 'on');
    plot(ax3, t_plot, Z_filt(1:n_mostrar), ...
         'Color', [0.0 0.45 0.74], 'LineWidth', 2.2); % azul vivo por cima

    legend(ax3, 'Original', 'Filtrado', 'Location', 'best');
    xlabel(ax3, 'Tempo (s)');
    ylabel(ax3, 'Posicao Z (mm)');
    title(ax3, sprintf('Sinal original vs filtrado – %s (maior variancia em Z)', nome_marc_ref));
    grid(ax3, 'on');

    %% Título geral
    sgtitle(sprintf('filtrarSinal  |  modo: %s  |  fc = %.2f Hz  |  fs = %.0f Hz', ...
                    modo, fc, fs), 'FontWeight', 'bold', 'FontSize', 12);

    %% Ajuste manual de espaçamento entre painéis
    % [left, bottom, width, height] — normalizado [0,1]
    ax1.Position = [0.10  0.70  0.82  0.22];
    ax2.Position = [0.10  0.40  0.82  0.22];
    ax3.Position = [0.10  0.07  0.82  0.25];
end