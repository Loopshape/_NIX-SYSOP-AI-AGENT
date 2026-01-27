from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List
import asyncio
from .agents import AgentSwarm
from .persistence import init_db, get_soul, save_soul
from .entropy import process_text_entropy

app = FastAPI(title="NEXUS-AI Backend")
swarm = AgentSwarm()

class PromptRequest(BaseModel):
    prompt: str
    context: Optional[str] = ""

@app.on_event("startup")
def startup_event():
    init_db()

@app.get("/")
def read_root():
    return {"status": "NEXUS-AI Online"}

@app.post("/process")
async def process_prompt(request: PromptRequest):
    # Update entropy index with the new prompt
    process_text_entropy(request.prompt)
    
    # Process with swarm
    result = await swarm.process(request.prompt, request.context)
    return result

@app.get("/soul")
def read_soul():
    return {"soul": get_soul("current_identity") or "New NEXUS Soul"}

@app.post("/soul")
def update_soul(identity: str):
    save_soul("current_identity", identity)
    return {"status": "Soul updated"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
