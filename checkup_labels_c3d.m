function checkup_labels_c3d(caminho)
% CHECKUP_LABELS_C3D  —  Verifica e visualiza os labels de marcadores de um .c3d
%
% Usa ler_c3d_sem_toolbox.m (sem necessidade do BTK).
%
% USO:
%   checkup_labels_c3d()                   % abre seletor de arquivo
%   checkup_labels_c3d('arquivo.c3d')
%
% LABELS ACEITOS (qualquer formato que contenha o número 1–32):
%   "1"  "32"  "Resp1"  "Resp_32"  "Resp:1"  "Resp_:1"
%   "TRUNK:5"  "marker_17"  "M.22"  "P 9"  ...

% 0. SELECIONAR ARQUIVO

if nargin < 1 || isempty(caminho)
    [arq, pasta] = uigetfile('*.c3d', 'Selecione o arquivo .c3d');
    if isequal(arq, 0), disp('Operacao cancelada.'); return; end
    caminho = fullfile(pasta, arq);
end


% 1. LER C3D

if exist('ler_c3d_sem_toolbox', 'file') ~= 2
    error('ler_c3d_sem_toolbox.m nao encontrada no path MATLAB.');
end

dados      = ler_c3d_sem_toolbox(caminho);
labels_raw = dados.labels;
coords     = dados.marcadores;   % [n_frames x 3 x n_marcadores] — ordem fisica
freq_hz    = dados.freq_hz;
n_lidos    = dados.n_marcadores;

% 2. EXTRAIR NÚMERO DE CADA LABEL (último número no string)

num_extraido = zeros(1, n_lidos);
for i = 1:n_lidos
    tokens = regexp(labels_raw{i}, '\d+', 'match');
    if ~isempty(tokens)
        num_extraido(i) = str2double(tokens{end});
    end
end

% 3. MAPEAMENTO: número anatômico 1–32 → índice físico no arquivo

idx_por_num = zeros(1, 32);
duplicatas  = {};

for i = 1:n_lidos
    n = num_extraido(i);
    if n < 1 || n > 32, continue; end
    if idx_por_num(n) == 0
        idx_por_num(n) = i;
    else
        duplicatas{end+1} = sprintf('Numero %d: "%s" (pos %d) e "%s" (pos %d)', ...
            n, labels_raw{idx_por_num(n)}, idx_por_num(n), labels_raw{i}, i); %#ok<AGROW>
    end
end

% 4. DIAGNÓSTICO NO TERMINAL
n_ok      = sum(idx_por_num > 0);
n_ausente = 32 - n_ok;
n_dup     = numel(duplicatas);

fprintf('\n%s\n', repmat('=', 1, 65));
fprintf('CHECKUP DE LABELS — %s\n', nome_curto(caminho));
fprintf('Marcadores no arquivo : %d   |   Esperados : 32\n', n_lidos);
fprintf('Taxa de captura       : %.1f Hz\n', freq_hz);
fprintf('%s\n\n', repmat('=', 1, 65));

fprintf('%-5s  %-22s  %-8s  %s\n', 'NUM', 'LABEL NO ARQUIVO', 'POS C3D', 'STATUS');
fprintf('%s\n', repmat('-', 1, 55));

for n = 1:32
    idx = idx_por_num(n);
    if idx > 0
        fprintf('%-5d  %-22s  %-8d  OK\n', n, labels_raw{idx}, idx);
    else
        fprintf('%-5d  %-22s  %-8s  AUSENTE\n', n, '---', '---');
    end
end

fprintf('\n%s\n', repmat('-', 1, 55));
fprintf('RESUMO: %d OK  |  %d Ausentes  |  %d Duplicatas\n', n_ok, n_ausente, n_dup);

if ~isempty(duplicatas)
    fprintf('\nDUPLICATAS:\n');
    for k = 1:numel(duplicatas), fprintf('  [!] %s\n', duplicatas{k}); end
end

sem_numero = find(num_extraido == 0 | num_extraido > 32);
if ~isempty(sem_numero)
    fprintf('\nMARCADORES SEM NUMERO VALIDO (ignorados):\n');
    for k = 1:numel(sem_numero)
        fprintf('  [?] pos %2d: "%s"\n', sem_numero(k), labels_raw{sem_numero(k)});
    end
end

fprintf('%s\n\n', repmat('=', 1, 65));
if n_ausente == 0 && n_dup == 0
    fprintf('[OK] Todos os 32 marcadores identificados.\n\n');
else
    fprintf('[ATENCAO] Corrija os labels antes de executar a função de volume.\n\n');
end

% 5. POSIÇÃO MÉDIA (frame médio)
%    pos_med(n,:) = posição do marcador anatômico n
%    USA idx_por_num para buscar o índice físico correto no arquivo

pos_med = NaN(32, 3);
for n = 1:32
    if idx_por_num(n) > 0
        pos_med(n, :) = mean(coords(:, :, idx_por_num(n)), 1);
    end
end


% 6. MODELO DE CONECTIVIDADE (idêntico ao volume_32.m)

model_idx = [
     1  5 21 17  2  6 22 18;   % RCp hex1
     5  9 25 21  6 10 26 22;   % RCp hex2
     9 13 29 25 10 14 30 26;   % RCp hex3
     2  6 22 18  3  7 23 19;   % RCa hex1
     6 10 26 22  7 11 27 23;   % RCa hex2
    10 14 30 26 11 15 31 27;   % RCa hex3
     3  7 23 19  4  8 24 20;   % AB  hex1
     7 11 27 23  8 12 28 24;   % AB  hex2
    11 15 31 27 12 16 32 28];  % AB  hex3


% 7. REGIÕES POR LINHA ANATÔMICA
regiao = zeros(1, 32);
regiao([1  5  9 13 17 21 25 29]) = 1;   % linha 1 — RCp
regiao([2  6 10 14 18 22 26 30]) = 1;   % linha 2 — RCp
regiao([3  7 11 15 19 23 27 31]) = 2;   % linha 3 — RCa
regiao([4  8 12 16 20 24 28 32]) = 3;   % linha 4 — AB

cor_reg = [0.18 0.44 0.71;   % RCp — azul
           0.20 0.63 0.17;   % RCa — verde
           0.84 0.15 0.15];  % AB  — vermelho

% 12 arestas únicas do hexaedro
arestas_hex = [1 2; 2 3; 3 4; 4 1;   % anel superior
               5 6; 6 7; 7 8; 8 5;   % anel inferior
               1 5; 2 6; 3 7; 4 8];  % verticais

% 8. FIGURA — 3 painéis: Vista 3D | Frontal (X-Z) | Lateral (Y-Z)


figure('Name', 'Checkup Labels', 'NumberTitle', 'off', ...
       'Color', [0.96 0.96 0.98], 'Position', [40 60 1300 520]);

% Painel 1: Vista 3D
ax1 = subplot(1, 3, 1);
hold(ax1,'on'); grid(ax1,'on'); box(ax1,'on');
ax1.Color = [0.97 0.97 0.99];

for m = 1:9
    verts = pos_med(model_idx(m,:), :);
    if any(isnan(verts(:))), continue; end
    if m<=3, cor=cor_reg(1,:); elseif m<=6, cor=cor_reg(2,:); else, cor=cor_reg(3,:); end
    for a = 1:12
        i1 = arestas_hex(a,1); i2 = arestas_hex(a,2);
        plot3(ax1, verts([i1 i2],1), verts([i1 i2],2), verts([i1 i2],3), ...
              '-', 'Color', cor, 'LineWidth', 1.5);
    end
end

for n = 1:32
    if any(isnan(pos_med(n,:))), continue; end
    r = regiao(n); if r==0, r=1; end
    cor = cor_reg(r,:);
    if n <= 16
        sym = 'o';   % frente — círculo
    else
        sym = 's';   % costas — quadrado
    end
    if idx_por_num(n) == 0
        plot3(ax1, pos_med(n,1), pos_med(n,2), pos_med(n,3), ...
            'x', 'Color', [.5 .5 .5], 'MarkerSize', 10, 'LineWidth', 2);
        text(ax1, pos_med(n,1), pos_med(n,2), pos_med(n,3), ...
            sprintf('  %d?',n), 'FontSize', 7, 'Color', [.4 .4 .4]);
    else
        plot3(ax1, pos_med(n,1), pos_med(n,2), pos_med(n,3), ...
            sym, 'Color', cor, 'MarkerFaceColor', cor, 'MarkerSize', 6);
        text(ax1, pos_med(n,1), pos_med(n,2), pos_med(n,3), ...
            sprintf('  %d', n), 'FontSize', 7, 'Color', cor*0.65, 'FontWeight', 'bold');
    end
end

xlabel(ax1,'X'); ylabel(ax1,'Y'); zlabel(ax1,'Z');
title(ax1, 'Vista 3D', 'FontSize', 9, 'FontWeight', 'bold');
axis(ax1, 'equal');
view(ax1, [-30, 20]);   

h(1) = plot3(ax1,NaN,NaN,NaN,'-o','Color',cor_reg(1,:),'MarkerFaceColor',cor_reg(1,:),'DisplayName','RCp');
h(2) = plot3(ax1,NaN,NaN,NaN,'-o','Color',cor_reg(2,:),'MarkerFaceColor',cor_reg(2,:),'DisplayName','RCa');
h(3) = plot3(ax1,NaN,NaN,NaN,'-o','Color',cor_reg(3,:),'MarkerFaceColor',cor_reg(3,:),'DisplayName','AB');
h(4) = plot3(ax1,NaN,NaN,NaN,'o','Color',[.4 .4 .4],'MarkerFaceColor',[.4 .4 .4],'MarkerSize',5,'DisplayName','Frente (1-16)');
h(5) = plot3(ax1,NaN,NaN,NaN,'s','Color',[.4 .4 .4],'MarkerFaceColor',[.4 .4 .4],'MarkerSize',5,'DisplayName','Costas (17-32)');
legend(ax1, h, 'Location', 'best', 'FontSize', 7);

% Painel 2: Frontal X vs Z
ax2 = subplot(1, 3, 2);
hold(ax2,'on'); grid(ax2,'on'); box(ax2,'on');
ax2.Color = [0.97 0.97 0.99];
title(ax2, 'Vista Frontal (X–Z)', 'FontSize', 9, 'FontWeight', 'bold');
xlabel(ax2, 'X'); ylabel(ax2, 'Z');

for m = 1:9
    verts = pos_med(model_idx(m,:), :);
    if any(isnan(verts(:))), continue; end
    if m<=3, cor=cor_reg(1,:); elseif m<=6, cor=cor_reg(2,:); else, cor=cor_reg(3,:); end
    for a = 1:12
        i1 = arestas_hex(a,1); i2 = arestas_hex(a,2);
        plot(ax2, verts([i1 i2],1), verts([i1 i2],3), '-', 'Color', cor, 'LineWidth', 1.2);
    end
end

for n = 1:32
    if any(isnan(pos_med(n,:))), continue; end
    r = regiao(n); if r==0, r=1; end
    cor = cor_reg(r,:);
    if idx_por_num(n) == 0
        plot(ax2, pos_med(n,1), pos_med(n,3), 'x', 'Color', [.5 .5 .5], 'MarkerSize', 9, 'LineWidth', 2);
        text(ax2, pos_med(n,1), pos_med(n,3), sprintf('  %d?',n), 'FontSize', 7, 'Color', [.4 .4 .4]);
    else
        plot(ax2, pos_med(n,1), pos_med(n,3), 'o', 'Color', cor, 'MarkerFaceColor', cor, 'MarkerSize', 6);
        text(ax2, pos_med(n,1), pos_med(n,3), sprintf('  %d',n), 'FontSize', 7, 'Color', cor*0.65, 'FontWeight', 'bold');
    end
end

axis(ax2, 'equal');

% Painel 3: Lateral Y vs Z
ax3 = subplot(1, 3, 3);
hold(ax3,'on'); grid(ax3,'on'); box(ax3,'on');
ax3.Color = [0.97 0.97 0.99];
title(ax3, 'Vista Lateral (Y–Z)', 'FontSize', 9, 'FontWeight', 'bold');
xlabel(ax3, 'Y'); ylabel(ax3, 'Z');

for m = 1:9
    verts = pos_med(model_idx(m,:), :);
    if any(isnan(verts(:))), continue; end
    if m<=3, cor=cor_reg(1,:); elseif m<=6, cor=cor_reg(2,:); else, cor=cor_reg(3,:); end
    for a = 1:12
        i1 = arestas_hex(a,1); i2 = arestas_hex(a,2);
        plot(ax3, verts([i1 i2],2), verts([i1 i2],3), '-', 'Color', cor, 'LineWidth', 1.2);
    end
end

for n = 1:32
    if any(isnan(pos_med(n,:))), continue; end
    r = regiao(n); if r==0, r=1; end
    cor = cor_reg(r,:);
    if idx_por_num(n) == 0
        plot(ax3, pos_med(n,2), pos_med(n,3), 'x', 'Color', [.5 .5 .5], 'MarkerSize', 9, 'LineWidth', 2);
        text(ax3, pos_med(n,2), pos_med(n,3), sprintf('  %d?',n), 'FontSize', 7, 'Color', [.4 .4 .4]);
    else
        plot(ax3, pos_med(n,2), pos_med(n,3), 'o', 'Color', cor, 'MarkerFaceColor', cor, 'MarkerSize', 6);
        text(ax3, pos_med(n,2), pos_med(n,3), sprintf('  %d',n), 'FontSize', 7, 'Color', cor*0.65, 'FontWeight', 'bold');
    end
end

axis(ax3, 'equal');

sgtitle(sprintf('Checkup Labels — %s   (%d frames @ %.0f Hz)', ...
    nome_curto(caminho), size(coords,1), freq_hz), ...
    'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'none');

end  % fim da função principal

function s = nome_curto(caminho)
    [~, n, ext] = fileparts(caminho);
    s = [n ext];
end
