import requests

RAPIDAPI_HEADERS = {
    "x-rapidapi-host": "cricbuzz-cricket2.p.rapidapi.com",
    "x-rapidapi-key": "a5eac63245mshc1a65cb950faebfp1c7d8ajsnc48adb31d3ee"
}

match_id = 150964

def test_build():
    try:
        # 1. Fetch teams
        print("Fetching teams...")
        teams_url = f"https://cricbuzz-cricket2.p.rapidapi.com/mcenter/v1/{match_id}/teams"
        teams_resp = requests.get(teams_url, headers=RAPIDAPI_HEADERS, timeout=10)
        teams_data = teams_resp.json()
        
        team1_data = teams_data.get("team1", {})
        team2_data = teams_data.get("team2", {})
        
        team1_name = team1_data.get("team", {}).get("teamname", "Team 1")
        team1_short = team1_data.get("team", {}).get("teamsname", "T1")
        team2_name = team2_data.get("team", {}).get("teamname", "Team 2")
        team2_short = team2_data.get("team", {}).get("teamsname", "T2")
        
        playing_xi1 = []
        bench1 = []
        for cat_group in team1_data.get("players", []):
            cat = cat_group.get("category", "")
            players = cat_group.get("player", [])
            if cat == "playing XI":
                playing_xi1.extend(players)
            elif cat == "bench":
                bench1.extend(players)
                
        playing_xi2 = []
        bench2 = []
        for cat_group in team2_data.get("players", []):
            cat = cat_group.get("category", "")
            players = cat_group.get("player", [])
            if cat == "playing XI":
                playing_xi2.extend(players)
            elif cat == "bench":
                bench2.extend(players)
                
        print(f"Team 1 ({team1_name}): {len(playing_xi1)} playing, {len(bench1)} bench")
        print(f"Team 2 ({team2_name}): {len(playing_xi2)} playing, {len(bench2)} bench")

        # 2. Fetch scorecard
        print("Fetching scorecard...")
        scard_url = f"https://cricbuzz-cricket2.p.rapidapi.com/mcenter/v1/{match_id}/scard"
        scard_resp = requests.get(scard_url, headers=RAPIDAPI_HEADERS, timeout=10)
        scard_data = scard_resp.json()
        
        stats_map = {}
        for innings in scard_data.get("scoreCard", []):
            # Batsmen
            for bat_id, bat in innings.get("batTeamDetails", {}).get("batsmenData", {}).items():
                runs = bat.get("runs", 0)
                balls = bat.get("balls", 0)
                sr = bat.get("strikeRate", 0)
                stats_map[str(bat_id)] = f"Runs: {runs}, Balls: {balls}, Strike Rate: {sr}"
            # Bowlers
            bowl_team = innings.get("bowlTeamDetails", {})
            for bowl_id, bowl in bowl_team.get("bowlersData", {}).items():
                overs = bowl.get("overs", 0)
                wkts = bowl.get("wickets", 0)
                econ = bowl.get("economy", 0)
                stats_map[str(bowl_id)] = f"Overs: {overs}, Wickets: {wkts}, Economy: {econ}"

        # 3. Fetch liveState (leanback)
        print("Fetching leanback...")
        lean_url = f"https://cricbuzz-cricket2.p.rapidapi.com/mcenter/v1/{match_id}/leanback"
        lean_resp = requests.get(lean_url, headers=RAPIDAPI_HEADERS, timeout=10)
        lean_data = lean_resp.json()
        ms = lean_data.get("miniscore", {})
        
        live_state = None
        if ms:
            target = ms.get("target", 0)
            batting_team_score = ms.get("batteamscore", {}).get("teamscore", 0)
            runsNeeded = max(0, target - batting_team_score) if target > 0 else 0
            
            active_batsmen = []
            for key, is_striker in [("batsmanstriker", True), ("batsmannonstriker", False)]:
                b = ms.get(key)
                if b:
                    active_batsmen.append({
                        "name": b.get("name", "Unknown"),
                        "playerId": b.get("id"),
                        "runs": b.get("runs", 0),
                        "ballsFaced": b.get("balls", 0),
                        "fours": b.get("fours", 0),
                        "sixes": b.get("sixes", 0),
                        "isStriker": is_striker
                    })
                    
            active_bowler = {}
            b = ms.get("bowlerstriker")
            if b:
                active_bowler = {
                    "name": b.get("name", "Unknown"),
                    "playerId": b.get("id"),
                    "overs": float(b.get("overs", 0.0)) if b.get("overs") else 0.0,
                    "maidens": b.get("maidens", 0),
                    "runsConceded": b.get("runs", 0),
                    "wickets": b.get("wickets", 0),
                    "currentOverStats": [str(c) for c in ms.get("curovsstats", [])] if isinstance(ms.get("curovsstats"), list) else [str(c) for c in ms.get("curovsstats", "").split() if c]
                }
                
            live_state = {
                "inningsNo": ms.get("inningsnbr", 1),
                "battingTeamId": ms.get("batteamscore", {}).get("teamid"),
                "bowlingTeamId": None,
                "target": target,
                "runsNeeded": runsNeeded,
                "ballsRemaining": max(0, ms.get("ballsrem", 0)),
                "requiredRunRate": ms.get("rrr", 0.0),
                "currentRunRate": ms.get("crr", 0.0),
                "activeBatsmen": active_batsmen,
                "activeBowler": active_bowler
            }

        def format_player(p, is_bench=False):
            p_id = str(p.get("id"))
            role = p.get("role", "Player")
            p_stats = stats_map.get(p_id)
            if not p_stats:
                if is_bench:
                    p_stats = "Did Not Play"
                elif "bowler" in role.lower():
                    p_stats = "Did Not Bowl"
                else:
                    p_stats = "Did Not Bat"
                    
            return {
                "name": p.get("name", "Unknown"),
                "role": role,
                "number": p_id,
                "imageId": str(p.get("faceimageid", p_id)),
                "nationality": "International",
                "stats": p_stats
            }

        teams = {
            team1_name: {
                "short": team1_short,
                "playingXI": [format_player(p) for p in playing_xi1],
                "bench": [format_player(p, is_bench=True) for p in bench1],
                "players": [format_player(p) for p in playing_xi1] + [format_player(p, is_bench=True) for p in bench1]
            },
            team2_name: {
                "short": team2_short,
                "playingXI": [format_player(p) for p in playing_xi2],
                "bench": [format_player(p, is_bench=True) for p in bench2],
                "players": [format_player(p) for p in playing_xi2] + [format_player(p, is_bench=True) for p in bench2]
            }
        }
        
        final_result = {
            "status": "success",
            "liveState": live_state,
            "teams": teams
        }
        print("Success! Final result keys:", list(final_result.keys()))
        print("Live state details:", final_result["liveState"])
        print("First player formatted stats:", final_result["teams"][team1_name]["playingXI"][0])

    except Exception as e:
        print("Error during build:", e)

if __name__ == "__main__":
    test_build()
