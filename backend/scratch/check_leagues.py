import requests
import json

headers = {
    "x-rapidapi-host": "free-api-live-football-data.p.rapidapi.com",
    "x-rapidapi-key": "a5eac63245mshc1a65cb950faebfp1c7d8ajsnc48adb31d3ee"
}

try:
    print("Fetching popular leagues...")
    r = requests.get("https://free-api-live-football-data.p.rapidapi.com/football-popular-leagues", headers=headers, timeout=10)
    print("Status:", r.status_code)
    data = r.json()
    print("Popular leagues:")
    print(json.dumps(data, indent=2))
except Exception as e:
    print("Error:", e)
