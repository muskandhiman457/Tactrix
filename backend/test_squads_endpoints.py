import requests

RAPIDAPI_HEADERS = {
    "x-rapidapi-host": "cricbuzz-cricket2.p.rapidapi.com",
    "x-rapidapi-key": "a5eac63245mshc1a65cb950faebfp1c7d8ajsnc48adb31d3ee"
}

match_id = 150964  # New Zealand vs Ireland

urls = [
    f"https://cricbuzz-cricket2.p.rapidapi.com/mcenter/v1/{match_id}/squads",
    f"https://cricbuzz-cricket2.p.rapidapi.com/mcenter/v1/{match_id}/teams",
    f"https://cricbuzz-cricket2.p.rapidapi.com/mcenter/v1/{match_id}/players",
    f"https://cricbuzz-cricket2.p.rapidapi.com/mcenter/v1/{match_id}/matchInfo"
]

for url in urls:
    print(f"\nQuerying: {url}")
    try:
        r = requests.get(url, headers=RAPIDAPI_HEADERS, timeout=10)
        print(f"Status: {r.status_code}")
        if r.status_code == 200:
            print("Keys:", list(r.json().keys()))
        else:
            print("Response:", r.text[:200])
    except Exception as e:
        print("Error:", e)
