import requests

RAPIDAPI_HEADERS = {
    "x-rapidapi-host": "cricbuzz-cricket2.p.rapidapi.com",
    "x-rapidapi-key": "a5eac63245mshc1a65cb950faebfp1c7d8ajsnc48adb31d3ee"
}

match_id = 150964  # New Zealand vs Ireland

url = f"https://cricbuzz-cricket2.p.rapidapi.com/mcenter/v1/{match_id}/teams"
try:
    r = requests.get(url, headers=RAPIDAPI_HEADERS, timeout=10)
    if r.status_code == 200:
        data = r.json()
        print("team1 keys:", list(data["team1"].keys()))
        print("team2 keys:", list(data["team2"].keys()))
        print("team1 name:", data["team1"].get("name"))
        print("team1 shortName:", data["team1"].get("shortName"))
        print("team1 player list keys:", [list(p.keys()) for p in data["team1"].get("player", [])[:2]])
        print("team1 first player details:", data["team1"].get("player", [])[0] if data["team1"].get("player", []) else "none")
except Exception as e:
    print("Error:", e)
