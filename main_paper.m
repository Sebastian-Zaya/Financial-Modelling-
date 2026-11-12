clc
clear
addpath(genpath(pwd))

%% Setting
P = 1; % Lag of Y
Q = 1; % Lag of Z
Y_index = 1; % Target_Depreciation is column 1 in Data_Sweden.xlsx numeric matrix
is_Report = 1; % Set to 1 to generate figures for the final report
OSS = 36; % 3-year (36 months) out-of-sample evaluation period

%% Data Loading
Data_full = readmatrix('Data_Sweden.xlsx', 'Range', 'B2:J345');
Variable_Names = readcell('Data_Sweden.xlsx', 'Range', 'B1:J1');
Variable_Names = ['Const', Variable_Names];

%% Prior Settings (Tuning Parameters)
a0 = 5; c0 = 10;
b0 = 0.001; b1 = 25;
alpha0 = 5; delta0 = 5;

%% Evaluation over multiple horizons (3, 12, 24 months)
Horizons = [3, 12, 24];
for h_idx = 1:length(Horizons)
    H = Horizons(h_idx);
    disp('==================================================')
    disp(['Forecasting Horizon H = ', num2str(H), ' months'])
    disp('==================================================')

    T_in0 = size(Data_full, 1) - OSS - H + 1;
    OSm = Data_full(end - OSS + 1 : end, Y_index);
    Pred_errorm = zeros(OSS, 1);
    Pred_errorm_AR = zeros(OSS, 1);

    for ind_OSF = 1:OSS
        T_in = T_in0 + ind_OSF - 1;
        Data_in_sample = Data_full(1:T_in, :);

        % BVS Model
        [~, ~, yfm] = ...
            ADL_BVS3(Data_in_sample, P, Q, H, a0, c0, b0, b1, alpha0, delta0, Y_index, 0);

        % AR Benchmark Model
        [~, ~, yfm_AR] = AR_Bayes(Data_in_sample, 1, H, a0, c0, b0, b1, alpha0, delta0, Y_index, 0);

        forecast = mean(yfm);
        forecast_AR = mean(yfm_AR);
        realized_value = OSm(ind_OSF);

        Pred_errorm(ind_OSF) = realized_value - forecast;
        Pred_errorm_AR(ind_OSF) = realized_value - forecast_AR;
    end

    RMSE = sqrt(Pred_errorm'*Pred_errorm/OSS);
    RMSE_AR = sqrt(Pred_errorm_AR'*Pred_errorm_AR/OSS);

    disp(['RMSE (ADL-BVS) : ', num2str(RMSE)])
    disp(['RMSE (AR)      : ', num2str(RMSE_AR)])

    % Run one final time on full sample to get Prob_Importance and Plots for the report
    disp('--- Full Sample Estimation for Figures ---')
    [betam, Prob_Importance, yfm] = ADL_BVS3(Data_full, P, Q, H, a0, c0, b0, b1, alpha0, delta0, Y_index, is_Report);

    disp('Important Predictors (PIP > 0.5):')
    for i = 1:length(Prob_Importance)
        if Prob_Importance(i) > 0.5
            disp([Variable_Names{i}, ': ', num2str(Prob_Importance(i))])
        end
    end
end