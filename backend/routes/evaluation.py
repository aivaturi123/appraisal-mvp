from fastapi import APIRouter, Request
from firebase_config import db
import httpx
import os


router = APIRouter()

@router.post("/submit-evaluation")
async def submit_evaluation(request: Request):
    data = await request.json()
    doc_ref = db.collection("evaluations").document()
    doc_ref.set(data)
    return {"message": "Evaluation submitted", "id": doc_ref.id}

@router.post("/generate-feedback")
async def generate_feedback(request: Request):
    data = await request.json()

    prompt = f"""
You are an HR assistant. Based on the following self-evaluation, write a brief summary of:
1. The employee's top strength
2. One area for improvement
3. A motivational message

Input:
Name: {data.get("name")}
Work Quality: {data.get("work_quality")}
Collaboration: {data.get("collaboration")}
Skills Developed: {data.get("skill_dev")}
Goals: {data.get("goals")}
"""

    headers = {
        "Authorization": f"Bearer {os.getenv('OPENROUTER_API_KEY')}",
        "Content-Type": "application/json",
    }

    payload = {
        "model": "openai/gpt-3.5-turbo",
        "messages": [
            {"role": "system", "content": "You are a helpful HR assistant."},
            {"role": "user", "content": prompt}
        ]
    }

    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers=headers,
            json=payload
        )

    result = response.json()
    feedback = result["choices"][0]["message"]["content"]
    return {"feedback": feedback.strip()}