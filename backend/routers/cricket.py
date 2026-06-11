import os
import requests
from fastapi import APIRouter, Response
from fastapi.responses import FileResponse
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


MOCK_IPL_MATCHES = [
    {
        "_matchType": "T20",
        "_seriesName": "Indian Premier League 2026",
        "matchInfo": {
            "matchId": 99001,
            "seriesId": 999,
            "seriesName": "Indian Premier League 2026",
            "matchDesc": "Final",
            "matchFormat": "T20",
            "startDate": 1779976800000,
            "endDate": 1779989400000,
            "state": "Live",
            "status": "CSK need 12 runs off 6 balls",
            "team1": {
                "teamId": 1,
                "teamName": "Chennai Super Kings",
                "teamSName": "CSK",
                "imageId": 1001
            },
            "team2": {
                "teamId": 2,
                "teamName": "Mumbai Indians",
                "teamSName": "MI",
                "imageId": 1002
            },
            "venueInfo": {
                "ground": "Wankhede Stadium",
                "city": "Mumbai"
            }
        },
        "liveState": {
            "inningsNo": 2,
            "battingTeamId": 1,
            "bowlingTeamId": 2,
            "target": 183,
            "runsNeeded": 12,
            "ballsRemaining": 6,
            "requiredRunRate": 12.0,
            "currentRunRate": 9.0,
            "activeBatsmen": [
                {
                    "name": "MS Dhoni",
                    "playerId": 1001,
                    "runs": 28,
                    "ballsFaced": 12,
                    "fours": 1,
                    "sixes": 3,
                    "isStriker": True
                },
                {
                    "name": "Ravindra Jadeja",
                    "playerId": 1003,
                    "runs": 15,
                    "ballsFaced": 10,
                    "fours": 0,
                    "sixes": 1,
                    "isStriker": False
                }
            ],
            "activeBowler": {
                "name": "Jasprit Bumrah",
                "playerId": 1014,
                "overs": 3.0,
                "maidens": 0,
                "runsConceded": 22,
                "wickets": 2,
                "currentOverStats": [".", "6", "W", "1", "4", "1"]
            }
        },
        "matchScore": {
            "team1Score": {
                "inngs1": {
                    "inningsId": 1,
                    "runs": 171,
                    "wickets": 4,
                    "overs": 19.0
                }
            },
            "team2Score": {
                "inngs1": {
                    "inningsId": 2,
                    "runs": 182,
                    "wickets": 6,
                    "overs": 20.0
                }
            }
        }
    },
    {
        "_matchType": "T20",
        "_seriesName": "Indian Premier League 2026",
        "matchInfo": {
            "matchId": 99002,
            "seriesId": 999,
            "seriesName": "Indian Premier League 2026",
            "matchDesc": "Qualifier 2",
            "matchFormat": "T20",
            "startDate": 1780063200000,
            "endDate": 1780075800000,
            "state": "Preview",
            "status": "Upcoming Match",
            "team1": {
                "teamId": 3,
                "teamName": "Royal Challengers Bengaluru",
                "teamSName": "RCB",
                "imageId": 1003
            },
            "team2": {
                "teamId": 4,
                "teamName": "Kolkata Knight Riders",
                "teamSName": "KKR",
                "imageId": 1004
            },
            "venueInfo": {
                "ground": "M. Chinnaswamy Stadium",
                "city": "Bengaluru"
            }
        }
    },
    {
        "_matchType": "T20",
        "_seriesName": "Indian Premier League 2026",
        "matchInfo": {
            "matchId": 99003,
            "seriesId": 999,
            "seriesName": "Indian Premier League 2026",
            "matchDesc": "Eliminator",
            "matchFormat": "T20",
            "startDate": 1780149600000,
            "endDate": 1780162200000,
            "state": "Preview",
            "status": "Upcoming Match",
            "team1": {
                "teamId": 5,
                "teamName": "Sunrisers Hyderabad",
                "teamSName": "SRH",
                "imageId": 1005
            },
            "team2": {
                "teamId": 6,
                "teamName": "Rajasthan Royals",
                "teamSName": "RR",
                "imageId": 1006
            },
            "venueInfo": {
                "ground": "Narendra Modi Stadium",
                "city": "Ahmedabad"
            }
        }
    },
    {
        "_matchType": "T20",
        "_seriesName": "Indian Premier League 2026",
        "matchInfo": {
            "matchId": 99004,
            "seriesId": 999,
            "seriesName": "Indian Premier League 2026",
            "matchDesc": "Group Stage",
            "matchFormat": "T20",
            "startDate": 1780236000000,
            "endDate": 1780248600000,
            "state": "Preview",
            "status": "Upcoming Match",
            "team1": {
                "teamId": 7,
                "teamName": "Gujarat Titans",
                "teamSName": "GT",
                "imageId": 1007
            },
            "team2": {
                "teamId": 8,
                "teamName": "Lucknow Super Giants",
                "teamSName": "LSG",
                "imageId": 1008
            },
            "venueInfo": {
                "ground": "Arun Jaitley Stadium",
                "city": "Delhi"
            }
        }
    },
    {
        "_matchType": "T20",
        "_seriesName": "Indian Premier League 2026",
        "matchInfo": {
            "matchId": 99005,
            "seriesId": 999,
            "seriesName": "Indian Premier League 2026",
            "matchDesc": "Group Stage",
            "matchFormat": "T20",
            "startDate": 1780322400000,
            "endDate": 1780335000000,
            "state": "Preview",
            "status": "Upcoming Match",
            "team1": {
                "teamId": 9,
                "teamName": "Delhi Capitals",
                "teamSName": "DC",
                "imageId": 1009
            },
            "team2": {
                "teamId": 10,
                "teamName": "Punjab Kings",
                "teamSName": "PBKS",
                "imageId": 1010
            },
            "venueInfo": {
                "ground": "HPCA Stadium",
                "city": "Dharamshala"
            }
        }
    }
]


def is_ipl(match: dict) -> bool:
    """Check if the match is part of the Indian Premier League (IPL) or features IPL teams."""
    series_name = (match.get("_seriesName") or match.get("matchInfo", {}).get("seriesName") or "").lower()
    if "indian premier league" in series_name or "ipl" in series_name:
        return True
    
    info = match.get("matchInfo", {})
    t1 = (info.get("team1", {}).get("teamName") or "").lower()
    t2 = (info.get("team2", {}).get("teamName") or "").lower()
    
    def is_ipl_t(name):
        # Split by spaces and remove punctuation
        words = [w.strip(".,()[]{}") for w in name.split()]
        abbreviations = {"csk", "mi", "rcb", "kkr", "rr", "dc", "pbks", "srh", "gt", "lsg"}
        full_names = {
            "chennai", "super", "kings", "mumbai", "indians", "royal", "challengers",
            "bengaluru", "bangalore", "kolkata", "knight", "riders", "rajasthan", "royals",
            "delhi", "capitals", "punjab", "sunrisers", "hyderabad", "gujarat", "titans",
            "lucknow", "giants"
        }
        return any(w in full_names or w in abbreviations for w in words)
    
    return is_ipl_t(t1) or is_ipl_t(t2)


def is_allowed_match(match: dict) -> bool:
    """Check if the match is an IPL match or an international match."""
    # 1. Keep IPL matches
    if is_ipl(match):
        return True
    
    # 2. Keep international matches (which includes international ODI, Test, and T20Is)
    match_type = (match.get("_matchType") or "").lower()
    if "international" in match_type:
        return True
        
    return False


def get_mock_scorecard(match_id: int) -> dict:
    mapping = {
        99001: ("Chennai Super Kings", "CSK", "Mumbai Indians", "MI"),
        99002: ("Royal Challengers Bengaluru", "RCB", "Kolkata Knight Riders", "KKR"),
        99003: ("Sunrisers Hyderabad", "SRH", "Rajasthan Royals", "RR"),
        99004: ("Gujarat Titans", "GT", "Lucknow Super Giants", "LSG"),
        99005: ("Delhi Capitals", "DC", "Punjab Kings", "PBKS"),
    }
    if match_id not in mapping:
        return {"status": "error", "message": "Match not found", "teams": {}}
    
    t1_name, t1_short, t2_name, t2_short = mapping[match_id]
    
    rosters = {
        "CSK": {
            "playingXI": [
                {"name": "Ruturaj Gaikwad", "role": "Batter", "number": "31", "imageId": "11813", "nationality": "Indian", "stats": "Runs: 42, Balls: 28, Strike Rate: 150.0"},
                {"name": "Rachin Ravindra", "role": "Batter", "number": "17", "imageId": "13735", "nationality": "New Zealander", "stats": "Runs: 10, Balls: 8, Strike Rate: 125.0"},
                {"name": "Ajinkya Rahane", "role": "Batter", "number": "21", "imageId": "1447", "nationality": "Indian", "stats": "Runs: 8, Balls: 10, Strike Rate: 80.0"},
                {"name": "Shivam Dube", "role": "All-Rounder", "number": "25", "imageId": "11801", "nationality": "Indian", "stats": "Runs: 34, Balls: 18, Strike Rate: 188.8"},
                {"name": "MS Dhoni", "role": "Wicketkeeper", "number": "7", "imageId": "265", "nationality": "Indian", "stats": "Runs: 28, Balls: 12, Strike Rate: 233.3"},
                {"name": "Ravindra Jadeja", "role": "All-Rounder", "number": "8", "imageId": "587", "nationality": "Indian", "stats": "Runs: 15, Balls: 10, Strike Rate: 150.0"},
                {"name": "Mitchell Santner", "role": "All-Rounder", "number": "74", "imageId": "8683", "nationality": "New Zealander", "stats": "Did Not Bat"},
                {"name": "Shardul Thakur", "role": "Bowler", "number": "54", "imageId": "8685", "nationality": "Indian", "stats": "Overs: 4, Wickets: 1, Economy: 8.5"},
                {"name": "Tushar Deshpande", "role": "Bowler", "number": "24", "imageId": "13670", "nationality": "Indian", "stats": "Overs: 4, Wickets: 2, Economy: 8.4"},
                {"name": "Matheesha Pathirana", "role": "Bowler", "number": "99", "imageId": "14705", "nationality": "Sri Lankan", "stats": "Overs: 4, Wickets: 3, Economy: 7.6"},
                {"name": "Richard Gleeson", "role": "Bowler", "number": "71", "imageId": "11036", "nationality": "English", "stats": "Overs: 4, Wickets: 0, Economy: 9.0"}
            ],
            "bench": [
                {"name": "Sameer Rizvi", "role": "Batter", "number": "1", "imageId": "14001", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Prashant Solanki", "role": "Bowler", "number": "3", "imageId": "14002", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Shaik Rasheed", "role": "Batter", "number": "4", "imageId": "14003", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Mukesh Choudhary", "role": "Bowler", "number": "5", "imageId": "14004", "nationality": "Indian", "stats": "Did Not Play"}
            ]
        },
        "MI": {
            "playingXI": [
                {"name": "Rohit Sharma", "role": "Batter", "number": "45", "imageId": "576", "nationality": "Indian", "stats": "Runs: 54, Balls: 35, Strike Rate: 154.3"},
                {"name": "Ishan Kishan", "role": "Wicketkeeper", "number": "23", "imageId": "10276", "nationality": "Indian", "stats": "Runs: 18, Balls: 12, Strike Rate: 150.0"},
                {"name": "Suryakumar Yadav", "role": "Batter", "number": "63", "imageId": "8292", "nationality": "Indian", "stats": "Runs: 31, Balls: 15, Strike Rate: 206.7"},
                {"name": "Tilak Varma", "role": "Batter", "number": "9", "imageId": "12781", "nationality": "Indian", "stats": "Runs: 12, Balls: 8, Strike Rate: 150.0"},
                {"name": "Hardik Pandya", "role": "All-Rounder", "number": "33", "imageId": "9647", "nationality": "Indian", "stats": "Runs: 22, Balls: 14, Strike Rate: 157.1"},
                {"name": "Tim David", "role": "Batter", "number": "85", "imageId": "11532", "nationality": "Australian", "stats": "Runs: 25, Balls: 13, Strike Rate: 192.3"},
                {"name": "Romario Shepherd", "role": "All-Rounder", "number": "16", "imageId": "11406", "nationality": "West Indian", "stats": "Runs: 10, Balls: 6, Strike Rate: 166.7"},
                {"name": "Gerald Coetzee", "role": "Bowler", "number": "62", "imageId": "13217", "nationality": "South African", "stats": "Overs: 4, Wickets: 1, Economy: 8.9"},
                {"name": "Jasprit Bumrah", "role": "Bowler", "number": "93", "imageId": "9311", "nationality": "Indian", "stats": "Overs: 3.0, Wickets: 2, Economy: 5.5"},
                {"name": "Piyush Chawla", "role": "Bowler", "number": "11", "imageId": "376", "nationality": "Indian", "stats": "Overs: 4, Wickets: 1, Economy: 8.0"},
                {"name": "Nuwan Thushara", "role": "Bowler", "number": "54", "imageId": "13963", "nationality": "Sri Lankan", "stats": "Overs: 3, Wickets: 0, Economy: 9.5"}
            ],
            "bench": [
                {"name": "Dewald Brevis", "role": "Batter", "number": "18", "imageId": "14005", "nationality": "South African", "stats": "Did Not Play"},
                {"name": "Shreyas Gopal", "role": "Bowler", "number": "27", "imageId": "14006", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Naman Dhir", "role": "All-Rounder", "number": "10", "imageId": "14007", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Anshul Kamboj", "role": "Bowler", "number": "12", "imageId": "14008", "nationality": "Indian", "stats": "Did Not Play"}
            ]
        },
        "RCB": {
            "playingXI": [
                {"name": "Virat Kohli", "role": "Batter", "number": "18", "imageId": "1413", "nationality": "Indian", "stats": "Runs: 72, Balls: 47, Strike Rate: 153.2"},
                {"name": "Faf du Plessis", "role": "Batter", "number": "13", "imageId": "370", "nationality": "South African", "stats": "Runs: 35, Balls: 22, Strike Rate: 159.1"},
                {"name": "Will Jacks", "role": "All-Rounder", "number": "20", "imageId": "11571", "nationality": "English", "stats": "Runs: 12, Balls: 8, Strike Rate: 150.0"},
                {"name": "Rajat Patidar", "role": "Batter", "number": "97", "imageId": "10904", "nationality": "Indian", "stats": "Runs: 15, Balls: 10, Strike Rate: 150.0"},
                {"name": "Glenn Maxwell", "role": "All-Rounder", "number": "32", "imageId": "1844", "nationality": "Australian", "stats": "Runs: 18, Balls: 11, Strike Rate: 163.6"},
                {"name": "Cameron Green", "role": "All-Rounder", "number": "4", "imageId": "11782", "nationality": "Australian", "stats": "Runs: 20, Balls: 12, Strike Rate: 166.7"},
                {"name": "Dinesh Karthik", "role": "Wicketkeeper", "number": "19", "imageId": "145", "nationality": "Indian", "stats": "Runs: 26, Balls: 14, Strike Rate: 185.7"},
                {"name": "Swapnil Singh", "role": "All-Rounder", "number": "86", "imageId": "9042", "nationality": "Indian", "stats": "Overs: 2, Wickets: 1, Economy: 8.0"},
                {"name": "Karn Sharma", "role": "Bowler", "number": "33", "imageId": "1849", "nationality": "Indian", "stats": "Overs: 4, Wickets: 1, Economy: 8.5"},
                {"name": "Mohammed Siraj", "role": "Bowler", "number": "73", "imageId": "10808", "nationality": "Indian", "stats": "Overs: 4, Wickets: 1, Economy: 8.2"},
                {"name": "Yash Dayal", "role": "Bowler", "number": "12", "imageId": "12847", "nationality": "Indian", "stats": "Overs: 4, Wickets: 2, Economy: 8.8"}
            ],
            "bench": [
                {"name": "Anuj Rawat", "role": "Wicketkeeper", "number": "55", "imageId": "14009", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Mahipal Lomror", "role": "All-Rounder", "number": "6", "imageId": "14010", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Tom Curran", "role": "All-Rounder", "number": "59", "imageId": "14011", "nationality": "English", "stats": "Did Not Play"},
                {"name": "Lockie Ferguson", "role": "Bowler", "number": "87", "imageId": "14012", "nationality": "New Zealander", "stats": "Did Not Play"}
            ]
        },
        "KKR": {
            "playingXI": [
                {"name": "Shreyas Iyer", "role": "Batter", "number": "41", "imageId": "9425", "nationality": "Indian", "stats": "Runs: 38, Balls: 25, Strike Rate: 152.0"},
                {"name": "Phil Salt", "role": "Wicketkeeper", "number": "21", "imageId": "10712", "nationality": "English", "stats": "Runs: 20, Balls: 15, Strike Rate: 133.3"},
                {"name": "Sunil Narine", "role": "All-Rounder", "number": "74", "imageId": "1985", "nationality": "West Indian", "stats": "Runs: 25, Balls: 12, Strike Rate: 208.3"},
                {"name": "Venkatesh Iyer", "role": "Batter", "number": "27", "imageId": "10917", "nationality": "Indian", "stats": "Runs: 15, Balls: 12, Strike Rate: 125.0"},
                {"name": "Andre Russell", "role": "All-Rounder", "number": "12", "imageId": "7736", "nationality": "West Indian", "stats": "Runs: 41, Balls: 19, Strike Rate: 215.8"},
                {"name": "Rinku Singh", "role": "Batter", "number": "35", "imageId": "10892", "nationality": "Indian", "stats": "Runs: 18, Balls: 9, Strike Rate: 200.0"},
                {"name": "Ramandeep Singh", "role": "All-Rounder", "number": "19", "imageId": "14562", "nationality": "Indian", "stats": "Runs: 10, Balls: 5, Strike Rate: 200.0"},
                {"name": "Mitchell Starc", "role": "Bowler", "number": "56", "imageId": "7725", "nationality": "Australian", "stats": "Overs: 4, Wickets: 2, Economy: 8.8"},
                {"name": "Harshit Rana", "role": "Bowler", "number": "28", "imageId": "15061", "nationality": "Indian", "stats": "Overs: 4, Wickets: 1, Economy: 9.1"},
                {"name": "Varun Chakaravarthy", "role": "Bowler", "number": "29", "imageId": "12926", "nationality": "Indian", "stats": "Overs: 4, Wickets: 3, Economy: 6.5"},
                {"name": "Vaibhav Arora", "role": "Bowler", "number": "14", "imageId": "13672", "nationality": "Indian", "stats": "Overs: 4, Wickets: 1, Economy: 8.5"}
            ],
            "bench": [
                {"name": "Rahmanullah Gurbaz", "role": "Wicketkeeper", "number": "21", "imageId": "14013", "nationality": "Afghan", "stats": "Did Not Play"},
                {"name": "Nitish Rana", "role": "Batter", "number": "27", "imageId": "14014", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Suyash Sharma", "role": "Bowler", "number": "9", "imageId": "14015", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Sherfane Rutherford", "role": "Batter", "number": "50", "imageId": "14016", "nationality": "West Indian", "stats": "Did Not Play"}
            ]
        },
        "SRH": {
            "playingXI": [
                {"name": "Travis Head", "role": "Batter", "number": "62", "imageId": "8709", "nationality": "Australian", "stats": "Runs: 58, Balls: 30, Strike Rate: 193.3"},
                {"name": "Abhishek Sharma", "role": "Batter", "number": "4", "imageId": "11796", "nationality": "Indian", "stats": "Runs: 32, Balls: 16, Strike Rate: 200.0"},
                {"name": "Nitish Kumar Reddy", "role": "All-Rounder", "number": "67", "imageId": "14188", "nationality": "Indian", "stats": "Runs: 15, Balls: 10, Strike Rate: 150.0"},
                {"name": "Heinrich Klaasen", "role": "Wicketkeeper", "number": "45", "imageId": "8422", "nationality": "South African", "stats": "Runs: 44, Balls: 22, Strike Rate: 200.0"},
                {"name": "Abdul Samad", "role": "Batter", "number": "1", "imageId": "12825", "nationality": "Indian", "stats": "Runs: 10, Balls: 8, Strike Rate: 125.0"},
                {"name": "Shahbaz Ahmed", "role": "All-Rounder", "number": "21", "imageId": "12918", "nationality": "Indian", "stats": "Runs: 12, Balls: 7, Strike Rate: 171.4"},
                {"name": "Pat Cummins", "role": "All-Rounder", "number": "30", "imageId": "8095", "nationality": "Australian", "stats": "Overs: 4, Wickets: 2, Economy: 7.8"},
                {"name": "Bhuvneshwar Kumar", "role": "Bowler", "number": "15", "imageId": "1726", "nationality": "Indian", "stats": "Overs: 4, Wickets: 1, Economy: 8.0"},
                {"name": "Jaydev Unadkat", "role": "Bowler", "number": "46", "imageId": "6410", "nationality": "Indian", "stats": "Overs: 4, Wickets: 1, Economy: 9.3"},
                {"name": "Mayank Markande", "role": "Bowler", "number": "11", "imageId": "11799", "nationality": "Indian", "stats": "Overs: 4, Wickets: 0, Economy: 8.8"},
                {"name": "T Natarajan", "role": "Bowler", "number": "44", "imageId": "10884", "nationality": "Indian", "stats": "Overs: 4, Wickets: 1, Economy: 9.2"}
            ],
            "bench": [
                {"name": "Glenn Phillips", "role": "Batter", "number": "23", "imageId": "14017", "nationality": "New Zealander", "stats": "Did Not Play"},
                {"name": "Washington Sundar", "role": "All-Rounder", "number": "5", "imageId": "14018", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Umran Malik", "role": "Bowler", "number": "24", "imageId": "14019", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Rahul Tripathi", "role": "Batter", "number": "52", "imageId": "14020", "nationality": "Indian", "stats": "Did Not Play"}
            ]
        },
        "RR": {
            "playingXI": [
                {"name": "Sanju Samson", "role": "Batter", "number": "8", "imageId": "8271", "nationality": "Indian", "stats": "Runs: 48, Balls: 32, Strike Rate: 150.0"},
                {"name": "Yashasvi Jaiswal", "role": "Batter", "number": "64", "imageId": "13533", "nationality": "Indian", "stats": "Runs: 35, Balls: 20, Strike Rate: 175.0"},
                {"name": "Jos Buttler", "role": "Wicketkeeper", "number": "63", "imageId": "7909", "nationality": "English", "stats": "Runs: 29, Balls: 18, Strike Rate: 161.1"},
                {"name": "Riyan Parag", "role": "Batter", "number": "12", "imageId": "12777", "nationality": "Indian", "stats": "Runs: 24, Balls: 15, Strike Rate: 160.0"},
                {"name": "Shimron Hetmyer", "role": "Batter", "number": "18", "imageId": "9376", "nationality": "West Indian", "stats": "Runs: 15, Balls: 9, Strike Rate: 166.7"},
                {"name": "Dhruv Jurel", "role": "Batter", "number": "21", "imageId": "14198", "nationality": "Indian", "stats": "Runs: 10, Balls: 7, Strike Rate: 142.9"},
                {"name": "Ravichandran Ashwin", "role": "All-Rounder", "number": "99", "imageId": "1530", "nationality": "Indian", "stats": "Overs: 4, Wickets: 1, Economy: 8.3"},
                {"name": "Trent Boult", "role": "Bowler", "number": "18", "imageId": "7723", "nationality": "New Zealander", "stats": "Overs: 4, Wickets: 1, Economy: 6.8"},
                {"name": "Avesh Khan", "role": "Bowler", "number": "27", "imageId": "10918", "nationality": "Indian", "stats": "Overs: 4, Wickets: 1, Economy: 8.9"},
                {"name": "Sandeep Sharma", "role": "Bowler", "number": "20", "imageId": "8050", "nationality": "Indian", "stats": "Overs: 4, Wickets: 2, Economy: 7.9"},
                {"name": "Yuzvendra Chahal", "role": "Bowler", "number": "3", "imageId": "7910", "nationality": "Indian", "stats": "Overs: 4, Wickets: 2, Economy: 7.5"}
            ],
            "bench": [
                {"name": "Rovman Powell", "role": "Batter", "number": "14", "imageId": "14021", "nationality": "West Indian", "stats": "Did Not Play"},
                {"name": "Navdeep Saini", "role": "Bowler", "number": "29", "imageId": "14022", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Donavon Ferreira", "role": "Batter", "number": "55", "imageId": "14023", "nationality": "South African", "stats": "Did Not Play"},
                {"name": "Nandre Burger", "role": "Bowler", "number": "88", "imageId": "14024", "nationality": "South African", "stats": "Did Not Play"}
            ]
        },
        "GT": {
            "playingXI": [
                {"name": "Shubman Gill", "role": "Batter", "number": "7", "imageId": "11808", "nationality": "Indian", "stats": "Runs: 52, Balls: 36, Strike Rate: 144.4"},
                {"name": "Sai Sudharsan", "role": "Batter", "number": "23", "imageId": "14201", "nationality": "Indian", "stats": "Runs: 38, Balls: 28, Strike Rate: 135.7"},
                {"name": "David Miller", "role": "Batter", "number": "10", "imageId": "571", "nationality": "South African", "stats": "Runs: 24, Balls: 16, Strike Rate: 150.0"},
                {"name": "Shahrukh Khan", "role": "Batter", "number": "24", "imageId": "10890", "nationality": "Indian", "stats": "Runs: 12, Balls: 8, Strike Rate: 150.0"},
                {"name": "Rahul Tewatia", "role": "All-Rounder", "number": "20", "imageId": "9631", "nationality": "Indian", "stats": "Runs: 18, Balls: 10, Strike Rate: 180.0"},
                {"name": "Rashid Khan", "role": "All-Rounder", "number": "19", "imageId": "10738", "nationality": "Afghan", "stats": "Overs: 4, Wickets: 2, Economy: 6.2"},
                {"name": "R Sai Kishore", "role": "Bowler", "number": "8", "imageId": "11795", "nationality": "Indian", "stats": "Overs: 3, Wickets: 1, Economy: 9.1"},
                {"name": "Mohit Sharma", "role": "Bowler", "number": "18", "imageId": "7941", "nationality": "Indian", "stats": "Overs: 4, Wickets: 2, Economy: 8.5"},
                {"name": "Umesh Yadav", "role": "Bowler", "number": "70", "imageId": "1858", "nationality": "Indian", "stats": "Overs: 3, Wickets: 1, Economy: 9.0"},
                {"name": "Spencer Johnson", "role": "Bowler", "number": "45", "imageId": "16084", "nationality": "Australian", "stats": "Overs: 4, Wickets: 1, Economy: 9.2"},
                {"name": "Noor Ahmad", "role": "Bowler", "number": "15", "imageId": "14304", "nationality": "Afghan", "stats": "Overs: 4, Wickets: 1, Economy: 8.2"}
            ],
            "bench": [
                {"name": "Kane Williamson", "role": "Batter", "number": "22", "imageId": "14025", "nationality": "New Zealander", "stats": "Did Not Play"},
                {"name": "Wridhiman Saha", "role": "Wicketkeeper", "number": "6", "imageId": "14026", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Joshua Little", "role": "Bowler", "number": "30", "imageId": "14027", "nationality": "Irish", "stats": "Did Not Play"},
                {"name": "Kartik Tyagi", "role": "Bowler", "number": "13", "imageId": "14028", "nationality": "Indian", "stats": "Did Not Play"}
            ]
        },
        "LSG": {
            "playingXI": [
                {"name": "KL Rahul", "role": "Batter", "number": "1", "imageId": "8733", "nationality": "Indian", "stats": "Runs: 44, Balls: 32, Strike Rate: 137.5"},
                {"name": "Devdutt Padikkal", "role": "Batter", "number": "19", "imageId": "11803", "nationality": "Indian", "stats": "Runs: 12, Balls: 10, Strike Rate: 120.0"},
                {"name": "Marcus Stoinis", "role": "All-Rounder", "number": "17", "imageId": "7974", "nationality": "Australian", "stats": "Runs: 28, Balls: 18, Strike Rate: 155.6"},
                {"name": "Nicholas Pooran", "role": "Batter", "number": "29", "imageId": "9582", "nationality": "West Indian", "stats": "Runs: 49, Balls: 25, Strike Rate: 196.0"},
                {"name": "Deepak Hooda", "role": "Batter", "number": "5", "imageId": "9423", "nationality": "Indian", "stats": "Runs: 15, Balls: 12, Strike Rate: 125.0"},
                {"name": "Ayush Badoni", "role": "Batter", "number": "11", "imageId": "13524", "nationality": "Indian", "stats": "Runs: 235, Strike Rate: 138.0"},
                {"name": "Krunal Pandya", "role": "All-Rounder", "number": "25", "imageId": "9654", "nationality": "Indian", "stats": "Overs: 4, Wickets: 1, Economy: 7.2"},
                {"name": "Ravi Bishnoi", "role": "Bowler", "number": "56", "imageId": "12782", "nationality": "Indian", "stats": "Overs: 4, Wickets: 1, Economy: 7.5"},
                {"name": "Naveen-ul-Haq", "role": "Bowler", "number": "78", "imageId": "10767", "nationality": "Afghan", "stats": "Overs: 4, Wickets: 2, Economy: 8.8"},
                {"name": "Yash Thakur", "role": "Bowler", "number": "34", "imageId": "12848", "nationality": "Indian", "stats": "Overs: 4, Wickets: 1, Economy: 9.0"},
                {"name": "Mayank Yadav", "role": "Bowler", "number": "23", "imageId": "15494", "nationality": "Indian", "stats": "Overs: 4, Wickets: 2, Economy: 6.9"}
            ],
            "bench": [
                {"name": "Quinton de Kock", "role": "Wicketkeeper", "number": "12", "imageId": "14029", "nationality": "South African", "stats": "Did Not Play"},
                {"name": "Amit Mishra", "role": "Bowler", "number": "99", "imageId": "14030", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Prerak Mankad", "role": "All-Rounder", "number": "24", "imageId": "14031", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Shamar Joseph", "role": "Bowler", "number": "8", "imageId": "14032", "nationality": "West Indian", "stats": "Did Not Play"}
            ]
        },
        "DC": {
            "playingXI": [
                {"name": "Rishabh Pant", "role": "Batter", "number": "17", "imageId": "1081", "nationality": "Indian", "stats": "Runs: 46, Balls: 28, Strike Rate: 164.3"},
                {"name": "David Warner", "role": "Batter", "number": "31", "imageId": "1082", "nationality": "Australian", "stats": "Runs: 34, Balls: 24, Strike Rate: 141.7"},
                {"name": "Jake Fraser-McGurk", "role": "Batter", "number": "24", "imageId": "15160", "nationality": "Australian", "stats": "Runs: 20, Balls: 10, Strike Rate: 200.0"},
                {"name": "Abishek Porel", "role": "Batter", "number": "22", "imageId": "14197", "nationality": "Indian", "stats": "Runs: 15, Balls: 12, Strike Rate: 125.0"},
                {"name": "Shai Hope", "role": "Batter", "number": "4", "imageId": "9377", "nationality": "West Indian", "stats": "Runs: 12, Balls: 10, Strike Rate: 120.0"},
                {"name": "Tristan Stubbs", "role": "Batter", "number": "30", "imageId": "14545", "nationality": "South African", "stats": "Runs: 22, Balls: 14, Strike Rate: 157.1"},
                {"name": "Axar Patel", "role": "All-Rounder", "number": "20", "imageId": "1083", "nationality": "Indian", "stats": "Overs: 4, Wickets: 1, Economy: 7.5"},
                {"name": "Kuldeep Yadav", "role": "Bowler", "number": "23", "imageId": "1084", "nationality": "Indian", "stats": "Overs: 4, Wickets: 2, Economy: 6.8"},
                {"name": "Prithvi Shaw", "role": "Batter", "number": "100", "imageId": "1085", "nationality": "Indian", "stats": "Runs: 18, Balls: 12, Strike Rate: 150.0"},
                {"name": "Khaleel Ahmed", "role": "Bowler", "number": "90", "imageId": "1086", "nationality": "Indian", "stats": "Overs: 4, Wickets: 1, Economy: 8.2"},
                {"name": "Mukesh Kumar", "role": "Bowler", "number": "19", "imageId": "11664", "nationality": "Indian", "stats": "Overs: 4, Wickets: 2, Economy: 9.0"}
            ],
            "bench": [
                {"name": "Lalit Yadav", "role": "All-Rounder", "number": "5", "imageId": "14033", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Anrich Nortje", "role": "Bowler", "number": "20", "imageId": "14034", "nationality": "South African", "stats": "Did Not Play"},
                {"name": "Kumar Kushagra", "role": "Wicketkeeper", "number": "9", "imageId": "14035", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Rasikh Salam", "role": "Bowler", "number": "77", "imageId": "14036", "nationality": "Indian", "stats": "Did Not Play"}
            ]
        },
        "PBKS": {
            "playingXI": [
                {"name": "Shikhar Dhawan", "role": "Batter", "number": "1091", "imageId": "1091", "nationality": "Indian", "stats": "Runs: 35, Balls: 28, Strike Rate: 125.0"},
                {"name": "Prabhsimran Singh", "role": "Batter", "number": "84", "imageId": "11804", "nationality": "Indian", "stats": "Runs: 12, Balls: 10, Strike Rate: 120.0"},
                {"name": "Jonny Bairstow", "role": "Batter", "number": "51", "imageId": "7911", "nationality": "English", "stats": "Runs: 20, Balls: 15, Strike Rate: 133.3"},
                {"name": "Rilee Rossouw", "role": "Batter", "number": "99", "imageId": "1878", "nationality": "South African", "stats": "Runs: 15, Balls: 12, Strike Rate: 125.0"},
                {"name": "Shashank Singh", "role": "Batter", "number": "25", "imageId": "10901", "nationality": "Indian", "stats": "Runs: 25, Balls: 18, Strike Rate: 138.9"},
                {"name": "Jitesh Sharma", "role": "Wicketkeeper", "number": "23", "imageId": "1096", "nationality": "Indian", "stats": "Runs: 15, Balls: 10, Strike Rate: 150.0"},
                {"name": "Sam Curran", "role": "All-Rounder", "number": "58", "imageId": "1092", "nationality": "English", "stats": "Runs: 24, Balls: 16, Strike Rate: 150.0"},
                {"name": "Liam Livingstone", "role": "All-Rounder", "number": "93", "imageId": "1093", "nationality": "English", "stats": "Runs: 38, Balls: 20, Strike Rate: 190.0"},
                {"name": "Arshdeep Singh", "role": "Bowler", "number": "9", "imageId": "1094", "nationality": "Indian", "stats": "Overs: 4, Wickets: 3, Economy: 7.8"},
                {"name": "Kagiso Rabada", "role": "Bowler", "number": "95", "imageId": "1095", "nationality": "South African", "stats": "Overs: 4, Wickets: 1, Economy: 8.5"},
                {"name": "Harpreet Brar", "role": "Bowler", "number": "95", "imageId": "11802", "nationality": "Indian", "stats": "Overs: 4, Wickets: 0, Economy: 8.0"}
            ],
            "bench": [
                {"name": "Ashutosh Sharma", "role": "Batter", "number": "12", "imageId": "14037", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Harshal Patel", "role": "Bowler", "number": "83", "imageId": "14038", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Rahul Chahar", "role": "Bowler", "number": "2", "imageId": "14039", "nationality": "Indian", "stats": "Did Not Play"},
                {"name": "Chris Woakes", "role": "All-Rounder", "number": "15", "imageId": "14040", "nationality": "English", "stats": "Did Not Play"}
            ]
        }
    }
    
    t1_roster = rosters.get(t1_short, {"playingXI": [], "bench": []})
    t2_roster = rosters.get(t2_short, {"playingXI": [], "bench": []})
    
    live_state = None
    if match_id == 99001:
        live_state = {
            "inningsNo": 2,
            "battingTeamId": 1,
            "bowlingTeamId": 2,
            "target": 183,
            "runsNeeded": 12,
            "ballsRemaining": 6,
            "requiredRunRate": 12.0,
            "currentRunRate": 9.0,
            "activeBatsmen": [
                {
                    "name": "MS Dhoni",
                    "playerId": 1001,
                    "runs": 28,
                    "ballsFaced": 12,
                    "fours": 1,
                    "sixes": 3,
                    "isStriker": True
                },
                {
                    "name": "Ravindra Jadeja",
                    "playerId": 1003,
                    "runs": 15,
                    "ballsFaced": 10,
                    "fours": 0,
                    "sixes": 1,
                    "isStriker": False
                }
            ],
            "activeBowler": {
                "name": "Jasprit Bumrah",
                "playerId": 1014,
                "overs": 3.0,
                "maidens": 0,
                "runsConceded": 22,
                "wickets": 2,
                "currentOverStats": [".", "6", "W", "1", "4", "1"]
            }
        }

    CAPTAINS = {
        "Ruturaj Gaikwad", "Hardik Pandya", "Faf du Plessis", 
        "Shreyas Iyer", "Pat Cummins", "Sanju Samson", 
        "Shubman Gill", "KL Rahul", "Rishabh Pant", "Shikhar Dhawan",
        "MS Dhoni", "Babar Azam"
    }
    
    for roster in (t1_roster, t2_roster):
        for p in roster.get("playingXI", []):
            p["captain"] = p.get("name") in CAPTAINS
        for p in roster.get("bench", []):
            p["captain"] = p.get("name") in CAPTAINS

    return {
        "status": "success",
        "liveState": live_state,
        "teams": {
            t1_name: {
                "short": t1_short,
                "players": t1_roster["playingXI"] + t1_roster["bench"],
                "playingXI": t1_roster["playingXI"],
                "bench": t1_roster["bench"]
            },
            t2_name: {
                "short": t2_short,
                "players": t2_roster["playingXI"] + t2_roster["bench"],
                "playingXI": t2_roster["playingXI"],
                "bench": t2_roster["bench"]
            }
        }
    }


@router.get("/matches/live-and-upcoming")
def get_live_and_upcoming_cricket_matches():
    """
    Returns all LIVE + UPCOMING cricket matches merged in one list.
    Filters out completed matches (state == 'Complete').
    Returns IPL matches and international/ODI/TEST matches.
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

    # Keep IPL and international/ODI/TEST matches
    filtered_matches = [m for m in all_matches if is_allowed_match(m)]
    
    # Fallback to mock IPL matches if none found
    if not filtered_matches:
        filtered_matches = MOCK_IPL_MATCHES

    return {"status": "success", "matches": filtered_matches}


@router.get("/matches/live")
def get_live_cricket_matches():
    """Legacy live-only endpoint. ONLY returns IPL matches."""
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
        filtered_matches = [m for m in matches if is_allowed_match(m)]
        if not filtered_matches:
            # return only the mock live match
            filtered_matches = [m for m in MOCK_IPL_MATCHES if m["matchInfo"]["state"].lower() == "live"]
        return {"status": "success", "matches": filtered_matches}
    except Exception as e:
        # Fallback to mock live if exception
        filtered_matches = [m for m in MOCK_IPL_MATCHES if m["matchInfo"]["state"].lower() == "live"]
        return {"status": "success", "matches": filtered_matches}


@router.get("/matches/upcoming")
def get_upcoming_cricket_matches():
    """Legacy upcoming-only endpoint. ONLY returns IPL matches."""
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
        filtered_matches = [m for m in matches if is_allowed_match(m)]
        if not filtered_matches:
            # return only the mock preview matches
            filtered_matches = [m for m in MOCK_IPL_MATCHES if m["matchInfo"]["state"].lower() == "preview"]
        return {"status": "success", "matches": filtered_matches}
    except Exception as e:
        # Fallback to mock preview if exception
        filtered_matches = [m for m in MOCK_IPL_MATCHES if m["matchInfo"]["state"].lower() == "preview"]
        return {"status": "success", "matches": filtered_matches}


def get_ipl_logo_path(team_name: str) -> str:
    if not team_name:
        return None
    
    name = team_name.lower().strip()
    
    # Check for keywords of IPL teams strictly to prevent overlaps
    if "chennai" in name or "super kings" in name or "csk" in name:
        return r"D:\assets\csk logo.png"
    elif "mumbai" in name or name == "mi" or "mumbai indians" in name:
        return r"D:\assets\MI logo.jpg"
    elif "royal challengers" in name or "rcb" in name or "bengaluru" in name or "bangalore" in name:
        return r"D:\assets\RCB logo.jpg"
    elif "kolkata" in name or "knight riders" in name or "kkr" in name:
        return r"D:\assets\kkr logo.jpg"
    elif "rajasthan" in name or name == "rr" or "rajasthan royals" in name:
        return r"D:\assets\Rajasthan royal.jpg"
    elif "delhi" in name or name == "dc" or "delhi capitals" in name:
        return r"D:\assets\delhi capitals logo.png"
    elif "punjab" in name or "kings xi" in name or "pbks" in name or "punjab kings" in name:
        return r"D:\assets\Punjab kings logo.jpg"
    elif "sunrisers" in name or "hyderabad" in name or "srh" in name:
        return r"D:\assets\sunrisers hyderabad logo.png"
    elif "gujarat" in name or name == "gt" or "gujarat titans" in name:
        return r"D:\assets\GT logo.png"
    elif "lucknow" in name or "super giants" in name or "lsg" in name:
        return r"D:\assets\LSG logo.jpg"
    
    return None


@router.get("/img/team/{image_id}")
def get_team_image(image_id: int, teamName: str = None):
    """Proxy Cricbuzz team/player images so browser doesn't need API headers. For IPL teams, uses local high-quality logos."""
    if teamName:
        local_path = get_ipl_logo_path(teamName)
        if local_path and os.path.exists(local_path):
            return FileResponse(local_path)

    try:
        resp = requests.get(
            f"https://www.cricbuzz.com/a/img/v1/152x152/i1/c{image_id}/i.jpg",
            headers={"User-Agent": "Mozilla/5.0"},
            timeout=5
        )
        if resp.status_code == 200:
            return Response(content=resp.content, media_type="image/jpeg")
    except Exception:
        pass
    return Response(status_code=404)


@router.get("/img/player/{player_id}")
def get_player_image(player_id: int):
    """Proxy Cricbuzz player face images."""
    try:
        resp = requests.get(
            f"https://www.cricbuzz.com/a/img/v1/152x152/i1/c{player_id}/i.jpg",
            headers={"User-Agent": "Mozilla/5.0"},
            timeout=5
        )
        if resp.status_code == 200:
            return Response(content=resp.content, media_type="image/jpeg")
    except Exception:
        pass
    return Response(status_code=404)


@router.get("/match/{match_id}/scorecard")
def get_match_scorecard(match_id: int):
    """
    Fetches the scorecard for a given matchId from Cricbuzz.
    Returns parsed team players with name, role, and basic stats.
    """
    # Intercept mock matches
    if match_id in (99001, 99002, 99003, 99004, 99005):
        return get_mock_scorecard(match_id)

    # 1. Try to fetch the team rosters (playing XI vs bench) from the Cricbuzz /teams endpoint
    teams_roster = {}
    try:
        teams_resp = requests.get(
            f"https://cricbuzz-cricket2.p.rapidapi.com/mcenter/v1/{match_id}/teams",
            headers=RAPIDAPI_HEADERS,
            timeout=10
        )
        if teams_resp.status_code == 200:
            teams_data = teams_resp.json()
            for t_key in ("team1", "team2"):
                t_info = teams_data.get(t_key, {})
                t_team = t_info.get("team", {})
                t_name = t_team.get("teamname")
                t_short = t_team.get("teamsname")
                if t_name:
                    playing_xi = []
                    bench = []
                    for group in t_info.get("players", []):
                        category = group.get("category", "").lower()
                        group_players = group.get("player", [])
                        
                        for p in group_players:
                            player_item = {
                                "name": p.get("name", "Unknown"),
                                "role": p.get("role", "Player"),
                                "number": str(p.get("id", "")),
                                "imageId": str(p.get("faceimageid") or p.get("id", "")),
                                "nationality": "International",
                                "stats": "Did Not Play" if "bench" in category else "Did Not Bat/Bowl",
                                "captain": p.get("captain", False)
                            }
                            if "playing" in category or "xi" in category:
                                playing_xi.append(player_item)
                            elif "bench" in category:
                                bench.append(player_item)
                    
                    teams_roster[t_name] = {
                        "short": t_short,
                        "playingXI": playing_xi,
                        "bench": bench,
                        "players": playing_xi + bench
                    }
    except Exception as e:
        print(f"Error fetching teams roster for match {match_id}: {e}")

    # 2. Try to fetch scorecard details (for current stats if live/complete)
    stats_map = {}
    scorecard_fetched = False
    scard_data = {}
    try:
        scard_resp = requests.get(
            f"https://cricbuzz-cricket2.p.rapidapi.com/mcenter/v1/{match_id}/scard",
            headers=RAPIDAPI_HEADERS,
            timeout=10
        )
        if scard_resp.status_code == 200:
            scard_data = scard_resp.json()
            scorecard_fetched = True
            for innings in scard_data.get("scoreCard", []):
                # Parse batsmen
                for bat_id, bat in innings.get("batTeamDetails", {}).get("batsmenData", {}).items():
                    p_id = str(bat.get("batId", ""))
                    stats_map[p_id] = f"Runs: {bat.get('runs', 0)}, Balls: {bat.get('balls', 0)}, SR: {bat.get('strikeRate', 0)}"

                # Parse bowlers
                bowl_team = innings.get("bowlTeamDetails", {})
                for bowl_id, bowl in bowl_team.get("bowlersData", {}).items():
                    p_id = str(bowl.get("bowlId", ""))
                    stats_map[p_id] = f"Overs: {bowl.get('overs', 0)}, Wickets: {bowl.get('wickets', 0)}, Econ: {bowl.get('economy', 0)}"
    except Exception as e:
        print(f"Error fetching scorecard stats for match {match_id}: {e}")

    # Merge stats into teams_roster if we have both
    has_players = len(teams_roster) == 2 and all(len(t_data.get("players", [])) > 0 for t_data in teams_roster.values())
    if teams_roster and has_players:
        for team_name, t_data in teams_roster.items():
            for p in t_data["playingXI"]:
                p_id = p["number"]
                if p_id in stats_map:
                    p["stats"] = stats_map[p_id]
            for p in t_data["bench"]:
                p_id = p["number"]
                if p_id in stats_map:
                    p["stats"] = stats_map[p_id]
            t_data["players"] = t_data["playingXI"] + t_data["bench"]
        return {"status": "success", "teams": teams_roster}

    # Fallback to simple scorecard parsing if teams roster failed
    if scorecard_fetched:
        try:
            teams = {}
            for innings in scard_data.get("scoreCard", []):
                team_name = innings.get("batTeamDetails", {}).get("batTeamName", "")
                team_short = innings.get("batTeamDetails", {}).get("batTeamSName", "")
                players = []

                # Parse batsmen
                for bat_id, bat in innings.get("batTeamDetails", {}).get("batsmenData", {}).items():
                    bat_player_id = bat.get("batId", "")
                    players.append({
                        "name": bat.get("batName", "Unknown"),
                        "role": "Batter",
                        "number": str(bat_player_id),
                        "imageId": str(bat_player_id),
                        "nationality": "International",
                        "stats": f"R: {bat.get('runs', 0)}, B: {bat.get('balls', 0)}, SR: {bat.get('strikeRate', 0)}"
                    })

                # Parse bowlers
                bowl_team = innings.get("bowlTeamDetails", {})
                bowl_team_name = bowl_team.get("bowlTeamName", "")
                for bowl_id, bowl in bowl_team.get("bowlersData", {}).items():
                    if bowl_team_name not in teams:
                        teams[bowl_team_name] = {"short": bowl_team.get("bowlTeamSName", ""), "players": []}
                    bowl_player_id = bowl.get("bowlId", "")
                    teams[bowl_team_name]["players"].append({
                        "name": bowl.get("bowlName", "Unknown"),
                        "role": "Bowler",
                        "number": str(bowl_player_id),
                        "imageId": str(bowl_player_id),
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

            # Map players to playingXI and empty bench for compatibility
            compatible_teams = {}
            for t_name, t_val in teams.items():
                compatible_teams[t_name] = {
                    "short": t_val.get("short", ""),
                    "players": t_val.get("players", []),
                    "playingXI": t_val.get("players", []),
                    "bench": []
                }
            has_compat_players = len(compatible_teams) == 2 and all(len(t_val.get("players", [])) > 0 for t_val in compatible_teams.values())
            if compatible_teams and has_compat_players:
                return {"status": "success", "teams": compatible_teams}
        except Exception as e:
            return {"status": "error", "message": str(e), "teams": {}}

    return {"status": "error", "message": "Failed to fetch match details or squads are empty", "teams": {}}
