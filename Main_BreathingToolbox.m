%% Artigo Breathing Toolbox
%% 1. Abrir .c3d
dados = ler_c3d_sem_toolbox('S4_CHLE_QB_M_T3_B.c3d');
%% 2. PRIMEIRO CHECK -> Posição dos marcadores
checkup_labels_c3d('S4_CHLE_QB_M_T3_B.c3d');
%% 3. Pré-processamento do sinal 
fs = dados.freq_hz;
max_gap_s = 0.1; % em segundos 
% CHECK UP DO RELATÓRIO - OPCIONAL
resultado = preProcessNaN(fs, max_gap_s);
%% 4. Filtragem do sinal 
% OPÇÃO DEFAULT 
[dados_filt, relatorio] = filtrarSinal(dados);               % OPÇÃO DEFAULT
%[dados_filt, relatorio] = filtrarSinal(dados, 'usuario', fc) % OPÇÃO MANUAL

%% 5. Cálculo do volume 
% Reshape: [n_frames × 3 × 32] → [n_frames × 96]
mat = [dados.tempo,reshape(dados_filt.marcadores, [], size(dados_filt.marcadores,3)*3)];
[~, volumes] = volume_32(mat, mat(:,1));
%Plot do volume
%volumes
VT_curve = volumes(:,1)/1000; %Transformar de ml para L 
ST_curve = volumes(:,2)/1000;
IT_curve = volumes(:,3)/1000;
AB_curve = volumes(:,4)/1000;
plotVolumes(dados.tempo, VT_curve, ST_curve, IT_curve, AB_curve);
%% 6. Corte do ciclos respiratórios
% Normalmente não considera o primeiro ciclo - por precaução
[ST, IT, AB, VT, ST_s, IT_s, AB_s, VT_s, locs] = crop_cycles(ST_curve, IT_curve, AB_curve, VT_curve, fs);
%% 7. Coordenação 
STm = mean(ST,2); 
ITm = mean(IT,2); 
ABm = mean(AB,2);
phase_angle = coord_phase_angle(STm, ITm, ABm)

%% 8. Variáveis relativas ao volume 
[Volamp_TOT, Contribution, RC_percent] = volume_variables(ST, IT, AB);

%% 9. Variáveis temporais
[Tempo_resp, Tempo_insp, Duty_cicle, Difftime, Phaseshift] = time_variables(ST_s, IT_s, AB_s, VT_s, fs);