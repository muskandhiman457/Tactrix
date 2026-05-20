import requests
from fastapi import APIRouter
from typing import List, Dict

router = APIRouter(
    prefix="/api/cricket",
    tags=["Cricket"]
)

RAPIDAPI_HEADERS = {
    "x-rapidapi-host": "cricbuzz-cricket2.p.rapidapi.com",
    "x-rapidapi-key": "a5eac63245mshc1a65cb950faebfp1c7d8ajsnc48adb31d3ee"
}


def _extract_matches(data: dict) -> list:
    """Flatten all matches from the Cricbuzz typeMatches structure."""
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


@router.get("/matches/live-and-upcoming")
def get_live_and_upcoming_cricket_matches():
    """
    Returns all LIVE + UPCOMING cricket matches merged in one list.
    Filters out completed matches (state == 'Complete').
    """
    all_matches = []

    # Fetch LIVE matches
    try:
        live_resp = requests.get(
            "https://cricbuzz-cricket2.p.rapidapi.com/matches/v1/live",
            headers=RAPIDAPI_HEADERS,
            timeout=10
        )
        live_data = live_resp.json()
        for m in _extract_matches(live_data):
            state = m.get("matchInfo", {}).get("state", "")
            if state.lower() != "complete":
                all_matches.append(m)
    except Exception as e:
        print(f"Error fetching live matches: {e}")

    # Fetch UPCOMING matches
    try:
        upcoming_resp = requests.get(
            "https://cricbuzz-cricket2.p.rapidapi.com/matches/v1/upcoming",
            headers=RAPIDAPI_HEADERS,
            timeout=10
        )
        upcoming_data = upcoming_resp.json()
        for m in _extract_matches(upcoming_data):
            state = m.get("matchInfo", {}).get("state", "")
            # Only include Preview (upcoming) - not Complete
            if state.lower() not in ("complete",):
                all_matches.append(m)
    except Exception as e:
        print(f"Error fetching upcoming matches: {e}")

    return {"status": "success", "matches": all_matches}


@router.get("/matches/live")
def get_live_cricket_matches():
    """Legacy live-only endpoint."""
    try:
        response = requests.get(
            "https://cricbuzz-cricket2.p.rapidapi.com/matches/v1/live",
            headers=RAPIDAPI_HEADERS,
            timeout=10
        )
        data = response.json()
        matches = [
            m for m in _extract_matches(data)
            if m.get("matchInfo", {}).get("state", "").lower() != "complete"
        ]
        return {"status": "success", "matches": matches}
    except Exception as e:
        return {"status": "error", "message": str(e), "matches": []}


@router.get("/matches/upcoming")
def get_upcoming_cricket_matches():
    """Legacy upcoming-only endpoint."""
    try:
        response = requests.get(
            "https://cricbuzz-cricket2.p.rapidapi.com/matches/v1/upcoming",
            headers=RAPIDAPI_HEADERS,
            timeout=10
        )
        data = response.json()
        matches = [
            m for m in _extract_matches(data)
            if m.get("matchInfo", {}).get("state", "").lower() == "preview"
        ]
        return {"status": "success", "matches": matches}
    except Exception as e:
        return {"status": "error", "message": str(e), "matches": []}


@router.get("/match/{match_id}/scorecard")
def get_match_scorecard(match_id: int):
    """
    Fetches the scorecard for a given matchId from Cricbuzz.
    Returns parsed team players with name, role, and basic stats.
    """
    try:
        response = requests.get(
            f"https://cricbuzz-cricket2.p.rapidapi.com/mcenter/v1/{match_id}/scard",
            headers=RAPIDAPI_HEADERS,
            timeout=10
        )
        data = response.json()

        teams = {}
        for innings in data.get("scoreCard", []):
            team_name = innings.get("batTeamDetails", {}).get("batTeamName", "")
            team_short = innings.get("batTeamDetails", {}).get("batTeamSName", "")
            players = []

            # Parse batsmen
            for bat_id, bat in innings.get("batTeamDetails", {}).get("batsmenData", {}).items():
                players.append({
                    "name": bat.get("batName", "Unknown"),
                    "role": "Batter",
                    "number": str(bat.get("batId", "")),
                    "nationality": "International",
                    "stats": f"R: {bat.get('runs', 0)}, B: {bat.get('balls', 0)}, SR: {bat.get('strikeRate', 0)}"
                })

            # Parse bowlers
            bowl_team = innings.get("bowlTeamDetails", {})
            bowl_team_name = bowl_team.get("bowlTeamName", "")
            for bowl_id, bowl in bowl_team.get("bowlersData", {}).items():
                if bowl_team_name not in teams:
                    teams[bowl_team_name] = {"short": bowl_team.get("bowlTeamSName", ""), "players": []}
                teams[bowl_team_name]["players"].append({
                    "name": bowl.get("bowlName", "Unknown"),
                    "role": "Bowler",
                    "number": str(bowl.get("bowlId", "")),
                    "nationality": "International",
                    "stats": f"O: {bowl.get('overs', 0)}, W: {bowl.get('wickets', 0)}, Econ: {bowl.get('economy', 0)}"
                })

            if team_name and players:
                if team_name not in teams:
                    teams[team_name] = {"short": team_short, "players": []}
                # Deduplicate
                existing_names = {p["name"] for p in teams[team_name]["players"]}
                teams[team_name]["players"].extend(
                    p for p in players if p["name"] not in existing_names
                )

        return {"status": "success", "teams": teams}
    except Exception as e:
        return {"status": "error", "message": str(e), "teams": {}}
