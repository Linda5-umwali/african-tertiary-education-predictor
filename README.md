# African Tertiary Education Enrollment Predictor

Predicts a country's **Gross Tertiary Education Enrollment (%)** from
education-pipeline indicators (out-of-school rates, completion rates,
literacy, birth rate, unemployment), scoped to **African countries**.

**Mission:** identify where students are lost from the basic-education
pipeline before ever reaching university, in African contexts. 
This will help in the research about youth unemployment in africa.

- **Live API (Swagger UI):** https://african-tertiary-education-predictor.onrender.com/docs
- **Demo video:** [https://youtu.be/jbW2H9bkr4E]

### Repo structure
```
summative/
├── linear_regression/
│   ├── multivariate.ipynb      # EDA, feature engineering, model training/comparison
│   └── Global_Education.csv    # Original dataset (202 countries, filtered to 54 African in-notebook)
├── API/
│   ├── main.py                 # FastAPI app: /predict, /retrain, CORS, Pydantic validation
│   ├── best_model.pkl          # Trained model
│   ├── feature_order.json      # Feature order + target used at training time
│   ├── training_data.csv       # Training set (grows via /retrain)
│   └── requirements.txt
├── FlutterApp/
│   ├── lib/main.dart           # Single-page app: form, Predict button, result/error display
│   └── pubspec.yaml
pyproject.toml
```

### Dataset & scope
- Source: Global_Education.csv (202 countries)
- Filtered to the **54 African countries** present in the
  data before any cleaning or modeling. Global rows were never used
  to train the model
- There was no dropping rows with missing/zero target, **54 African
  countries** remain in the final training set

### Task 1: Regression (see `summative/linear_regression/multivariate.ipynb`)
- Target: `Gross_Tertiary_Education_Enrollment`
- Cleaned data, engineered features, standardized where applicable
- Compared multiple regression algorithms (Linear Regression, Ridge,
  Random Forest, Decision Tree) plus a from-scratch gradient descent
  implementation with train/test loss curves
- Best model saved to `best_model.pkl`

### Task 2: API (see `summative/API/`)
- `POST /predict` Pydantic-validated inputs (typed, range-constrained)
- `POST /retrain` upload a CSV to retrain and hot-swap the model
- CORS configured for public, credential-free access (GET/POST only)
- Deployed on Render; Swagger UI publicly available at `/docs`

### Task 3: Flutter app (see `summative/FlutterApp/`)
- Single page: one text field per model feature, a **Predict** button,
  and a result/error display area
- Calls the deployed Render API's `/predict` endpoint directly

### Run locally

**API:**
```bash
cd summative/API
pip install -r requirements.txt
uvicorn main:app --reload
```
Visit `http://127.0.0.1:8000/docs`

**Flutter app:**
```bash
cd summative/FlutterApp
flutter pub get
flutter run
```
And dont forget to Set your deployed API URL in `lib/main.dart` before running.

### Author 
Linda Umwali
