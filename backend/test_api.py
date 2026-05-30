import requests
import json

headers = {
    "x-rapidapi-host": "cricbuzz-cricket2.p.rapidapi.com",
    "x-rapidapi-key": "a5eac63245mshc1a65cb950faebfp1c7d8ajsnc48adb31d3ee"
}

try:
    print("Testing live matches...")
    r = requests.get("https://cricbuzz-cricket2.p.rapidapi.com/matches/v1/live", headers=headers, timeout=10)
    print("Status:", r.status_code)
    data = r.json()
    print("Keys:", data.keys())
    # Save a small sample
    with open("live_sample.json", "w") as f:
        json.dump(data, f, indent=2)
    print("Wrote live_sample.json successfully!")
except Exception as e:
    print("Error:", e)
