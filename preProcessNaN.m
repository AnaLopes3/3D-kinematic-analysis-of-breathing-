function relatorio = preProcessNaN(fs, max_gap_s)
% preProcessNaN  Detecta NaN, interpola gaps aceitáveis e gera relatório.
%
%   relatorio = preProcessNaN(fs)
%       Usa fs (Hz) e ponto de corte padrão de 0.1 s.
%
%   relatorio = preProcessNaN(fs, max_gap_s)
%       Define ponto de corte em segundos (ex: 0.2).
%
%   Parâmetros:
%       fs          – frequência de amostragem em Hz
%       max_gap_s   – tamanho máximo do gap interpolável em SEGUNDOS
%                     (padrão: 0.1 s → 10 frames a 100 Hz)
%
%   Saída (struct array):
%       .nome            – nome da variável
%       .gaps            – struct com info de cada gap (inicio, fim, tamanho, acao)
%       .n_interpolados  – total de pontos interpolados
%       .n_excedidos     – gaps que excederam o limite (não interpolados)
%       .status          – 'interpolado', 'excedido' ou 'misto'

    %% Argumentos e defaults
    if nargin < 1, error('Informe a frequência de amostragem fs.'); end
    if nargin < 2 || isempty(max_gap_s), max_gap_s = 0.1; end

    max_gap_frames = round(max_gap_s * fs);

    if max_gap_s > 0.3
        warning(['max_gap_s = %.2f s é maior que 0.3 s. ' ...
                 'Interpolações longas podem introduzir erro significativo.'], max_gap_s);
    end

    %% Varrer TODAS as variáveis numéricas do workspace
    variaveis = evalin('base', 'who');
    relatorio = struct('nome',{}, 'gaps',{}, 'n_interpolados',{}, ...
                       'n_excedidos',{}, 'status',{});

    fprintf('\n========= Pré-processamento NaN =========\n');
    fprintf('  fs           : %.1f Hz\n', fs);
    fprintf('  Limite gap   : %.2f s  (%d frames)\n', max_gap_s, max_gap_frames);
    fprintf('-----------------------------------------\n');

    for i = 1:numel(variaveis)
        nomeVar = variaveis{i};
        valor   = evalin('base', nomeVar);

        % Ignora não-numéricos, não-vetores e variáveis sem NaN
        if ~isnumeric(valor) || ~isvector(valor), continue; end
        valor = valor(:);
        if ~any(isnan(valor)),                    continue; end

        %% Identificar gaps consecutivos
        gaps = identificarGaps(find(isnan(valor)));

        n_interp   = 0;
        n_excedido = 0;
        valorNovo  = valor;

        for g = 1:numel(gaps)
            if gaps(g).tamanho <= max_gap_frames
                antes  = gaps(g).inicio - 1;
                depois = gaps(g).fim    + 1;

                if antes >= 1 && depois <= numel(valor) && ...
                   ~isnan(valor(antes)) && ~isnan(valor(depois))

                    x_known  = [antes; depois];
                    y_known  = [valor(antes); valor(depois)];
                    x_interp = (gaps(g).inicio : gaps(g).fim)';
                    valorNovo(x_interp) = interp1(x_known, y_known, x_interp, 'pchip');
                    n_interp            = n_interp + gaps(g).tamanho;
                    gaps(g).acao        = 'interpolado';
                else
                    gaps(g).acao = 'sem_vizinhos';
                    n_excedido   = n_excedido + 1;
                end
            else
                gaps(g).acao = 'excedido';
                n_excedido   = n_excedido + 1;
            end
        end

        if n_interp > 0
            assignin('base', nomeVar, valorNovo);
        end

        if     n_excedido == 0, st = 'interpolado';
        elseif n_interp   == 0, st = 'excedido';
        else,                   st = 'misto';
        end

        entrada.nome           = nomeVar;
        entrada.gaps           = gaps;
        entrada.n_interpolados = n_interp;
        entrada.n_excedidos    = n_excedido;
        entrada.status         = st;
        relatorio(end+1)       = entrada; %#ok<AGROW>

        fprintf('  [%s] %s\n', upper(st), nomeVar);
        for g = 1:numel(gaps)
            fprintf('      Gap %d: frames %d–%d  (%d frames = %.3f s)  → %s\n', ...
                g, gaps(g).inicio, gaps(g).fim, gaps(g).tamanho, ...
                gaps(g).tamanho / fs, gaps(g).acao);
        end
    end

    %% Resumo
    if isempty(relatorio)
        fprintf('  Nenhum NaN encontrado.\n');
    else
        n_i = sum(strcmp({relatorio.status}, 'interpolado'));
        n_e = sum(strcmp({relatorio.status}, 'excedido')) + ...
              sum(strcmp({relatorio.status}, 'misto'));
        fprintf('-----------------------------------------\n');
        fprintf('  Variáveis com NaN     : %d\n', numel(relatorio));
        fprintf('  Totalmente interpoladas: %d\n', n_i);
        fprintf('  Com gaps excedidos    : %d\n', n_e);
        if n_e > 0
            fprintf('\n  *** ATENÇÃO: variáveis com gaps longos demais.\n');
            fprintf('      Verifique antes de prosseguir com o cálculo de volume.\n');
        end
    end
    fprintf('=========================================\n\n');
end

%% Helper – blocos consecutivos de NaN
function gaps = identificarGaps(idxNaN)
    gaps   = struct('inicio',{}, 'fim',{}, 'tamanho',{}, 'acao',{});
    breaks = [0; find(diff(idxNaN) > 1); numel(idxNaN)];
    for k  = 1:numel(breaks)-1
        ini            = idxNaN(breaks(k)+1);
        fim            = idxNaN(breaks(k+1));
        gaps(end+1).inicio  = ini;   %#ok<AGROW>
        gaps(end).fim       = fim;
        gaps(end).tamanho   = fim - ini + 1;
        gaps(end).acao      = 'pendente';
    end
end