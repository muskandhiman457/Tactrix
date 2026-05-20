import requests
from fastapi import APIRouter

router = APIRouter(
    prefix="/api/sports",
    tags=["Sports Information"]
)

SOFASCORE_HOST = "sofascore.p.rapidapi.com"
RAPIDAPI_KEY = "a5eac63245mshc1a65cb950faebfp1c7d8ajsnc48adb31d3ee"

@router.get("/popular")
def get_popular_sports(country: str = "GB"):
    """
    Retrieves the list of popular sports for a given country using the Sofascore API.
    """
    url = "https://sofascore.p.rapidapi.com/sports/list"
    querystring = {"countryCode": country}
    headers = {
        "x-rapidapi-host": SOFASCORE_HOST,
        "x-rapidapi-key": RAPIDAPI_KEY,
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.get(url, headers=headers, params=querystring)
        if response.status_code == 200:
            return response.json()
        else:
            return {"error": f"Failed to fetch data: {response.status_code}", "detail": response.text}
    except Exception as e:
        return {"error": "An error occurred", "detail": str(e)}
