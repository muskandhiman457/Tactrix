import requests
from fastapi import APIRouter

router = APIRouter(
    prefix="/api/football",
    tags=["Football"]
)

RAPIDAPI_HOST = "free-api-live-football-data.p.rapidapi.com"
RAPIDAPI_KEY = "a5eac63245mshc1a65cb950faebfp1c7d8ajsnc48adb31d3ee"

@router.get("/players/search")
def search_football_players(search: str = "m"):
    url = f"https://{RAPIDAPI_HOST}/football-players-search"
    querystring = {"search": search}
    headers = {
        "x-rapidapi-host": RAPIDAPI_HOST,
        "x-rapidapi-key": RAPIDAPI_KEY
    }
    
    response = requests.get(url, headers=headers, params=querystring)
    return response.json()

@router.get("/matches/live")
def get_live_football_matches():
    url = f"https://{RAPIDAPI_HOST}/football-current-live"
    headers = {
        "x-rapidapi-host": RAPIDAPI_HOST,
        "x-rapidapi-key": RAPIDAPI_KEY
    }
    
    response = requests.get(url, headers=headers)
    return response.json()

@router.get("/leagues/popular")
def get_popular_leagues():
    url = f"https://{RAPIDAPI_HOST}/football-popular-leagues"
    headers = {
        "x-rapidapi-host": RAPIDAPI_HOST,
        "x-rapidapi-key": RAPIDAPI_KEY
    }
    
    response = requests.get(url, headers=headers)
    return response.json()

@router.get("/matches/by-date")
def get_matches_by_date(date: str):
    """
    Get all matches for a specific date. 
    Format: YYYYMMDD (e.g., 20241107)
    """
    url = f"https://{RAPIDAPI_HOST}/football-get-matches-by-date"
    querystring = {"date": date}
    headers = {
        "x-rapidapi-host": RAPIDAPI_HOST,
        "x-rapidapi-key": RAPIDAPI_KEY
    }
    
    response = requests.get(url, headers=headers, params=querystring)
    return response.json()

@router.get("/matches/by-league")
def get_matches_by_league(leagueid: str):
    """
    Get all matches for a specific league.
    Provide the league ID (e.g., 42 for Champions League)
    """
    url = f"https://{RAPIDAPI_HOST}/football-get-all-matches-by-league"
    querystring = {"leagueid": leagueid}
    headers = {
        "x-rapidapi-host": RAPIDAPI_HOST,
        "x-rapidapi-key": RAPIDAPI_KEY
    }
    
    response = requests.get(url, headers=headers, params=querystring)
    return response.json()
