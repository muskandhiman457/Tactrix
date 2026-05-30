import requests

RAPIDAPI_HEADERS = {
    "x-rapidapi-host": "cricbuzz-cricket2.p.rapidapi.com",
    "x-rapidapi-key": "a5eac63245mshc1a65cb950faebfp1c7d8ajsnc48adb31d3ee"
}

match_id = 150964  # New Zealand vs Ireland

endpoints = [
    f"https://cricbuzz-cricket2.p.rapidapi.com/mcenter/v1/{match_id}/scard",
    f"https://cricbuzz-cricket2.p.rapidapi.com/mcenter/v1/{match_id}/comm",
    f"https://cricbuzz-cricket2.p.rapidapi.com/mcenter/v1/{match_id}/leanback"
]

for url in endpoints:
    print(f"\nQuerying: {url}")
    try:
        r = requests.get(url, headers=RAPIDAPI_HEADERS, timeout=10)
        print(f"Status: {r.status_code}")
        if r.status_code == 200:
            data = r.json()
            print("Keys:", list(data.keys()))
            if "scoreCard" in data:
                print("Found scoreCard.")
            if "commentaryList" in data:
                print("Found commentaryList. First comment keys:", list(data["commentaryList"][0].keys()) if data["commentaryList"] else "empty")
            if "miniscore" in data:
                print("Found miniscore. Keys:", list(data["miniscore"].keys()))
                # Print active batsman and bowler details if present in miniscore
                ms = data["miniscore"]
                print("Batsman details:", ms.get("batsman"))
                print("Bowler details:", ms.get("bowler"))
                print("Batting team:", ms.get("battingTeam"))
                print("Bowling team:", ms.get("bowlingTeam"))
        else:
            print("Response:", r.text[:200])
    except Exception as e:
        print("Error:", e)
