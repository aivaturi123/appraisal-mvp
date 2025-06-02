from fastapi import APIRouter, Request, HTTPException
from firebase_config import db
import httpx
import os

router = APIRouter()

@router.post("/submit-evaluation")
async def submit_evaluation(request: Request):
    data = await request.json()
    try:
        doc_ref = db.collection("evaluations").document()
        doc_ref.set(data)
        return {"message": "Evaluation submitted", "id": doc_ref.id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/generate-feedback")
async def generate_feedback(request: Request):
    print("📥 /generate-feedback called")
    data = await request.json()

    summary = data.get("summary", {})
    scores = data.get("scores", {})
    comments = data.get("comments", {})
    swot = data.get("swot", {})
    name = data.get("name", "Employee")

    prompt = f"""
You are an experienced HR performance coach.

Based on the self-evaluation below, provide a plain-text, professional, and friendly performance summary for the employee. 
Do not use markdown, bullet points, or any symbols like *, #, -, etc.

=== EMPLOYEE INPUT ===
Name: {name}

Performance Scorecard (Scores & Comments):
{chr(10).join([f"{k}: Score {scores.get(k, '-')}, Comment: {comments.get(k, 'N/A')}" for k in scores])}

SWOT Analysis:
Strengths: {swot.get("strengths", "")}
Weaknesses: {swot.get("weaknesses", "")}
Opportunities: {swot.get("opportunities", "")}
Threats: {swot.get("threats", "")}

Summary:
What Went Well: {summary.get("whatWentWell", "")}
Areas to Power Up: {summary.get("powerUp", "")}
Next Steps Requested: {summary.get("nextSteps", "")}

=== OUTPUT FORMAT ===

Top Strength:
[Explain clearly in one paragraph.]

Area for Growth:
[Explain in one paragraph.]

Motivational Note:
[A short, uplifting message.]

Next Steps (2 Practical Tips):
[Two clear, numbered sentences suggesting next steps.]

Please keep the output professional and clean — no emojis, markdown, special symbols, or non-ASCII characters.
"""


    headers = {
        "Authorization": f"Bearer {os.getenv('OPENROUTER_API_KEY')}",
        "Content-Type": "application/json",
    }

    payload = {
        "model": "openai/gpt-3.5-turbo",
        "messages": [
            {"role": "system", "content": "You are a helpful and motivational HR performance coach."},
            {"role": "user", "content": prompt}
        ]
    }

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers=headers,
                json=payload,
                timeout=30.0
            )

            if response.status_code != 200:
                raise HTTPException(status_code=500, detail="Failed to fetch AI feedback.")

            result = response.json()
            feedback = result.get("choices", [{}])[0].get("message", {}).get("content", "")

            if not feedback:
                raise HTTPException(status_code=500, detail="Empty feedback received.")

            return {"feedback": feedback.strip()}

        except Exception as e:
            return {
                "feedback": "⚠️ AI feedback generation failed. Please try again later.",
                "error": str(e)
            }
