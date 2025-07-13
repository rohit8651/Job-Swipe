# 🎯 Job Swipe – AI-Powered Job Recommendation App

## 📌 Overview
**Job Swipe** is a smart job discovery app that lets users upload their resume (PDF), scans and analyzes it using **Gemini AI**, and recommends the most relevant job roles. The app extracts key information like **skills, education, and projects**, and fetches real-time job listings based on this data using a public **Jobs API**. Users can **swipe right to like/save a job** or left to skip — making the job hunt simple, interactive, and AI-assisted.

---

## 🚀 Features

- 📄 **Upload Resume (PDF)** – Scan and extract structured resume content  
- 🤖 **AI-Powered Parsing** – Extracts:
  - Name
  - Email
  - Skills & Education
  - Projects  
- 🎯 **Role Recommendations** – Suggests top 3 roles using Gemini LLM based on extracted skills  
- 🧭 **Job Listings Explorer** – Fetches and displays job postings using **RapidAPI**  
- 💾 **Save or Like** – Swipe right to save job for later  
- 🔗 **Job Detail View** – View full job description and apply link

---

## 🛠️ Tech Stack

- **Flutter** – Cross-platform mobile UI  
- **Dart** – Core app logic  
- **Firebase** – Auth + Firestore (for saved jobs & history)  
- **Gemini AI (LLM)** – Resume analysis, job role suggestions  
- **PDF Parser** – Text extraction from uploaded resume  
- **RapidAPI** – Job listing and search API

---

## 📱 Screenshots

📍 Resume Upload → Extracted Details → Recommended Roles  
![Upload & Roles](assets\resume_parser_screen.dart)
📍 Job Listings → Swipeable Cards → Job Detail View  
![Job Details](assets\job_list_screen.dart)

---

## 📥 How to Run Locally

1. **Clone the repository:**
   ```bash https://github.com/rohit8651/Job-Swipe.git
       cd job-swipe
