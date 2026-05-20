import requests
from fastapi import APIRouter
from typing import List, Dict

router = APIRouter(
    prefix="/api/cricket",
    tags=["Cricket"]
)

@router.get("/matches/live")
def get_live_cricket_matches():
    # --- YOUR RAPID API INTEGRATION ---
    RAPIDAPI_URL = "https://cricbuzz-cricket2.p.rapidapi.com/matches/v1/live"
    HEADERS = {
        "x-rapidapi-host": "cricbuzz-cricket2.p.rapidapi.com",
        "x-rapidapi-key": "a5eac63245mshc1a65cb950faebfp1c7d8ajsnc48adb31d3ee" 
    }
    response = requests.get(RAPIDAPI_URL, headers=HEADERS)
    data = response.json()
    return data
    # ----------------------------------

    # This is mock data mimicking the expected unified structure
    return {
        "status": "success",
        "data": [
            {
                "id": "cric_101",
                "team1": {"name": "Mumbai Indians", "shortName": "MI", "score": "185/4 (18.2)"},
                "team2": {"name": "Chennai Super Kings", "shortName": "CSK", "score": "Yet to bat"},
                "status": "Live - 1st Innings",
                "venue": "Wankhede Stadium"
            }
        ]
    }

@router.get("/matches/upcoming")
def get_upcoming_cricket_matches():
    # TODO: Integrate User's Cricket API here
    return {
        "status": "success",
        "data": [
            {
                "id": "cric_102",
                "team1": {"name": "Royal Challengers", "shortName": "RCB"},
                "team2": {"name": "Delhi Capitals", "shortName": "DC"},
                "status": "Starts in 4h 30m",
                "venue": "Chinnaswamy Stadium"
            }
        ]
    }
