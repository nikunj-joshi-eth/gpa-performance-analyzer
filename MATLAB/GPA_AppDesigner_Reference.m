% ==========================================================================
%  GPA_AppDesigner_Reference.m
%  Reference file — copy these callbacks into App Designer's Code View.
%
%  HOW TO SET UP:
%  1. Open MATLAB → Apps tab → App Designer → Blank App
%  2. Drag the following components onto the canvas and set their names
%     exactly as listed in the COMPONENT LIST below.
%  3. Switch to "Code View", find the callbacks section, and paste the
%     relevant callback code from this file.
%  4. The GPAAnalyzer.m class must be on the MATLAB path.
%
%  COMPONENT LIST (set Tag/Name in Design View → Inspector):
%  -------------------------------------------------------
%  UIFigure       (auto-created)
%  nSubjectsField  — Numeric Edit Field  "Number of subjects"
%  AddSubjectBtn   — Button              "Add Subject"
%  SubjectTable    — UI Table            (5 cols: Name,Credits,Marks,Att%,Grade)
%  CalcBtn         — Button              "Calculate GPA"
%  GPALabel        — Label               (shows live GPA)
%  PerfLabel       — Label               (shows performance band)
%  PlotBtn         — Button              "Show Charts"
%  SaveBtn         — Button              "Save Results"
%  SemesterField   — Edit Field (text)   "Semester name"
%  StatusLabel     — Label               (status messages)
% ==========================================================================

%% ---- App Properties (paste inside the 'properties (Access = private)' block) ----
%{
    analyzer GPAAnalyzer       % current semester analyzer object
    semGPAs  (1,:) double      % history for trend plot
    semNames (1,:) cell        % history for trend plot
    tableData cell             % raw data from SubjectTable
%}

%% ---- startupFcn (runs when app opens) ----
function startupFcn(app)
    app.semGPAs  = [];
    app.semNames = {};
    app.tableData = {};
    app.StatusLabel.Text = 'Enter number of subjects and click Add Subject.';

    % Pre-format the SubjectTable columns
    app.SubjectTable.ColumnName  = {'Subject','Credits','Marks','Att%','Grade'};
    app.SubjectTable.ColumnEditable = [true true true true false];
    app.SubjectTable.ColumnWidth = {140, 60, 60, 60, 60};
end

%% ---- AddSubjectBtn.ButtonPushedFcn ----
function AddSubjectBtnPushed(app, ~)
    n = round(app.nSubjectsField.Value);
    if n < 1 || n > 20
        app.StatusLabel.Text = 'ERROR: Number of subjects must be 1–20.';
        return;
    end

    % Build empty table rows
    data = cell(n, 5);
    for i = 1:n
        data{i,1} = sprintf('Subject %d', i);  % Name
        data{i,2} = 4;      % Default credits
        data{i,3} = 0;      % Marks
        data{i,4} = 100;    % Attendance
        data{i,5} = '—';    % Grade (read-only, filled after Calc)
    end
    app.SubjectTable.Data = data;
    app.tableData         = data;
    app.StatusLabel.Text  = sprintf('%d subject rows created. Fill in the table then click Calculate.', n);
end

%% ---- CalcBtn.ButtonPushedFcn ----
function CalcBtnPushed(app, ~)
    data = app.SubjectTable.Data;
    if isempty(data)
        app.StatusLabel.Text = 'ERROR: No subjects found. Add subjects first.';
        return;
    end

    n = size(data, 1);

    % Validate and extract
    subjects   = strings(1, n);
    credits    = zeros(1, n);
    marks      = zeros(1, n);
    attendance = zeros(1, n);

    for i = 1:n
        subjects(i)   = string(data{i,1});
        credits(i)    = data{i,2};
        marks(i)      = data{i,3};
        attendance(i) = data{i,4};

        % Validation
        if credits(i) < 1 || credits(i) > 6
            app.StatusLabel.Text = sprintf('ERROR: Credits for row %d must be 1–6.', i);
            return;
        end
        if marks(i) < 0 || marks(i) > 100
            app.StatusLabel.Text = sprintf('ERROR: Marks for row %d must be 0–100.', i);
            return;
        end
        if attendance(i) < 0 || attendance(i) > 100
            app.StatusLabel.Text = sprintf('ERROR: Attendance for row %d must be 0–100.', i);
            return;
        end
    end

    % Build analyzer object manually (bypassing inputData to use table values)
    semName         = string(app.SemesterField.Value);
    app.analyzer    = GPAAnalyzer(semName);
    app.analyzer.NumSubjects = n;   % Note: this requires NumSubjects to be public
    app.analyzer.Subjects    = subjects;
    app.analyzer.Credits     = credits;
    app.analyzer.Marks       = marks;
    app.analyzer.Attendance  = attendance;
    app.analyzer             = app.analyzer.calculate();

    % Update Grade column in table
    for i = 1:n
        data{i,5} = sprintf('%d (%s)', ...
            app.analyzer.GradePoints(i), app.analyzer.GradeLetters(i));
    end
    app.SubjectTable.Data = data;

    % Live GPA display
    app.GPALabel.Text  = sprintf('GPA: %.2f / 10', app.analyzer.GPA);
    app.PerfLabel.Text = sprintf('Performance: %s', app.analyzer.Performance);

    % Colour the performance label
    switch app.analyzer.Performance
        case "Excellent",        app.PerfLabel.FontColor = [0.10 0.40 0.85];
        case "Very Good",        app.PerfLabel.FontColor = [0.20 0.68 0.30];
        case "Good",             app.PerfLabel.FontColor = [0.60 0.60 0.00];
        case "Average",          app.PerfLabel.FontColor = [0.88 0.45 0.00];
        otherwise,               app.PerfLabel.FontColor = [0.88 0.18 0.18];
    end

    app.StatusLabel.Text = 'Calculation complete! Use Plot or Save buttons.';
end

%% ---- PlotBtn.ButtonPushedFcn ----
function PlotBtnPushed(app, ~)
    if isempty(app.analyzer) || isempty(app.analyzer.GPA)
        app.StatusLabel.Text = 'ERROR: Calculate GPA first.';
        return;
    end
    app.analyzer.plotCharts();

    % Trend (multi-semester)
    app.semGPAs(end+1)  = app.analyzer.GPA;
    app.semNames{end+1} = char(app.analyzer.SemesterName);
    if numel(app.semGPAs) >= 2
        GPAAnalyzer.plotTrend(app.semNames, app.semGPAs);
    end
    app.StatusLabel.Text = 'Charts displayed.';
end

%% ---- SaveBtn.ButtonPushedFcn ----
function SaveBtnPushed(app, ~)
    if isempty(app.analyzer) || isempty(app.analyzer.GPA)
        app.StatusLabel.Text = 'ERROR: Calculate GPA first.';
        return;
    end
    app.analyzer.saveResults();
    app.StatusLabel.Text = 'Results saved to .txt and .csv in current folder.';
end

% ==========================================================================
%  TIP: To make NumSubjects writable from outside the class, change
%       'properties (Access = private)' to 'properties' for NumSubjects
%       in GPAAnalyzer.m, or add a setter method.
% ==========================================================================
