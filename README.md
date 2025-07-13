# Job Recommendation App

## 📌 Overview
This app allows users to upload a PDF file (such as a CV or resume), extracts relevant text, and uses **Gemini AI** to analyze the content. It identifies key details like **name, email, skills, projects, and education** and then recommends **three suitable job roles** based on the extracted information. Users can explore job listings for the recommended roles and view job details with a single click.

## 🚀 Features
- 📄 **Upload PDF**: Users can upload their resume/CV.
- 🔍 **Extract Text**: Extracts text from the uploaded PDF.
- 🤖 **AI-Powered Analysis**: Uses **Gemini AI** to extract key details such as:
  - Name
  - Email
  - Skills
  - Projects
  - Education
- 🎯 **Job Role Recommendation**: Suggests **3 relevant job roles** based on the extracted skills and projects.
- 🏢 **Job Listings**: Displays job openings for the recommended roles.
- 🔗 **Job Details View**: Users can click on a job listing to view more details.

## 🛠️ Technologies Used
- **Flutter** (for front-end development)
- **Dart** (for app logic)
- **Firebase** (for storing job data and user interactions)
- **Gemini AI API** (for extracting and analyzing resume content)
- **PDF Parser** (to extract text from uploaded PDFs)

## 📸 Screenshots
---
Upload Resume, Extracted Data, Suggested Roles, Role Jobs
---
![1](https://github.com/user-attachments/assets/e18b41f3-9cce-49a3-b954-fa54672969ea)
---
Job Details, Apply link, App Options, Data Save Options
---
![2](https://github.com/user-attachments/assets/67f6adb3-6b02-4ca6-aa7e-dec00aca766b)
---

## 📥 Installation
1. **Clone the Repository:**
   ```sh
   git clone https://github.com/yourusername/job-recommendation-app.git
   cd job-recommendation-app
   ```
2. **Install Dependencies:**
   ```sh
   flutter pub get
   ```
3. **Run the App:**
   ```sh
   flutter run
   ```

## 🔧 Configuration
- Set up Firebase for job data storage.
- Configure **Gemini AI API Key** and **Jobs API Key** from below and update in the application settings.
  ```sh
   https://rapidapi.com/search/Jobs?sortBy=ByTrending
   ```

## 🤝 Contribution
Want to improve this project? Feel free to **fork the repository** and submit a **pull request**!

## 📜 License
This project is licensed under the **MIT License**.

---
🚀 **Developed with Flutter & AI to simplify job search!**

 - MUHAMMAD HUZAIFA LATIF
