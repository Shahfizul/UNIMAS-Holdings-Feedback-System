# Suggestify - UNIMAS Holdings Feedback System

> **Group:** G02_T22  
> **Course:** TMA3084 Software Engineering Laboratory

## 📋 Project Overview

**UNIMAS Holdings Feedback System** is a comprehensive mobile application designed to streamline the facility maintenance and feedback process for UNIMAS Holdings. 

Traditionally, the feedback process relied on manual Customer Complaint Forms (CCF), which were inefficient, slow, and lacked tracking capabilities. Suggestify digitizes this workflow, providing real-time tracking, automated priority analysis, and efficient task assignment.

## 🚀 Key Features

The system caters to three distinct user roles as defined in our User Manual:

### 👤 Resident (Students/Staff)
* **Dashboard:** View active complaints, history logs, and personal suggestions in organized tabs.
* **Report Issues:** Submit complaints with **Photo & Video evidence**, building location, and detailed descriptions.
* **Track Status:** Real-time updates (Pending → In Progress → Resolved).
* **Smart Suggestions:** Submit ideas for campus improvement with category tags.
* **Feedback:** Rate maintenance services and leave reviews upon job completion.

### 🛠️ Maintainer (Staff)
* **Work Portal:** Personalized dashboard showing "Active Jobs" (In Progress/Pending Verification) vs. "Work History".
* **Job Details:** View priority levels (High/Medium/Low), resident contact info, and specific location.
* **Workflow:** Update status from "In Progress" to "Pending Verification" or "Resolved".
* **Completion Reports:** Submit findings and "Action Taken" reports to close jobs.

### 🛡️ Admin
* **Dashboard:** View analytics, KPIs, and complaint statistics.
* **Task Assignment:** Validate complaints and assign specific Maintainers.
* **User Management:** Approve or reject new resident registrations.
* **Priority Analysis:** AI-powered analysis to flag critical issues (e.g., Fire/Safety).

## 🏗️ Architecture & Tech Stack

This project utilizes a **MVC (Model-View-Controller) Architecture** ensuring maintainability and scalability.

* **Frontend:** [Flutter](https://flutter.dev/) (Dart) - Cross-platform mobile UI.
* **Backend & Database:** [Firebase](https://firebase.google.com/)
    * **Authentication:** Secure user login and role management.
    * **Cloud Firestore:** Real-time NoSQL database.
    * **Cloud Storage:** Hosting for evidence photos and videos.
* **Intelligent Middleware:**
    * **Cloud Functions:** Middleware for logic processing.
    * **Google Cloud Natural Language API:** Provides NLP capabilities for analyzing complaint severity and priority.

## 👥 Meet the Team (G02_T22)

| Name | Matric No. | Role |
| :--- | :--- | :--- |
| **Lee Hao Ming** | 99451 | Team Leader |
| **Isaac Shagal Anak Tinggal** | 99176 | Quality Manager |
| **Javin Sim Chuin Cai** | 97468 | Development Manager |
| **Mohamad Shahfizul Bin Mohd Suhaimi** | 99749 | Support Manager |
| **Neasthy Laade** | 97625 | Planning Manager |

## 🏁 Getting Started

To run this project locally, follow these steps:

### Prerequisites
* Flutter SDK installed.
* A physical device or Android Emulator.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Shahfizul/UNIMAS-Holdings-Feedback-System.git
    ```
2.  **Navigate to the project directory:**
    ```bash
    cd UNIMAS-Holdings-Feedback-System
    ```
3.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
4.  **Run the application:**
    ```bash
    flutter run
    ```

4.  **Build APK (For Android):**
    ```bash
    flutter build apk
    ```
    *Output location: build/app/outputs/flutter-apk/app-release.apk
    
---
*Developed for UNIMAS Holdings Sdn Bhd*
