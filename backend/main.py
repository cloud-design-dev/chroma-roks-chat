from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, List, Optional
import uvicorn
import os
import logging
import json
from pathlib import Path
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np
from data_loader import load_facts_from_file

app = FastAPI(title="Animal Facts Chat API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Simple in-memory vector database using scikit-learn
class SimpleVectorDB:
    def __init__(self):
        self.facts = []
        self.vectorizer = TfidfVectorizer(stop_words='english', max_features=1000)
        self.vectors = None
        self.fact_counter = 0
        
    def add_facts(self, facts_data: List[Dict]):
        """Add facts to the database"""
        for fact_data in facts_data:
            self.facts.append({
                'id': f"fact_{self.fact_counter}",
                'text': fact_data['fact'],
                'animal': fact_data['animal']
            })
            self.fact_counter += 1
        
        # Recompute vectors when facts are added
        self._compute_vectors()
        
    def add_single_fact(self, animal: str, fact: str):
        """Add a single fact"""
        self.facts.append({
            'id': f"fact_{self.fact_counter}",
            'text': fact,
            'animal': animal.lower()
        })
        self.fact_counter += 1
        self._compute_vectors()
        
    def _compute_vectors(self):
        """Compute TF-IDF vectors for all facts"""
        if not self.facts:
            return
            
        texts = [fact['text'] for fact in self.facts]
        self.vectors = self.vectorizer.fit_transform(texts)
        
    def search(self, query: str, top_k: int = 3):
        """Search for similar facts"""
        if not self.facts or self.vectors is None:
            return []
            
        query_vector = self.vectorizer.transform([query])
        similarities = cosine_similarity(query_vector, self.vectors)[0]
        
        # Get top-k most similar facts
        top_indices = np.argsort(similarities)[::-1][:top_k]
        
        results = []
        for idx in top_indices:
            if similarities[idx] > 0.1:  # Minimum similarity threshold
                results.append({
                    'fact': self.facts[idx],
                    'similarity': float(similarities[idx])
                })
                
        return results
        
    def get_stats(self):
        """Get count of facts by animal"""
        stats = {}
        for fact in self.facts:
            animal = fact['animal']
            stats[animal] = stats.get(animal, 0) + 1
        return stats
        
    def reset(self):
        """Reset database to empty state"""
        self.facts = []
        self.vectors = None
        self.fact_counter = 0

# Initialize the vector database
vector_db = SimpleVectorDB()

def initialize_database():
    """Initialize database with default facts"""
    facts = load_facts_from_file()
    vector_db.add_facts(facts)
    logger.info(f"Loaded {len(facts)} animal facts into database")

# Initialize database on startup
initialize_database()

class ChatQuery(BaseModel):
    query: str

class ChatResponse(BaseModel):
    response: str
    sources: Optional[List[str]] = None

class AddFactRequest(BaseModel):
    animal: str
    fact: str

@app.get("/api/stats")
async def get_stats() -> Dict[str, int]:
    """Get count of facts by animal type"""
    try:
        return vector_db.get_stats()
    except Exception as e:
        logger.error(f"Failed to get stats: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to get stats: {str(e)}")

@app.post("/api/chat")
async def chat(query: ChatQuery) -> ChatResponse:
    """Query animal facts using vector similarity search"""
    try:
        # Search for relevant facts
        results = vector_db.search(query.query, top_k=3)
        
        if not results:
            stats = vector_db.get_stats()
            available_animals = ", ".join(sorted(stats.keys())) if stats else "various animals"
            return ChatResponse(
                response=f"I don't have specific information about that. Try asking about: {available_animals}!",
                sources=[]
            )
        
        # Format response with the most relevant facts
        facts = []
        sources = []
        for result in results:
            fact_data = result['fact']
            similarity = result['similarity']
            animal = fact_data['animal']
            fact_text = fact_data['text']
            
            facts.append(f"{animal.title()}: {fact_text}")
            sources.append(f"{animal} (relevance: {similarity:.2f})")
        
        response = "Here's what I know:\n\n" + "\n\n".join(facts)
        return ChatResponse(response=response, sources=sources)
        
    except Exception as e:
        logger.error(f"Query failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Query failed: {str(e)}")

@app.delete("/api/reset")
async def reset_database():
    """Reset database to initial state with base facts only"""
    try:
        vector_db.reset()
        initialize_database()
        
        logger.info("Database reset to initial state")
        return {"message": "Database reset successfully", "facts_count": len(vector_db.facts)}
    except Exception as e:
        logger.error(f"Failed to reset database: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to reset database: {str(e)}")

@app.post("/api/add_fact")
async def add_fact(request: AddFactRequest):
    """Add a new animal fact to the database with duplicate detection"""
    try:
        # Check for duplicate facts
        existing_facts = [fact for fact in vector_db.facts 
                         if fact['animal'].lower() == request.animal.lower() 
                         and fact['text'].lower().strip() == request.fact.lower().strip()]
        
        if existing_facts:
            logger.info(f"Fact already exists for {request.animal}: {request.fact[:50]}...")
            return {"message": f"Fact already exists for {request.animal}", "duplicate": True}
        
        vector_db.add_single_fact(request.animal, request.fact)
        
        logger.info(f"Added new fact for {request.animal}: {request.fact[:50]}...")
        return {"message": f"Added fact for {request.animal}", "id": f"fact_{vector_db.fact_counter-1}"}
    except Exception as e:
        logger.error(f"Failed to add fact: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to add fact: {str(e)}")

@app.on_event("startup")
async def startup_event():
    """Log startup information"""
    total_facts = len(vector_db.facts)
    logger.info(f"Animal Facts API started with {total_facts} facts in database")

@app.delete("/api/reset")
async def reset_database():
    """Reset database to initial state (useful for demo purposes)"""
    try:
        vector_db.reset()
        initialize_database()
        
        logger.info("Database reset to initial state")
        return {"message": "Database reset successfully", "facts_count": len(vector_db.facts)}
    except Exception as e:
        logger.error(f"Failed to reset database: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to reset database: {str(e)}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")