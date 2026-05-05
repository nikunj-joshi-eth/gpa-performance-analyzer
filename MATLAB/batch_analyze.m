% batch_analyze.m
% Loads student_data.csv and runs GPAAnalyzer on all 60 students.
% Produces:
%   - Per-student results printed to console
%   - Consolidated class_results.csv  with GPA, performance, backlogs
%   - Class-level visualisations (GPA distribution, top/bottom 10, etc.)
%
% Requirements: GPAAnalyzer.m and student_data.csv in the same folder.
% Run: >> batch_analyze

clc; clear; close all;

%% ── 1. Load CSV ──────────────────────────────────────────────────────────
fname = 'student_data.csv';
T = readtable(fname, 'TextType','string');
fprintf('Loaded %d rows from %s\n', height(T), fname);

studentIDs = unique(T.StudentID, 'stable');
nStudents  = numel(studentIDs);

%% ── 2. Batch process every student ──────────────────────────────────────
% Pre-allocate summary arrays
summaryID    = strings(nStudents, 1);
summaryName  = strings(nStudents, 1);
summaryGPA   = zeros(nStudents,  1);    
summaryPerf  = strings(nStudents, 1);
summaryBacklogs = zeros(nStudents, 1);
summaryLowAtt   = zeros(nStudents, 1);

fprintf('\nProcessing %d students...\n', nStudents);
fprintf('%s\n', repmat('-',1,65));

for k = 1:nStudents
    sid  = studentIDs(k);
    rows = T(T.StudentID == sid, :);

    % Build GPAAnalyzer object from table row (no keyboard input needed)
    semName = char(rows.Semester(1));
    a = GPAAnalyzer(semName);

    % Manually populate (bypasses interactive inputData)
    n = height(rows);
    a.Subjects   = rows.Subject';
    a.Credits    = rows.Credits';
    a.Marks      = rows.Marks';
    a.Attendance = rows.Attendance';

    % Patch private NumSubjects via calculate (it reads from Subjects length)
    a = patchAndCalculate(a, n);

    % Store summary
    summaryID(k)       = sid;
    summaryName(k)     = rows.StudentName(1);
    summaryGPA(k)      = a.GPA;
    summaryPerf(k)     = a.Performance;
    summaryBacklogs(k) = sum(a.GradePoints == 0);
    summaryLowAtt(k)   = sum(a.Attendance  <  75);

    fprintf('  %-6s  %-22s  GPA: %5.2f  %-18s  Backlogs: %d  LowAtt: %d\n', ...
        sid, rows.StudentName(1), a.GPA, a.Performance, ...
        summaryBacklogs(k), summaryLowAtt(k));
end

%% ── 3. Save consolidated CSV ─────────────────────────────────────────────
outFile = 'class_results.csv';
fid = fopen(outFile, 'w');
fprintf(fid, 'StudentID,StudentName,GPA,Performance,BacklogCount,LowAttendanceSubjects\n');
for k = 1:nStudents
    fprintf(fid, '%s,%s,%.2f,%s,%d,%d\n', ...
        summaryID(k), summaryName(k), summaryGPA(k), ...
        summaryPerf(k), summaryBacklogs(k), summaryLowAtt(k));
end
fclose(fid);
fprintf('\n[SAVED] %s\n', outFile);

%% ── 4. Class Statistics ──────────────────────────────────────────────────
fprintf('\n========== CLASS STATISTICS ==========\n');
fprintf('  Students analysed : %d\n',       nStudents);
fprintf('  Class Average GPA : %.2f\n',     mean(summaryGPA));
fprintf('  Highest GPA       : %.2f  (%s)\n', max(summaryGPA), ...
    summaryName(summaryGPA == max(summaryGPA)));
fprintf('  Lowest  GPA       : %.2f  (%s)\n', min(summaryGPA), ...
    summaryName(summaryGPA == min(summaryGPA)));
fprintf('  Std Deviation     : %.2f\n',     std(summaryGPA));

perfCats   = ["Excellent","Very Good","Good","Average","Needs Improvement"];
fprintf('\n  Performance Band Distribution:\n');
for p = perfCats
    cnt = sum(summaryPerf == p);
    bar_vis = repmat('█', 1, cnt);
    fprintf('    %-20s : %2d  %s\n', p, cnt, bar_vis);
end
fprintf('\n  Students with Backlogs     : %d\n', sum(summaryBacklogs > 0));
fprintf('  Students with Low Att (<75%%): %d\n', sum(summaryLowAtt  > 0));
fprintf('=======================================\n');

%% ── 5. Visualisations ────────────────────────────────────────────────────

% 5a. GPA Histogram
figure('Name','GPA Distribution','Color','white');
histogram(summaryGPA, 10, 'FaceColor',[0.10 0.40 0.85], ...
    'EdgeColor','white','FaceAlpha',0.85);
hold on;
xline(mean(summaryGPA),'r--','LineWidth',2, ...
    'Label',sprintf('Mean %.2f', mean(summaryGPA)), ...
    'LabelHorizontalAlignment','right');
hold off;
xlabel('GPA'); ylabel('Number of Students');
title('Class GPA Distribution','FontSize',13,'FontWeight','bold');
grid on;

% 5b. Performance band pie chart
perfCounts = arrayfun(@(p) sum(summaryPerf==p), perfCats);
nonZero    = perfCounts > 0;
figure('Name','Performance Bands','Color','white');
pie(perfCounts(nonZero), cellstr(perfCats(nonZero)));
title('Performance Band Distribution','FontSize',13,'FontWeight','bold');
colormap(gca, [0.10 0.40 0.85; 0.20 0.68 0.30; ...
               0.60 0.60 0.00; 0.95 0.70 0.10; 0.88 0.18 0.18]);

% 5c. Top 10 students bar chart
[sortedGPA, sortIdx] = sort(summaryGPA, 'descend');
top10idx = sortIdx(1:min(10,nStudents));
figure('Name','Top 10 Students','Color','white');
b = bar(sortedGPA(1:numel(top10idx)), 'FaceColor',[0.10 0.40 0.85]);
xticks(1:numel(top10idx));
xticklabels(summaryName(top10idx));
xtickangle(30);
ylim([0 10.5]);
ylabel('GPA');
title('Top 10 Students by GPA','FontSize',13,'FontWeight','bold');
for i = 1:numel(top10idx)
    text(i, sortedGPA(i)+0.15, sprintf('%.2f', sortedGPA(i)), ...
        'HorizontalAlignment','center','FontSize',8,'FontWeight','bold');
end
grid on;

% 5d. Bottom 10 students bar chart
bot10idx = sortIdx(max(1,end-9):end);
bot10gpa = summaryGPA(bot10idx);
figure('Name','Bottom 10 Students','Color','white');
bar(bot10gpa, 'FaceColor',[0.88 0.18 0.18]);
xticks(1:numel(bot10idx));
xticklabels(summaryName(bot10idx));
xtickangle(30);
ylim([0 10.5]);
ylabel('GPA');
title('Bottom 10 Students by GPA','FontSize',13,'FontWeight','bold');
for i = 1:numel(bot10idx)
    text(i, bot10gpa(i)+0.15, sprintf('%.2f', bot10gpa(i)), ...
        'HorizontalAlignment','center','FontSize',8,'FontWeight','bold');
end
grid on;

% 5e. Backlog count per student (only those with ≥1 backlog)
backlogMask = summaryBacklogs > 0;
if any(backlogMask)
    figure('Name','Students with Backlogs','Color','white');
    bar(summaryBacklogs(backlogMask), 'FaceColor',[0.95 0.45 0.10]);
    xticks(1:sum(backlogMask));
    xticklabels(summaryName(backlogMask));
    xtickangle(30);
    ylabel('Number of Backlogs');
    title('Students with Backlogs','FontSize',13,'FontWeight','bold');
    grid on;
end

fprintf('\nBatch analysis complete.  See class_results.csv for full data.\n');

%% ── Helper: populate NumSubjects (private workaround) ──────────────────
function a = patchAndCalculate(a, n)
% GPAAnalyzer.calculate() uses numel(a.Subjects) so n is already encoded.
% We just need to set the private field via calculate which will derive it.
% This works because calculate() calls numel(a.Subjects) internally.
% If NumSubjects is private, use this direct recalculation instead:

    gradePoints  = zeros(1, n);
    gradeLetters = strings(1, n);
    for i = 1:n
        [gradePoints(i), gradeLetters(i)] = GPAAnalyzer.marksToGrade(a.Marks(i));
    end
    a.GradePoints  = gradePoints;
    a.GradeLetters = gradeLetters;

    totalCredits = sum(a.Credits);
    a.GPA        = sum(a.Credits .* gradePoints) / totalCredits;
    a.Performance = GPAAnalyzer.classifyPerformance(a.GPA);
end
