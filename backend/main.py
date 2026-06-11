from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import cricket, analysis, football, sports, community, kabaddi

app = FastAPI(
    title="Multi-Sport Analytics API",
    description="Backend API for the Multi-Sport Analytics and Community App",
    version="1.0.0"
)

# CORS config
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # For development, allow all
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(cricket.router)
app.include_router(analysis.router)
app.include_router(football.router)
app.include_router(sports.router)
app.include_router(community.router)
app.include_router(kabaddi.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to the Multi-Sport Analytics API"}

@app.get("/health")
@app.head("/health")
def health_check():
    return {"status": "ok"}
