from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
import pandas as pd
import numpy as np
import joblib
import json
import io

# Loading the Model

model = joblib.load("best_model.pkl")

with open("feature_order.json", "r") as f:
    feature_info = json.load(f)

FEATURES = feature_info["features"]
TARGET = feature_info["target"]

# FastAPI App

app = FastAPI(
    title="Education Prediction API",
    description=(
        "Predicts Gross Tertiary Education Enrollment (%) for African "
        "countries from out-of-school rates, completion rates, literacy, "
        "birth rate, and unemployment rate."),
    version="1.0"
)

from fastapi.responses import RedirectResponse

@app.get("/", include_in_schema=False)
def root():
    return RedirectResponse(url="/docs")

# CORS Middleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
)

# Input Model

class PredictionInput(BaseModel):

    OOSR_Pre0Primary_Age_Male: float = Field(..., ge=0, le=100)
    OOSR_Pre0Primary_Age_Female: float = Field(..., ge=0, le=100)
    OOSR_Primary_Age_Male: float = Field(..., ge=0, le=100)
    OOSR_Primary_Age_Female: float = Field(..., ge=0, le=100)
    OOSR_Lower_Secondary_Age_Male: float = Field(..., ge=0, le=100)
    OOSR_Lower_Secondary_Age_Female: float = Field(..., ge=0, le=100)
    OOSR_Upper_Secondary_Age_Male: float = Field(..., ge=0, le=100)
    OOSR_Upper_Secondary_Age_Female: float = Field(..., ge=0, le=100)

    Completion_Rate_Primary_Male: float = Field(..., ge=0, le=100)
    Completion_Rate_Primary_Female: float = Field(..., ge=0, le=100)
    Completion_Rate_Lower_Secondary_Male: float = Field(..., ge=0, le=100)
    Completion_Rate_Lower_Secondary_Female: float = Field(..., ge=0, le=100)
    Completion_Rate_Upper_Secondary_Male: float = Field(..., ge=0, le=100)
    Completion_Rate_Upper_Secondary_Female: float = Field(..., ge=0, le=100)

    Grade_2_3_Proficiency_Reading: float = Field(..., ge=0, le=100)
    Grade_2_3_Proficiency_Math: float = Field(..., ge=0, le=100)

    Primary_End_Proficiency_Reading: float = Field(..., ge=0, le=100)
    Primary_End_Proficiency_Math: float = Field(..., ge=0, le=100)

    Lower_Secondary_End_Proficiency_Reading: float = Field(..., ge=0, le=100)
    Lower_Secondary_End_Proficiency_Math: float = Field(..., ge=0, le=100)

    Youth_15_24_Literacy_Rate_Male: float = Field(..., ge=0, le=100)
    Youth_15_24_Literacy_Rate_Female: float = Field(..., ge=0, le=100)

    Birth_Rate: float = Field(..., ge=0, le=60)

    Gross_Primary_Education_Enrollment: float = Field(..., ge=0, le=200)

    Unemployment_Rate: float = Field(..., ge=0, le=40)

# Prediction Endpoint

@app.post("/predict")
def predict(data: PredictionInput):

    values = data.model_dump()

    df = pd.DataFrame([values])

    df = df[FEATURES]

    prediction = model.predict(df)[0]

    return {
        "Predicted Gross Tertiary Education Enrollment": round(float(prediction), 2)
    }

# Retrain Endpoint

@app.post("/retrain")
def retrain(file: UploadFile = File(...)):

    try:
        if not file.filename.endswith(".csv"):
            raise HTTPException(status_code=400, detail="Please upload a .csv file")

        new_data = pd.read_csv(io.BytesIO(file.file.read()))

        required_cols = set(FEATURES + [TARGET])
        if not required_cols.issubset(new_data.columns):
            missing = required_cols - set(new_data.columns)
            raise HTTPException(
                status_code=422,
                detail=f"Uploaded CSV is missing required columns: {sorted(missing)}"
            )

        existing = pd.read_csv("training_data.csv")
        combined = pd.concat(
            [existing, new_data[list(required_cols)]], ignore_index=True
        ).drop_duplicates()

        X = combined[FEATURES]
        y = combined[TARGET]

        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42
        )

        new_model = RandomForestRegressor(
            n_estimators=300,
            max_depth=6,
            random_state=42
        )

        new_model.fit(X_train, y_train)

        rmse = float(np.sqrt(mean_squared_error(y_test, new_model.predict(X_test))))

        joblib.dump(new_model, "best_model.pkl")
        combined.to_csv("training_data.csv", index=False)

        global model
        model = new_model

        return {
            "status": "success",
            "rows_used": len(combined),
            "test_rmse": round(rmse, 3),
            "message": "Model retrained on combined existing + uploaded data and hot-swapped into the API."
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))