% main_gpa.m
% Runner script for the GPAAnalyzer class.
% Supports multiple semesters with trend plotting.
%
% Requirements: GPAAnalyzer.m must be in the same folder (or on MATLAB path)
%
% Run: >> main_gpa

clc; clear; close all;

fprintf('╔══════════════════════════════════════════╗\n');
fprintf('║   COLLEGE GPA & PERFORMANCE ANALYZER     ║\n');
fprintf('║   Powered by GPAAnalyzer class            ║\n');
fprintf('╚══════════════════════════════════════════╝\n\n');

semGPAs  = [];          % stores GPA of each semester entered
semNames = {};          % stores name of each semester entered

while true

    %% --- Semester name ---
    semName = strtrim(input('Enter semester name (e.g., Sem 1 / 2024-Odd): ', 's'));
    if isempty(semName)
        semName = sprintf('Semester %d', numel(semGPAs)+1);
    end

    %% --- Create, populate and compute ---
    analyzer = GPAAnalyzer(semName);
    analyzer = analyzer.inputData();
    analyzer = analyzer.calculate();

    %% --- Display results ---
    analyzer.displayResults();

    %% --- Visualise ---
    analyzer.plotCharts();

    %% --- Save to disk (.txt and .csv) ---
    analyzer.saveResults();

    %% --- Accumulate for trend ---
    semGPAs(end+1)  = analyzer.GPA;       %#ok<AGROW>
    semNames{end+1} = char(semName);      %#ok<AGROW>

    %% --- Multi-semester trend (only when ≥ 2 semesters recorded) ---
    if numel(semGPAs) >= 2
        GPAAnalyzer.plotTrend(semNames, semGPAs);
    end

    %% --- Continue? ---
    fprintf('\n');
    again = lower(strtrim(input('Add another semester? (y / n): ', 's')));
    if ~strcmp(again, 'y')
        break;
    end
    fprintf('\n');
end

%% Final trend summary across all semesters
fprintf('\n========================================\n');
fprintf(' OVERALL SUMMARY\n');
fprintf('========================================\n');
for k = 1:numel(semGPAs)
    fprintf('  %-20s  GPA = %.2f  (%s)\n', semNames{k}, semGPAs(k), ...
        char(GPAAnalyzer.classifyPerformance(semGPAs(k))));
end
if numel(semGPAs) > 1
    fprintf('\n  Cumulative GPA : %.2f\n', mean(semGPAs));
    [best, bk] = max(semGPAs);
    [wrst, wk] = min(semGPAs);
    fprintf('  Best Semester  : %s  (%.2f)\n', semNames{bk}, best);
    fprintf('  Worst Semester : %s  (%.2f)\n', semNames{wk}, wrst);
end
fprintf('========================================\n');
fprintf('\nAnalysis complete.  Check this folder for saved .txt and .csv files.\n');
