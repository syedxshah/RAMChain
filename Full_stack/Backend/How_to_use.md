# How to Run the FastAPI Application

This guide covers how to set up your virtual environment, install the FastAPI dependencies, and launch the server using Uvicorn.

## 📦 Dependencies

Make sure your `requirements.txt` file contains the following lines:
```text
fastapi
uvicorn
```

---

## ⚡ Quick Start Guide

### 🪟 Windows Setup

1. **Create & activate the environment:**
   ```bash
   python -m venv .venv
   .venv\Scripts\activate
   ```
2. **Install FastAPI and Uvicorn:**
   ```bash
   pip install -r requirements.txt
   ```
3. **Launch the server:**
   ```bash
   uvicorn main:app --reload
   ```

### 🍏 macOS & 🐧 Linux Setup

1. **Create & activate the environment:**
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   ```
2. **Install FastAPI and Uvicorn:**
   ```bash
   pip install -r requirements.txt
   ```
3. **Launch the server:**
   ```bash
   uvicorn main:app --reload
   ```

---

## 🔍 Understanding the Run Command

The command `uvicorn main:app --reload` consists of three parts:
* **`main`**: The name of your Python file (e.g., `main.py`).
* **`app`**: The specific FastAPI instance variable created inside that file (`app = FastAPI()`).
* **`--reload`**: Enables auto-restart so the server updates instantly whenever you save changes to your code.

## 🌐 Accessing the App

Once Uvicorn starts, open your web browser and navigate to:
* **Live Application:** `http://127.0.0.1:8000`
* **Interactive API Documentation (Swagger UI):** `http://127.0.0`

## 🛑 Stop the Server

To shut down the Uvicorn server, press **`Ctrl + C`** in your terminal, then type `deactivate` to exit the virtual environment.
