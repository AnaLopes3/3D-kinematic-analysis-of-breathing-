function plotVolumes(t, VT, ST_curve, IT_curve, AB_curve)

    figure('Name', 'volume_32 – Volumes Compartimentais', ...
           'NumberTitle', 'off', ...
           'Position', [80 80 960 720]);

    cores = {[0.1  0.1  0.1 ], ...   % VT       — preto
             [0.0  0.45 0.74], ...   % Tórax sup — azul
             [0.85 0.33 0.10], ...   % Tórax inf — laranja
             [0.47 0.67 0.19]};      % Abdômen   — verde

    curvas     = {VT,       ST_curve,      IT_curve,      AB_curve};
    nomes      = {'VT total', 'Tórax superior', 'Tórax inferior', 'Abdômen'};
    posicoes   = [1 2 3 4];

    %% Painel 1 — VT total sozinho
    ax1 = subplot(4, 1, 1);
    plot(ax1, t, VT, 'Color', cores{1}, 'LineWidth', 1.5);
    ylabel(ax1, 'Volume (L)');
    title(ax1, 'Volume Total (VT)');
    grid(ax1, 'on');
    ax1.XTickLabel = {};

    %% Painéis 2–4 — compartimentos individuais
    labels_y = {'Tórax sup (L)', 'Tórax inf (L)', 'Abdômen (L)'};
    ax_prev  = ax1;

    for k = 2:4
        ax = subplot(4, 1, posicoes(k));
        plot(ax, t, curvas{k}, 'Color', cores{k}, 'LineWidth', 1.5);
        ylabel(ax, labels_y{k-1});
        title(ax, nomes{k});
        grid(ax, 'on');
        linkaxes([ax_prev ax], 'x');
        ax_prev = ax;
        if k < 4
            ax.XTickLabel = {};
        end
    end

    xlabel(ax_prev, 'Tempo (s)');

    %% Título geral
    sgtitle('Volumes Compartimentais – Modelo 32 marcadores', ...
            'FontWeight', 'bold', 'FontSize', 12);

    %% Ajuste de espaçamento
    all_ax = findobj(gcf, 'Type', 'axes');
    all_ax = flipud(all_ax);   % ordem top→bottom
    tops    = [0.75, 0.52, 0.29, 0.06];
    for k = 1:4
        all_ax(k).Position = [0.10, tops(k), 0.82, 0.17];
    end
end
