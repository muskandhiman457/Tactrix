import requests
import json

headers = {
    "x-rapidapi-host": "free-api-live-football-data.p.rapidapi.com",
    "x-rapidapi-key": "a5eac63245mshc1a65cb950faebfp1c7d8ajsnc48adb31d3ee"
}

try:
    print("Testing football matches...")
    r = requests.get("https://free-api-live-football-data.p.rapidapi.com/football-get-all-matches-by-league", headers=headers, params={"leagueid": "42"}, timeout=10)
    print("Status:", r.status_code)
    data = r.json()
    print("Keys:", data.keys())
    # Save a small sample
    with open("football_sample.json", "w") as f:
        json.dump(data, f, indent=2)
    print("Wrote football_sample.json successfully!")
except Exception as e:
    print("Error:", e)
