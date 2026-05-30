import requests

RAPIDAPI_HEADERS = {
    "x-rapidapi-host": "cricbuzz-cricket2.p.rapidapi.com",
    "x-rapidapi-key": "a5eac63245mshc1a65cb950faebfp1c7d8ajsnc48adb31d3ee"
}

def _extract_matches(data: dict) -> list:
    matches = []
    for type_match in data.get("typeMatches", []):
        for series in type_match.get("seriesMatches", []):
            wrapper = series.get("seriesAdWrapper")
            if wrapper and wrapper.get("matches"):
                for match in wrapper["matches"]:
                    match["_matchType"] = type_match.get("matchType", "")
                    match["_seriesName"] = wrapper.get("seriesName", "")
                    matches.append(match)
    return matches

print("Fetching live matches...")
try:
    live_resp = requests.get(
        "https://cricbuzz-cricket2.p.rapidapi.com/matches/v1/live",
        headers=RAPIDAPI_HEADERS,
        timeout=10
    )
    live_matches = _extract_matches(live_resp.json())
    print(f"Found {len(live_matches)} live matches.")
    for m in live_matches[:5]:
        info = m.get("matchInfo", {})
        print(f"ID: {info.get('matchId')}, Series: {info.get('seriesName')}, Match: {info.get('team1', {}).get('teamName')} vs {info.get('team2', {}).get('teamName')}, State: {info.get('state')}")
except Exception as e:
    print("Error fetching live matches:", e)

print("\nFetching upcoming matches...")
try:
    upcoming_resp = requests.get(
        "https://cricbuzz-cricket2.p.rapidapi.com/matches/v1/upcoming",
        headers=RAPIDAPI_HEADERS,
        timeout=10
    )
    upcoming_matches = _extract_matches(upcoming_resp.json())
    print(f"Found {len(upcoming_matches)} upcoming matches.")
    for m in upcoming_matches[:5]:
        info = m.get("matchInfo", {})
        print(f"ID: {info.get('matchId')}, Series: {info.get('seriesName')}, Match: {info.get('team1', {}).get('teamName')} vs {info.get('team2', {}).get('teamName')}, State: {info.get('state')}")
except Exception as e:
    print("Error fetching upcoming matches:", e)
