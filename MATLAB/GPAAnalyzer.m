classdef GPAAnalyzer
% GPAAnalyzer  College GPA & Performance Analyzer
%
%   USAGE (single semester):
%       a = GPAAnalyzer('Semester 1');
%       a = a.inputData();
%       a = a.calculate();
%       a.displayResults();
%       a.plotCharts();
%       a.saveResults();
%
%   USAGE (multi-semester trend) — see main_gpa.m

    % ------------------------------------------------------------------ %
    %  Public properties
    % ------------------------------------------------------------------ %
    properties
        Subjects        string
        Credits         double
        Marks           double
        Attendance      double
        GradePoints     double
        GradeLetters    string
        GPA             double
        Performance     string
        SemesterName    string
    end

    properties (Access = private)
        NumSubjects (1,1) double = 0
    end

    % ================================================================== %
    %  Public methods
    % ================================================================== %
    methods

        % -------------------------------------------------------------- %
        %  Constructor
        % -------------------------------------------------------------- %
        function obj = GPAAnalyzer(semName)
            if nargin < 1
                semName = "Semester 1";
            end
            obj.SemesterName = semName;
        end

        % -------------------------------------------------------------- %
        %  Input with full validation
        % -------------------------------------------------------------- %
        function obj = inputData(obj)
            fprintf('\n=== %s ===\n', obj.SemesterName);

            % -- Number of subjects --
            n = GPAAnalyzer.validatedInput( ...
                'Enter number of subjects: ', 1, 20, true);
            obj.NumSubjects = n;

            obj.Subjects   = strings(1, n);
            obj.Credits    = zeros(1, n);
            obj.Marks      = zeros(1, n);
            obj.Attendance = zeros(1, n);

            for i = 1:n
                fprintf('\n--- Subject %d ---\n', i);

                obj.Subjects(i) = strtrim(input('  Subject name      : ', 's'));

                obj.Credits(i) = GPAAnalyzer.validatedInput( ...
                    '  Credits   (1–6)  : ', 1, 6, false);

                obj.Marks(i) = GPAAnalyzer.validatedInput( ...
                    '  Marks   (0–100)  : ', 0, 100, false);

                obj.Attendance(i) = GPAAnalyzer.validatedInput( ...
                    '  Attendance (0–100)%: ', 0, 100, false);
            end
        end

        % -------------------------------------------------------------- %
        %  Calculate GPA, grades, performance
        % -------------------------------------------------------------- %
        function obj = calculate(obj)
            n = obj.NumSubjects;
            obj.GradePoints  = zeros(1, n);
            obj.GradeLetters = strings(1, n);

            for i = 1:n
                [obj.GradePoints(i), obj.GradeLetters(i)] = ...
                    GPAAnalyzer.marksToGrade(obj.Marks(i));
            end

            totalCredits  = sum(obj.Credits);
            obj.GPA       = sum(obj.Credits .* obj.GradePoints) / totalCredits;
            obj.Performance = GPAAnalyzer.classifyPerformance(obj.GPA);
        end

        % -------------------------------------------------------------- %
        %  Display formatted results
        % -------------------------------------------------------------- %
        function displayResults(obj)
            SEP = repmat('=', 1, 62);
            fprintf('\n%s\n', SEP);
            fprintf('  RESULT — %s\n', obj.SemesterName);
            fprintf('%s\n', SEP);

            % Header row
            fprintf('  %-20s %6s %7s %4s %5s %7s\n', ...
                'Subject','Credits','Marks','GP','Grade','Att%');
            fprintf('  %s\n', repmat('-',1,56));

            % Subject rows
            for i = 1:obj.NumSubjects
                flag = '';
                if obj.Attendance(i) < 75,  flag = [flag ' [!ATT]']; end
                if obj.GradePoints(i) == 0, flag = [flag ' [FAIL]']; end
                fprintf('  %-20s %6d %7.1f %4d %5s %6.1f%%%s\n', ...
                    obj.Subjects(i), obj.Credits(i), obj.Marks(i), ...
                    obj.GradePoints(i), obj.GradeLetters(i), ...
                    obj.Attendance(i), flag);
            end

            fprintf('  %s\n', repmat('-',1,56));
            fprintf('  Total Credits   : %d\n',    sum(obj.Credits));
            fprintf('  GPA             : %.2f / 10\n', obj.GPA);
            fprintf('  Performance     : %s\n',    obj.Performance);

            [~, bIdx] = max(obj.GradePoints);
            [~, wIdx] = min(obj.GradePoints);
            fprintf('  Best Subject    : %s\n', obj.Subjects(bIdx));
            fprintf('  Weakest Subject : %s\n', obj.Subjects(wIdx));
            fprintf('%s\n', SEP);

            % Attendance warnings
            lowAtt = find(obj.Attendance < 75);
            if ~isempty(lowAtt)
                fprintf('\n[WARNING] Attendance below 75%%:\n');
                for i = lowAtt
                    fprintf('  * %s — %.1f%%\n', obj.Subjects(i), obj.Attendance(i));
                end
            end

            % Backlog
            fails = find(obj.GradePoints == 0);
            if ~isempty(fails)
                fprintf('\n[BACKLOG] Failed subjects:\n');
                for i = fails
                    fprintf('  * %s\n', obj.Subjects(i));
                end
            end

            % GPA gap to next level
            obj.showGPAGap();

            % Improvement suggestions
            obj.showImprovementSuggestions();
        end

        % -------------------------------------------------------------- %
        %  Show how far the student is from the next GPA level
        % -------------------------------------------------------------- %
        function showGPAGap(obj)
            thresholds = [9.0, 8.0, 7.0, 6.0];
            labels     = ["Excellent (9.0+)", "Very Good (8.0+)", ...
                          "Good (7.0+)", "Average (6.0+)"];
            fprintf('\n[GPA GAP]\n');
            for k = 1:numel(thresholds)
                if obj.GPA < thresholds(k)
                    fprintf('  You need +%.2f GPA points to reach %s.\n', ...
                        thresholds(k) - obj.GPA, labels(k));
                    return;
                end
            end
            fprintf('  You are in the Excellent band — keep it up!\n');
        end

        % -------------------------------------------------------------- %
        %  Per-subject improvement suggestions
        % -------------------------------------------------------------- %
        function showImprovementSuggestions(obj)
            markThresh = [90, 80, 70, 60, 50];
            gradeLabel = ["O (10)", "A+ (9)", "A (8)", "B+ (7)", "B (6)"];

            fprintf('\n[IMPROVEMENT SUGGESTIONS]\n');
            for i = 1:obj.NumSubjects
                m = obj.Marks(i);
                moved = false;
                for t = 1:numel(markThresh)
                    if m < markThresh(t)
                        fprintf('  * %-20s : Need %d more marks to reach Grade %s\n', ...
                            obj.Subjects(i), markThresh(t) - m, gradeLabel(t));
                        moved = true;
                        break;
                    end
                end
                if ~moved
                    fprintf('  * %-20s : Perfect score — well done!\n', obj.Subjects(i));
                end
            end
        end

        % -------------------------------------------------------------- %
        %  All four charts
        % -------------------------------------------------------------- %
        function plotCharts(obj)
            obj.plotGradeBar();
            obj.plotCreditPie();
            obj.plotRadar();
            obj.plotAttendanceBar();
        end

        % -------------------------------------------------------------- %
        %  Color-coded Grade Point bar chart
        % -------------------------------------------------------------- %
        function plotGradeBar(obj)
            n = obj.NumSubjects;
            clr = zeros(n, 3);
            for i = 1:n
                gp = obj.GradePoints(i);
                if gp == 0
                    clr(i,:) = [0.88 0.18 0.18];   % Red   – Fail
                elseif gp <= 6
                    clr(i,:) = [0.95 0.70 0.10];   % Amber – Average
                elseif gp <= 8
                    clr(i,:) = [0.20 0.68 0.30];   % Green – Good
                else
                    clr(i,:) = [0.10 0.40 0.85];   % Blue  – Excellent
                end
            end

            figure('Name','Grade Points','NumberTitle','off','Color','white');
            b = bar(obj.GradePoints, 'FaceColor','flat');
            b.CData = clr;
            hold on;

            % Value labels on top of bars
            for i = 1:n
                text(i, obj.GradePoints(i) + 0.18, ...
                    sprintf('%d\n(%s)', obj.GradePoints(i), obj.GradeLetters(i)), ...
                    'HorizontalAlignment','center','FontSize',8,'FontWeight','bold');
            end

            % Dummy patches for legend
            p1 = patch(NaN,NaN,[0.88 0.18 0.18]);
            p2 = patch(NaN,NaN,[0.95 0.70 0.10]);
            p3 = patch(NaN,NaN,[0.20 0.68 0.30]);
            p4 = patch(NaN,NaN,[0.10 0.40 0.85]);
            legend([p1 p2 p3 p4], {'Fail (F)', 'Average (B)', ...
                'Good (A/B+)', 'Excellent (A+/O)'}, ...
                'Location','northeast','FontSize',8);

            hold off;
            xticks(1:n);
            xticklabels(obj.Subjects);
            xtickangle(30);
            ylim([0 11]);
            yticks(0:1:10);
            ylabel('Grade Points');
            xlabel('Subjects');
            title(sprintf('Subject-wise Grade Points — %s', obj.SemesterName), ...
                'FontSize',13,'FontWeight','bold');
            grid on; grid minor;
        end

        % -------------------------------------------------------------- %
        %  Credit distribution pie chart
        % -------------------------------------------------------------- %
        function plotCreditPie(obj)
            figure('Name','Credit Distribution','NumberTitle','off','Color','white');
            pie(obj.Credits, cellstr(obj.Subjects));
            title('Credit Distribution Across Subjects', ...
                'FontSize',13,'FontWeight','bold');
        end

        % -------------------------------------------------------------- %
        %  Radar / Spider chart
        % -------------------------------------------------------------- %
        function plotRadar(obj)
            n       = obj.NumSubjects;
            values  = obj.GradePoints / 10;          % normalise 0-1
            angles  = linspace(0, 2*pi, n+1);
            angles  = angles(1:n);                   % n evenly-spaced spokes

            sx = cos(angles);
            sy = sin(angles);

            % Polygon vertices (closed)
            vx = [values .* sx, values(1)*sx(1)];
            vy = [values .* sy, values(1)*sy(1)];

            figure('Name','Radar Chart','NumberTitle','off','Color','white');
            hold on;

            % Grid rings
            for r = 0.2:0.2:1.0
                th = linspace(0, 2*pi, 200);
                plot(r*cos(th), r*sin(th), 'Color',[0.82 0.82 0.82],'LineWidth',0.5);
                % Ring label at top
                text(0, r+0.03, num2str(r*10,'%.0f'), ...
                    'HorizontalAlignment','center','FontSize',7,'Color',[0.55 0.55 0.55]);
            end

            % Spokes
            for k = 1:n
                plot([0 sx(k)],[0 sy(k)],'Color',[0.75 0.75 0.75],'LineWidth',0.8);
            end

            % Data polygon
            fill(vx, vy, [0.10 0.40 0.85], 'FaceAlpha',0.25, ...
                'EdgeColor',[0.10 0.40 0.85],'LineWidth',2);
            scatter(vx(1:n), vy(1:n), 60, [0.10 0.40 0.85], 'filled');

            % Subject labels
            for k = 1:n
                text(1.22*sx(k), 1.22*sy(k), obj.Subjects(k), ...
                    'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
            end

            axis equal; axis off;
            title(sprintf('Performance Radar — %s', obj.SemesterName), ...
                'FontSize',13,'FontWeight','bold');
            hold off;
        end

        % -------------------------------------------------------------- %
        %  Attendance bar chart with 75% threshold line
        % -------------------------------------------------------------- %
        function plotAttendanceBar(obj)
            n = obj.NumSubjects;
            clr = zeros(n, 3);
            for i = 1:n
                if obj.Attendance(i) < 75
                    clr(i,:) = [0.88 0.18 0.18];
                else
                    clr(i,:) = [0.20 0.68 0.30];
                end
            end

            figure('Name','Attendance','NumberTitle','off','Color','white');
            ba = bar(obj.Attendance, 'FaceColor','flat');
            ba.CData = clr;
            hold on;
            yline(75,'r--','LineWidth',2,'Label','  75% Min','LabelHorizontalAlignment','left');
            hold off;

            xticks(1:n);
            xticklabels(obj.Subjects);
            xtickangle(30);
            ylim([0 108]);
            ylabel('Attendance (%)');
            xlabel('Subjects');
            title('Subject-wise Attendance', 'FontSize',13,'FontWeight','bold');
            grid on;
        end

        % -------------------------------------------------------------- %
        %  Save results to .txt and .csv
        % -------------------------------------------------------------- %
        function saveResults(obj, baseName)
            if nargin < 2
                baseName = sprintf('GPA_%s', ...
                    strrep(strrep(obj.SemesterName,' ','_'),'/','_'));
            end

            txtFile = [baseName '.txt'];
            csvFile = [baseName '.csv'];

            % ---------- TXT ----------
            fid = fopen(txtFile, 'w');
            if fid == -1
                warning('GPAAnalyzer:saveResults', ...
                    'Cannot open %s for writing.', txtFile);
                return;
            end
            fprintf(fid, 'COLLEGE GPA & PERFORMANCE ANALYZER\n');
            fprintf(fid, 'Semester : %s\n', obj.SemesterName);
            fprintf(fid, 'Date     : %s\n\n', datestr(now, 'dd-mmm-yyyy HH:MM'));
            fprintf(fid, '%-20s %7s %7s %4s %6s %8s\n', ...
                'Subject','Credits','Marks','GP','Grade','Att%');
            fprintf(fid, '%s\n', repmat('-',1,58));
            for i = 1:obj.NumSubjects
                fprintf(fid, '%-20s %7d %7.1f %4d %6s %7.1f%%\n', ...
                    obj.Subjects(i), obj.Credits(i), obj.Marks(i), ...
                    obj.GradePoints(i), obj.GradeLetters(i), obj.Attendance(i));
            end
            fprintf(fid, '%s\n', repmat('-',1,58));
            fprintf(fid, 'Total Credits   : %d\n',    sum(obj.Credits));
            fprintf(fid, 'GPA             : %.2f\n',  obj.GPA);
            fprintf(fid, 'Performance     : %s\n',    obj.Performance);
            fclose(fid);

            % ---------- CSV ----------
            fid2 = fopen(csvFile, 'w');
            fprintf(fid2, 'Subject,Credits,Marks,GradePoints,GradeLetter,Attendance\n');
            for i = 1:obj.NumSubjects
                fprintf(fid2, '%s,%d,%.1f,%d,%s,%.1f\n', ...
                    obj.Subjects(i), obj.Credits(i), obj.Marks(i), ...
                    obj.GradePoints(i), obj.GradeLetters(i), obj.Attendance(i));
            end
            fprintf(fid2, ',,,,,\n');
            fprintf(fid2, 'GPA,%.2f,,,,\n', obj.GPA);
            fprintf(fid2, 'Performance,%s,,,,\n', obj.Performance);
            fclose(fid2);

            fprintf('\n[SAVED] %s  and  %s\n', txtFile, csvFile);
        end

    end   % end public methods

    % ================================================================== %
    %  Static / utility methods
    % ================================================================== %
    methods (Static)

        % -------------------------------------------------------------- %
        %  Marks → Grade Point + Grade Letter
        % -------------------------------------------------------------- %
        function [gp, gl] = marksToGrade(marks)
            if marks >= 90
                gp = 10; gl = "O";
            elseif marks >= 80
                gp = 9;  gl = "A+";
            elseif marks >= 70
                gp = 8;  gl = "A";
            elseif marks >= 60
                gp = 7;  gl = "B+";
            elseif marks >= 50
                gp = 6;  gl = "B";
            else
                gp = 0;  gl = "F";
            end
        end

        % -------------------------------------------------------------- %
        %  GPA → Performance label
        % -------------------------------------------------------------- %
        function perf = classifyPerformance(gpa)
            if gpa >= 9,     perf = "Excellent";
            elseif gpa >= 8, perf = "Very Good";
            elseif gpa >= 7, perf = "Good";
            elseif gpa >= 6, perf = "Average";
            else,            perf = "Needs Improvement";
            end
        end

        % -------------------------------------------------------------- %
        %  Multi-semester GPA trend line
        % -------------------------------------------------------------- %
        function plotTrend(semNames, gpaValues)
            if numel(gpaValues) < 2
                fprintf('[TREND] Need at least 2 semesters to plot trend.\n');
                return;
            end

            figure('Name','GPA Trend','NumberTitle','off','Color','white');
            hold on;

            % Coloured band zones
            xRange = [0.5, numel(gpaValues)+0.5];
            fill([xRange fliplr(xRange)], [9 9 10 10],[0.10 0.40 0.85],'FaceAlpha',0.07,'EdgeColor','none');
            fill([xRange fliplr(xRange)], [8 8  9  9],[0.20 0.68 0.30],'FaceAlpha',0.07,'EdgeColor','none');
            fill([xRange fliplr(xRange)], [7 7  8  8],[0.95 0.70 0.10],'FaceAlpha',0.07,'EdgeColor','none');
            fill([xRange fliplr(xRange)], [6 6  7  7],[0.88 0.18 0.18],'FaceAlpha',0.07,'EdgeColor','none');

            % Threshold lines
            yline(9,'--','Color',[0.10 0.40 0.85],'LineWidth',1.2,'Label','Excellent','LabelHorizontalAlignment','right');
            yline(8,'--','Color',[0.20 0.68 0.30],'LineWidth',1.2,'Label','Very Good','LabelHorizontalAlignment','right');
            yline(7,'--','Color',[0.95 0.70 0.10],'LineWidth',1.2,'Label','Good','LabelHorizontalAlignment','right');
            yline(6,'--','Color',[0.88 0.18 0.18],'LineWidth',1.2,'Label','Average','LabelHorizontalAlignment','right');

            % GPA line
            plot(1:numel(gpaValues), gpaValues, '-o', ...
                'LineWidth',2.5,'MarkerSize',9, ...
                'Color',[0.10 0.40 0.85],'MarkerFaceColor',[0.10 0.40 0.85]);

            % Data point labels
            for i = 1:numel(gpaValues)
                text(i, gpaValues(i)+0.18, sprintf('%.2f', gpaValues(i)), ...
                    'HorizontalAlignment','center','FontWeight','bold','FontSize',9);
            end

            xticks(1:numel(semNames));
            xticklabels(semNames);
            xtickangle(30);
            xlim([0.5, numel(gpaValues)+0.5]);
            ylim([0 10.5]);
            ylabel('GPA');
            title('Semester-over-Semester GPA Trend','FontSize',13,'FontWeight','bold');
            grid on; grid minor;
            hold off;
        end

        % -------------------------------------------------------------- %
        %  Validated numeric input helper
        % -------------------------------------------------------------- %
        function val = validatedInput(prompt, minVal, maxVal, mustBeInteger)
            while true
                val = input(prompt);
                ok = isnumeric(val) && isscalar(val) && ...
                     val >= minVal  && val <= maxVal;
                if mustBeInteger
                    ok = ok && (floor(val) == val);
                end
                if ok
                    break;
                end
                if mustBeInteger
                    fprintf('  [ERROR] Enter a whole number between %d and %d.\n', minVal, maxVal);
                else
                    fprintf('  [ERROR] Enter a number between %.1f and %.1f.\n', minVal, maxVal);
                end
            end
        end

    end   % end static methods

end   % end classdef
