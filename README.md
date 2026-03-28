# 🚍 RidePulse – Smart Public Transport Management System

## 📌 Overview
**RidePulse** is a smart, data-driven public transportation management system designed to improve efficiency, passenger experience, and operational control in bus services.

It integrates **machine learning, real-time tracking, and management tools** to optimize routes, predict crowd levels, and enhance decision-making for passengers, staff, bus owners, and authorities.

---

## 🎯 Key Features

### 🧠 AI & Data-Driven Features
- 📊 **Crowd Prediction System**  
  Predict passenger demand using machine learning models.

- 🛣️ **Route Optimization**  
  Optimize routes based on demand and traffic conditions.

---

### 📱 Passenger Features
- 🛰️ **Live Bus Tracking**  
  Track bus location in real-time.

- 👥 **Live Crowd Level Monitoring**  
  View crowd levels (Low / Medium / High) before boarding.

- 📊 **Crowd Prediction**  
  Check expected crowd levels for upcoming trips.

- 📝 **Complaint Management System**  
  Submit complaints and feedback directly through the app.

---

### 👨‍💼 Management Features
- 👥 **Staff Management System**  
  Manage drivers and conductors.

- 📅 **Duty Roster System**  
  Assign and manage staff schedules.

- 💰 **Fare Control (Authority Level)**  
  Authorities can update fares dynamically.

---

### 🚌 Operational Features
- 📍 **Trip Monitoring System**  
  Track active trips and their status.

- 💰 **Revenue Tracking**  
  Analyze trip-based income.

- 🧾 **Ticket Management System**  
  Digital ticket handling.

---

### 🔐 Authentication
- 📱 Login using mobile number (OTP-based)  
- 🔐 JWT-based authentication  
- 👥 Role-based access:
  - Passenger  
  - Staff  
  - Bus Owner  
  - Authority  

---

## 🏗️ System Architecture



Flutter App (Passenger + Staff)
↓
Spring Boot Backend (REST API)
↓
PostgreSQL Database
↓
Python ML Microservice (Crowd Prediction)



---

## 🛠️ Tech Stack

### 💻 Frontend
- Flutter (Dart)

### ⚙️ Backend
- Java Spring Boot  
- Spring Data JPA  
- REST APIs  

### 🗄️ Database
- PostgreSQL  

### 🤖 AI / ML Service
- Python (Flask / FastAPI)  
- Scikit-learn  
- Feature Engineering  

### 🐳 DevOps
- Docker (for ML service)

### 🔐 Security
- JWT Authentication

---

## 📂 Project Structure



ridepulse/
│
├── backend/                  # Spring Boot API
│   ├── controller/
│   ├── service/
│   ├── repository/
│   ├── entity/
│   └── dto/
│
├── frontend/                 # Flutter mobile app
│   └── flutter_app/
│
├── predict_service/          # ML Microservice (Python)
│   ├── app.py                # API entry point
│   ├── config.py             # Configuration
│   ├── feature_builder.py    # Feature engineering
│   ├── model_loader.py       # Load ML model
│   └── Dockerfile            # Container setup
│
└── database/
└── migrations/           # SQL migration scripts



---

## 🚀 Getting Started

### 🔧 Backend Setup


cd backend
./mvnw spring-boot:run



---

### 📱 Frontend Setup


cd frontend
flutter pub get
flutter run



---

### 🤖 Prediction Service Setup


cd predict_service
pip install -r requirements.txt
python app.py



#### Using Docker


docker build -t predict-service .
docker run -p 5000:5000 predict-service


---

### 🗄️ Database Setup
1. Create PostgreSQL database  
2. Run migration scripts  
3. Configure `application.properties`  

---

## 🔄 System Workflow

1. Passenger opens the app  
2. Requests bus details or crowd level  
3. Backend processes request  
4. Backend calls ML microservice  
5. ML model predicts crowd level  
6. Response sent back to user  

---

## 📊 Modules

- Passenger Management  
- Staff & Duty Roster Management  
- Bus & Route Management  
- Ticketing System  
- Revenue Management  
- Complaint Management  
- Trip Monitoring  
- Crowd Prediction System  

---

## 🎓 Academic Purpose

Developed as part of:

**BSc (Hons) Business Information Systems**  
University of Sri Jayewardenepura  


---

## 🔮 Future Enhancements

- 📡 Advanced GPS tracking  
- 💳 Digital payment integration  
- 🔔 Real-time notifications  
- 📊 Advanced analytics dashboard  
- 🤖 Improved AI prediction models  

---

## 📄 License

This project is developed for educational purposes only.
