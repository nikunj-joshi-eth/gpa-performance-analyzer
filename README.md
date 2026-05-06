# 📊 College GPA & Performance Analyzer

<div align="center">

<!-- Language & Tool Badges -->
![MATLAB](https://img.shields.io/badge/MATLAB-R2024b-0076A8?style=for-the-badge&logo=mathworks&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.x-3776AB?style=for-the-badge&logo=python&logoColor=white)
![HTML5](https://img.shields.io/badge/HTML5-E34F26?style=for-the-badge&logo=html5&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black)
![Chart.js](https://img.shields.io/badge/Chart.js-v4-FF6384?style=for-the-badge&logo=chartdotjs&logoColor=white)
![GitHub release](https://img.shields.io/github/v/release/yourusername/gpa-performance-analyzer?style=for-the-badge&color=1B3A6B)
![Python CI](https://github.com/yourusername/gpa-performance-analyzer/actions/workflows/python-app.yml/badge.svg)

<!-- Project Info Badges -->
![Students](https://img.shields.io/badge/Students-60-16A34A?style=for-the-badge)
![Subjects](https://img.shields.io/badge/Subjects-6-0891B2?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-D97706?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Completed-22c55e?style=for-the-badge)

<!-- Academic Badges -->

</div>

---

> A multi-tool academic analytics system — MATLAB · HTML/JS · Python  
> 2025–26


---

## 🧠 What This Project Does

Most GPA calculators just give you a number. This system tells you **why** your GPA is what it is, which subject is pulling it down, and exactly how many more marks you need to improve — all automatically.

Built as a mini-project , the core of the system is the weighted average formula:

```
GPA = Σ(Credits_i × GradePoints_i) / Σ(Credits_i)
```

---

## ✨ Features

| Feature | Tool |
|--------|------|
| Weighted GPA calculation with input validation | MATLAB |
| Grade letters: O / A+ / A / B+ / B / F | MATLAB |
| Backlog detection & attendance < 75% warning | MATLAB |
| Colour-coded grade bar chart | MATLAB |
| Radar / spider chart per student | MATLAB |
| Attendance bar chart with 75% threshold line | MATLAB |
| Credit distribution pie chart | MATLAB |
| Multi-semester CGPA trend line | MATLAB |
| Batch processing of 60 students from CSV | MATLAB |
| Interactive class dashboard — works in any browser | HTML + Chart.js |
| Live what-if GPA simulator with sliders | HTML + JS |
| 60 PDF report cards with QR codes | Python |

---

## 🗂️ File Structure

```
gpa-performance-analyzer/
│
├── GPAAnalyzer.m          # Core MATLAB class (OOP) — GPA logic lives here
├── main_gpa.m             # Interactive runner — type >> main_gpa to start
├── batch_analyze.m        # Processes all 60 students from CSV in one go
├── export_json.m          # Exports data to JSON for HTML files
│
├── student_data.csv       # Sample dataset — 60 students × 6 subjects
│
├── dashboard.html         # Class analytics dashboard (just open in browser)
├── forecaster.html        # Live GPA what-if simulator (just open in browser)
│
└── generate_reports.py    # Python — generates 60 PDF report cards with QR codes
```

---

## 🚀 How to Run

### MATLAB — interactive mode (one student at a time)
```matlab
>> main_gpa
```
Asks for subject names, credits, marks, and attendance. Opens 4 charts automatically. Saves a `.txt` and `.csv` result file.

### MATLAB — batch mode (all 60 students)
```matlab
>> batch_analyze
```
Reads `student_data.csv`, processes all 60 students silently, generates class-wide charts and saves `class_results.csv`.

### HTML files — just double-click
No installation needed. Open `dashboard.html` or `forecaster.html` in Chrome/Edge/Firefox — they are self-contained files with all data embedded.

### Python — PDF report cards
```bash
# Install once
pip install reportlab qrcode[pil] Pillow

# Generate all 60 PDFs
python generate_reports.py

# Generate for one student only
python generate_reports.py --single S001
```
PDFs are saved to a `report_cards/` folder.

---

## 📐 Grade Conversion Scale

| Marks | Grade Points | Letter | Performance |
|-------|-------------|--------|-------------|
| 90 – 100 | 10 | O (Outstanding) | Excellent |
| 80 – 89  | 9  | A+              | Very Good |
| 70 – 79  | 8  | A               | Good      |
| 60 – 69  | 7  | B+              | Good      |
| 50 – 59  | 6  | B               | Average   |
| 0  – 49  | 0  | F (Fail)        | Needs Improvement |

---

## 📊 Sample Dataset

The project includes `student_data.csv` with **60 students** across **6 subjects** (20 credit hours total):

- Mathematics (4 credits)
- Physics (4 credits)
- Chemistry (3 credits)
- English (2 credits)
- Programming (4 credits)
- Engineering Drawing (3 credits)

The dataset covers all performance levels — from a 9.90 GPA topper to students with all-subject backlogs — to demonstrate every feature of the system.

---

## 🏗️ Architecture

```
student_data.csv
      │
      ▼
 MATLAB Core ──────────────────────────────────────
 GPAAnalyzer class                                  │
  ├── inputData()     ← collects & validates input  │
  ├── calculate()     ← weighted GPA formula        │
  ├── displayResults()← console table + suggestions │
  ├── plotCharts()    ← 4 MATLAB figures             │
  └── saveResults()   ← .txt + .csv output          │
                                                    │
 batch_analyze.m ──────────── class_results.csv     │
                                                    │
      ┌─────────────────────────────────────────────┘
      │
      ├── dashboard.html   ← Chart.js, all data embedded
      ├── forecaster.html  ← live JS sliders, no server needed
      └── generate_reports.py ── 60 × PDF report cards
                                  each with a QR code
```

---

## 🛠️ Tech Stack

![MATLAB](https://img.shields.io/badge/MATLAB-OOP%20%7C%20Plotting%20%7C%20File%20I%2FO-0076A8?style=flat-square&logo=mathworks&logoColor=white)
![Python](https://img.shields.io/badge/Python-reportlab%20%7C%20qrcode%20%7C%20Pillow-3776AB?style=flat-square&logo=python&logoColor=white)
![HTML5](https://img.shields.io/badge/HTML5-Self--contained%20dashboard-E34F26?style=flat-square&logo=html5&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-Live%20GPA%20Simulator-F7DF1E?style=flat-square&logo=javascript&logoColor=black)
![Chart.js](https://img.shields.io/badge/Chart.js-5%20interactive%20charts-FF6384?style=flat-square&logo=chartdotjs&logoColor=white)
![CSV](https://img.shields.io/badge/CSV-60%20students%20dataset-16A34A?style=flat-square)

---

## 👨‍💻 Author

<div align="center">

![Nikunj Joshi](https://img.shields.io/badge/Nikunj%20Joshi-1B3A6B?style=for-the-badge&logo=github&logoColor=white)

Nikunj Joshi B.Tech Student | Embedded Systems | IoT | Problem Solver

LinkedIn: https://www.linkedin.com/in/nikunj-joshi-83390235a/
---

## 📄 License

![MIT License](https://img.shields.io/badge/License-MIT-D97706?style=flat-square)

This project is open source under the [MIT License](LICENSE).  
Feel free to use, modify, and build on it — just give credit.
