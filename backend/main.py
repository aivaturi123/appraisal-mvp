from fastapi import FastAPI
from routes import evaluation
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(evaluation.router)

@app.get("/")
def root():
    return {"message": "Employee Evaluation System API is running"}
