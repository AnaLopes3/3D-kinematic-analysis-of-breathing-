function dados = ler_c3d_sem_toolbox(caminho)
% LER ARQUIVO C3D SEM TOOLBOX EXTERNO
%
% USO:
%   dados = ler_c3d_sem_toolbox('S5_MOSI_QB_B_T1_B.c3d');
%
% SAÍDA (struct):
%   .marcadores   — double [n_frames × 3 × n_marcadores]  (mm)
%   .residuos     — double [n_frames × n_marcadores]
%   .labels       — cell array com nomes dos marcadores
%   .tempo        — vetor coluna em segundos
%   .freq_hz      — taxa de captura (Hz)
%   .n_frames     — número de frames
%   .n_marcadores — número de marcadores
%
% Testado em:  S5_MOSI_QB_B_T1_B.c3d
%   32 marcadores | 3147 frames | 100 Hz | formato float32 Intel (little-endian)
%
% Compatível com qualquer arquivo C3D float32 little-endian (padrão moderno).
% -------------------------------------------------------------------------

if nargin < 1
    caminho = 'S5_MOSI_QB_B_T1_B.c3d';
end

% =========================================================
% 1.  ABRIR ARQUIVO (little-endian = processadores Intel)
% =========================================================
fid = fopen(caminho, 'rb', 'l');
if fid == -1
    error('Não foi possível abrir: %s', caminho);
end

% =========================================================
% 2.  LER HEADER  (primeiro bloco de 512 bytes, bytes 1-24)
% =========================================================
param_block  = fread(fid, 1, 'uint8');   % byte 1 — bloco de parâmetros
key          = fread(fid, 1, 'uint8');   % byte 2 — deve ser 80 (0x50)

if key ~= 80
    fclose(fid);
    error('Arquivo inválido (byte 2 = %d; esperado 80).', key);
end

n_pontos        = fread(fid, 1, 'uint16');  % bytes 3-4
analog_frame    = fread(fid, 1, 'uint16');  % bytes 5-6  (analógicos/frame)
primeiro_frame  = fread(fid, 1, 'uint16');  % bytes 7-8  (índice 1-based)
ultimo_frame    = fread(fid, 1, 'uint16');  % bytes 9-10
max_gap         = fread(fid, 1, 'uint16');  % bytes 11-12 (não usado)
scale           = fread(fid, 1, 'float32'); % bytes 13-16 (negativo = float32)
data_block      = fread(fid, 1, 'uint16');  % bytes 17-18 — bloco de dados
n_analogicos    = fread(fid, 1, 'uint16');  % bytes 19-20
freq_hz         = fread(fid, 1, 'float32'); % bytes 21-24

eh_float = (scale < 0);   % escala negativa → dados em float32
n_frames = ultimo_frame - primeiro_frame + 1;

fprintf('=== ARQUIVO: %s ===\n', caminho);
fprintf('  Marcadores   : %d\n',  n_pontos);
fprintf('  Frames       : %d  (%d → %d)\n', n_frames, primeiro_frame, ultimo_frame);
fprintf('  Taxa          : %.1f Hz\n', freq_hz);
fprintf('  Duração       : %.2f s\n',  n_frames / freq_hz);
fprintf('  Escala        : %.4f  (%s)\n', scale, iif(eh_float,'float32','int16'));
fprintf('  Bloco dados   : %d  (offset %d bytes)\n', data_block, (data_block-1)*512);
fprintf('  Analógicos    : %d canais\n', n_analogicos);

% =========================================================
% 3.  LER NOMES DOS MARCADORES (bloco de parâmetros)
% =========================================================
labels = ler_labels(fid, param_block, n_pontos);

fprintf('  Labels        : %d lidos\n', numel(labels));
if ~isempty(labels)
    fprintf('  Primeiros 5   :');
    for k = 1:min(5, numel(labels))
        fprintf(' [%s]', labels{k});
    end
    fprintf('\n');
end

% =========================================================
% 4.  LER DADOS 3D
% =========================================================
data_offset = (data_block - 1) * 512;
fseek(fid, data_offset, 'bof');

marcadores = NaN(n_frames, 3, n_pontos);   % X Y Z em mm
residuos   = NaN(n_frames, n_pontos);

fprintf('\nLendo dados (%d frames × %d marcadores)...\n', n_frames, n_pontos);

for fr = 1:n_frames
    for pt = 1:n_pontos
        if eh_float
            vals = fread(fid, 4, 'float32');   % X Y Z residual
        else
            raw  = fread(fid, 4, 'int16');
            vals = double(raw) * abs(scale);
            vals(4) = raw(4);   % residual não é escalado
        end
        if numel(vals) < 4, break; end

        marcadores(fr, 1, pt) = vals(1);
        marcadores(fr, 2, pt) = vals(2);
        marcadores(fr, 3, pt) = vals(3);
        residuos(fr,   pt)    = vals(4);
    end

    % Pular canais analógicos deste frame (se houver)
    if n_analogicos > 0
        fseek(fid, n_analogicos * 2, 'cof');
    end
end

fclose(fid);
fprintf('Concluído.\n\n');

% =========================================================
% 5.  SAÍDA
% =========================================================
tempo = (0 : n_frames-1)' / freq_hz;

dados.marcadores    = marcadores;
dados.residuos      = residuos;
dados.labels        = labels;
dados.tempo         = tempo;
dados.freq_hz       = freq_hz;
dados.n_frames      = n_frames;
dados.n_marcadores  = n_pontos;

% =========================================================
% 6.  COMO ACESSAR OS DADOS
% =========================================================
fprintf('=== EXEMPLOS DE ACESSO ===\n');
fprintf('  Todos X do marcador 1     : dados.marcadores(:, 1, 1)\n');
fprintf('  Y do marcador 5, frame 10 : dados.marcadores(10, 2, 5)\n');
fprintf('  Todos frames de Resp:17   : dados.marcadores(:, :, 1)\n');

% =========================================================
% 7.  PLOTAR TRAJETÓRIA DO MARCADOR 1
% =========================================================
if n_frames > 0 && n_pontos > 0
    lbl = '';
    if ~isempty(labels), lbl = labels{1}; end

    figure('Name', ['Trajetória – ' lbl], 'NumberTitle', 'off');
    eixos  = {'X','Y','Z'};
    cores  = {'b','r','g'};
    for ax = 1:3
        subplot(3,1,ax);
        plot(dados.tempo, dados.marcadores(:, ax, 1), cores{ax}, 'LineWidth', 1.2);
        ylabel([eixos{ax} ' (mm)']);
        if ax == 1, title(['Marcador: ' lbl]); end
        if ax == 3, xlabel('Tempo (s)'); end
        grid on;
    end
end

% =========================================================
% 8.  SALVAR .MAT  (descomente se quiser)
% =========================================================
% save('dados_c3d.mat', '-struct', 'dados');
% fprintf('Dados salvos em dados_c3d.mat\n');

end  % fim da função principal


% =========================================================
%  FUNÇÃO AUXILIAR — ler labels do bloco de parâmetros
%  Usa busca direta por 'LABELS' no buffer (robusto a variações de C3D)
% =========================================================
function labels = ler_labels(fid, param_block, n_pontos)
% Busca direta pela string 'LABELS' no bloco de parâmetros.
% Mais robusto que o parser hierárquico, que falha em alguns arquivos.

labels = {};

try
    % Ler todo o bloco de parâmetros de uma vez
    fseek(fid, (param_block - 1) * 512, 'bof');
    fread(fid, 1, 'uint8');   % reservado
    fread(fid, 1, 'uint8');   % chave
    n_blocos = fread(fid, 1, 'uint8');
    fread(fid, 1, 'uint8');   % processador
    
    n_bytes = n_blocos * 512 - 4;
    buf = fread(fid, n_bytes, 'uint8')';  % vetor linha, indexação 1-based

    % --- Busca direta pela sequência "LABELS" no buffer ---
    % Procura o byte nl=6 (comprimento de "LABELS") seguido de
    % gid > 0 (é parâmetro) seguido de "LABELS"
    alvo = uint8('LABELS');
    pos = [];
    
    for i = 1 : numel(buf) - 7
        if buf(i) == 6 && buf(i+1) > 0 && ...
           isequal(buf(i+2 : i+7), alvo)
            pos = i;
            break;
        end
    end

    if isempty(pos)
        % Fallback: tentar só pela string "LABELS" sem verificar nl/gid
        for i = 1 : numel(buf) - 5
            if isequal(buf(i : i+5), alvo)
                pos = i - 2;  % recuar para nl e gid
                if pos < 1, pos = 1; end
                break;
            end
        end
    end

    if isempty(pos)
        warning('ler_labels: parametro LABELS nao encontrado no bloco de parametros.');
        labels = {};
    else
        % Posição após o nome "LABELS" (6 chars)
        p = pos + 2 + 6;   % pular nl(1) + gid(1) + nome(6)

        % next_off (int16, 2 bytes) — não usamos o valor, só avançamos
        p = p + 2;

        % data_type (int8) e n_dims (uint8)
        % data_type = -1 para char
        p = p + 1;          % pular data_type
        n_dims = buf(p);
        p = p + 1;

        if n_dims < 2
            warning('ler_labels: LABELS com n_dims=%d (esperado >=2).', n_dims);
            labels = {};
        else
            % Ler dimensões
            dims = double(buf(p : p + n_dims - 1));
            p = p + n_dims;

            str_len  = dims(1);   % comprimento de cada label (em chars)
            n_labels = dims(2);   % número de labels

            % Ler os labels
            labels = cell(1, n_labels);
            for k = 1 : n_labels
                if p + str_len - 1 <= numel(buf)
                    labels{k} = strtrim(char(buf(p : p + str_len - 1)));
                    p = p + str_len;
                else
                    labels{k} = sprintf('Marker_%02d', k);
                end
            end
        end
    end

catch err
    warning('ler_labels: erro durante leitura — %s', err.message);
    labels = {};
end

% Fallback final
if isempty(labels)
    labels = arrayfun(@(i) sprintf('Marker_%02d', i), 1:n_pontos, ...
                      'UniformOutput', false);
end
end


% =========================================================
%  Helper: ternário simples
% =========================================================
function v = iif(cond, a, b)
    if cond, v = a; else, v = b; end
end
