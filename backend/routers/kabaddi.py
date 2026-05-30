from fastapi import APIRouter
import random
from typing import List, Dict, Optional
from pydantic import BaseModel

router = APIRouter(
    prefix="/api/kabaddi",
    tags=["Kabaddi"]
)

# Kabaddi Schemas
class TeamBrief(BaseModel):
    teamId: int
    teamName: str
    teamSName: str
    score: Optional[int] = 0

class VenueBrief(BaseModel):
    ground: str
    city: str

class MatchInfo(BaseModel):
    matchId: int
    seriesName: str
    matchDesc: str
    startDate: int
    state: str  # Live, Preview, Complete
    status: str
    team1: TeamBrief
    team2: TeamBrief
    venueInfo: VenueBrief

class KabaddiMatch(BaseModel):
    matchInfo: MatchInfo
    scoreText: Optional[str] = "VS"

# Mock Live & Upcoming Kabaddi Matches
MOCK_KABADDI_MATCHES = [
    {
        "matchInfo": {
            "matchId": 88001,
            "seriesName": "Pro Kabaddi League 2026",
            "matchDesc": "Match 45",
            "startDate": 1780063200000,
            "state": "Live",
            "status": "LIVE - Second Half",
            "team1": {
                "teamId": 801,
                "teamName": "Patna Pirates",
                "teamSName": "PAT",
                "score": 28
            },
            "team2": {
                "teamId": 802,
                "teamName": "U Mumba",
                "teamSName": "MUM",
                "score": 26
            },
            "venueInfo": {
                "ground": "Patliputra Sports Complex",
                "city": "Patna"
            }
        },
        "scoreText": "28 - 26"
    },
    {
        "matchInfo": {
            "matchId": 88002,
            "seriesName": "Pro Kabaddi League 2026",
            "matchDesc": "Match 46",
            "startDate": 1780149600000,
            "state": "Preview",
            "status": "Upcoming Match",
            "team1": {
                "teamId": 803,
                "teamName": "Jaipur Pink Panthers",
                "teamSName": "JAI",
                "score": 0
            },
            "team2": {
                "teamId": 804,
                "teamName": "Bengaluru Bulls",
                "teamSName": "BLR",
                "score": 0
            },
            "venueInfo": {
                "ground": "SMS Indoor Stadium",
                "city": "Jaipur"
            }
        },
        "scoreText": "VS"
    },
    {
        "matchInfo": {
            "matchId": 88003,
            "seriesName": "Pro Kabaddi League 2026",
            "matchDesc": "Match 47",
            "startDate": 1780236000000,
            "state": "Preview",
            "status": "Upcoming Match",
            "team1": {
                "teamId": 805,
                "teamName": "Dabang Delhi K.C.",
                "teamSName": "DEL",
                "score": 0
            },
            "team2": {
                "teamId": 806,
                "teamName": "Puneri Paltan",
                "teamSName": "PUN",
                "score": 0
            },
            "venueInfo": {
                "ground": "Thyagaraj Sports Complex",
                "city": "Delhi"
            }
        },
        "scoreText": "VS"
    }
]

@router.get("/matches/live-and-upcoming")
def get_live_and_upcoming_kabaddi_matches():
    return {"status": "success", "matches": MOCK_KABADDI_MATCHES}

@router.get("/match/{match_id}/scorecard")
def get_kabaddi_scorecard(match_id: int):
    # Mapping for teams details
    mapping = {
        88001: ("Patna Pirates", "PAT", "U Mumba", "MUM"),
        88002: ("Jaipur Pink Panthers", "JAI", "Bengaluru Bulls", "BLR"),
        88003: ("Dabang Delhi K.C.", "DEL", "Puneri Paltan", "PUN")
    }
    
    if match_id not in mapping:
        return {"status": "error", "message": "Kabaddi match not found"}
        
    t1_name, t1_short, t2_name, t2_short = mapping[match_id]
    
    # Generate mock Kabaddi rosters (Playing 7 + Bench)
    rosters = {
        "PAT": {
            "playingXI": [
                {"name": "Sudhakar M", "role": "Raider", "number": "1", "nationality": "Indian", "stats": "Raid Points: 8, Bonus: 2"},
                {"name": "Sachin Tanwar", "role": "Raider", "number": "9", "nationality": "Indian", "stats": "Raid Points: 6, Touch Points: 4"},
                {"name": "Manjeet", "role": "Raider", "number": "11", "nationality": "Indian", "stats": "Raid Points: 4, Tackle Points: 1"},
                {"name": "Ankit Jaglan", "role": "Defender - Left Corner", "number": "5", "nationality": "Indian", "stats": "Tackle Points: 4, Super Tackles: 1"},
                {"name": "Krishan Dhull", "role": "Defender - Right Corner", "number": "10", "nationality": "Indian", "stats": "Tackle Points: 3, Tackles: 5"},
                {"name": "Babu M", "role": "Defender - Left Cover", "number": "3", "nationality": "Indian", "stats": "Tackle Points: 1"},
                {"name": "Mayur Kadam", "role": "Defender - Right Cover", "number": "4", "nationality": "Indian", "stats": "Tackle Points: 0"}
            ],
            "bench": [
                {"name": "Randeep Singh", "role": "Raider", "number": "12", "nationality": "Indian", "stats": "Substituted Out"},
                {"name": "Thiyagarajan Yuvaraj", "role": "Defender", "number": "8", "nationality": "Indian", "stats": "DNP"}
            ]
        },
        "MUM": {
            "playingXI": [
                {"name": "Guman Singh", "role": "Raider", "number": "2", "nationality": "Indian", "stats": "Raid Points: 10, Super Raids: 1"},
                {"name": "Amirmohammad Zafardanesh", "role": "All-Rounder", "number": "10", "nationality": "Iranian", "stats": "Raid Points: 5, Tackle Points: 2"},
                {"name": "Alireza Mirzaeian", "role": "Raider", "number": "7", "nationality": "Iranian", "stats": "Raid Points: 2"},
                {"name": "Sombir", "role": "Defender - Left Corner", "number": "6", "nationality": "Indian", "stats": "Tackle Points: 3, Super Tackles: 1"},
                {"name": "Rinku Sharma", "role": "Defender - Right Corner", "number": "8", "nationality": "Indian", "stats": "Tackle Points: 2"},
                {"name": "Mahender Singh", "role": "Defender - Left Cover", "number": "5", "nationality": "Indian", "stats": "Tackle Points: 1"},
                {"name": "Surinder Singh", "role": "Defender - Right Cover", "number": "3", "nationality": "Indian", "stats": "Tackle Points: 1"}
            ],
            "bench": [
                {"name": "Pranay Rane", "role": "Raider", "number": "14", "nationality": "Indian", "stats": "DNP"},
                {"name": "Gokulakannan M", "role": "Defender", "number": "9", "nationality": "Indian", "stats": "DNP"}
            ]
        },
        "JAI": {
            "playingXI": [
                {"name": "Arjun Deshwal", "role": "Raider", "number": "9", "nationality": "Indian", "stats": "Last Season: 276 Raid Points"},
                {"name": "V Ajith Kumar", "role": "Raider", "number": "10", "nationality": "Indian", "stats": "Support Raider"},
                {"name": "Bhavani Rajput", "role": "Raider", "number": "11", "nationality": "Indian", "stats": "Support Raider"},
                {"name": "Ankush Rathee", "role": "Defender - Left Corner", "number": "3", "nationality": "Indian", "stats": "Last Season: 74 Tackle Points"},
                {"name": "Sahul Kumar", "role": "Defender - Right Corner", "number": "2", "nationality": "Indian", "stats": "Corner Support"},
                {"name": "Reza Mirbagheri", "role": "Defender - Left Cover", "number": "5", "nationality": "Iranian", "stats": "Aggressive Covers"},
                {"name": "Sunil Kumar", "role": "Defender - Right Cover", "number": "4", "nationality": "Indian", "stats": "Captain"}
            ],
            "bench": [
                {"name": "Lucky Sharma", "role": "Defender", "number": "7", "nationality": "Indian", "stats": "DNP"},
                {"name": "Abhishek KS", "role": "Defender", "number": "6", "nationality": "Indian", "stats": "DNP"}
            ]
        },
        "BLR": {
            "playingXI": [
                {"name": "Bharat Hooda", "role": "Raider", "number": "9", "nationality": "Indian", "stats": "Main Raider"},
                {"name": "Vikash Kandola", "role": "Raider", "number": "10", "nationality": "Indian", "stats": "Second Raider"},
                {"name": "Neeraj Narwal", "role": "All-Rounder", "number": "11", "nationality": "Indian", "stats": "Support All-Rounder"},
                {"name": "Aman", "role": "Defender - Left Corner", "number": "2", "nationality": "Indian", "stats": "Corner Defense"},
                {"name": "Saurabh Nandal", "role": "Defender - Right Corner", "number": "1", "nationality": "Indian", "stats": "Captain, Right Corner"},
                {"name": "Vishal", "role": "Defender - Left Cover", "number": "5", "nationality": "Indian", "stats": "Cover Support"},
                {"name": "Ponparthiban Subramanian", "role": "Defender - Right Cover", "number": "6", "nationality": "Indian", "stats": "Cover Support"}
            ],
            "bench": [
                {"name": "Ran Singh", "role": "All-Rounder", "number": "3", "nationality": "Indian", "stats": "DNP"},
                {"name": "Monu", "role": "Raider", "number": "8", "nationality": "Indian", "stats": "DNP"}
            ]
        },
        "DEL": {
            "playingXI": [
                {"name": "Naveen Kumar", "role": "Raider", "number": "10", "nationality": "Indian", "stats": "Naveen Express, Captain"},
                {"name": "Ashu Malik", "role": "Raider", "number": "9", "nationality": "Indian", "stats": "Co-Raider"},
                {"name": "Meet Sharma", "role": "Raider", "number": "11", "nationality": "Indian", "stats": "Support Raider"},
                {"name": "Ashish", "role": "Defender - Left Corner", "number": "2", "nationality": "Indian", "stats": "Corner"},
                {"name": "Yogesh Dhahiya", "role": "Defender - Right Corner", "number": "1", "nationality": "Indian", "stats": "Corner"},
                {"name": "Vikrant", "role": "Defender - Left Cover", "number": "3", "nationality": "Indian", "stats": "Cover"},
                {"name": "Mohit", "role": "Defender - Right Cover", "number": "4", "nationality": "Indian", "stats": "Cover"}
            ],
            "bench": [
                {"name": "Manjeet", "role": "Raider", "number": "12", "nationality": "Indian", "stats": "DNP"},
                {"name": "Vishal Bhardwaj", "role": "Defender", "number": "5", "nationality": "Indian", "stats": "DNP"}
            ]
        },
        "PUN": {
            "playingXI": [
                {"name": "Aslam Inamdar", "role": "All-Rounder", "number": "10", "nationality": "Indian", "stats": "Captain, All-Rounder"},
                {"name": "Mohit Goyat", "role": "Raider", "number": "9", "nationality": "Indian", "stats": "Speed Raider"},
                {"name": "Pankaj Mohite", "role": "Raider", "number": "11", "nationality": "Indian", "stats": "Support Raider"},
                {"name": "Mohammadreza Shadloui Chiyaneh", "role": "All-Rounder", "number": "1", "nationality": "Iranian", "stats": "Left Corner, Record Signing"},
                {"name": "Gaurav Khatri", "role": "Defender - Right Corner", "number": "2", "nationality": "Indian", "stats": "Right Corner"},
                {"name": "Sanket Sawant", "role": "Defender - Left Cover", "number": "3", "nationality": "Indian", "stats": "Left Cover"},
                {"name": "Abinesh Nadarajan", "role": "Defender - Right Cover", "number": "4", "nationality": "Indian", "stats": "Right Cover"}
            ],
            "bench": [
                {"name": "Aditya Shinde", "role": "Raider", "number": "12", "nationality": "Indian", "stats": "DNP"},
                {"name": "Badal Singh", "role": "Defender", "number": "5", "nationality": "Indian", "stats": "DNP"}
            ]
        }
    }
    
    t1_roster = rosters.get(t1_short, {"playingXI": [], "bench": []})
    t2_roster = rosters.get(t2_short, {"playingXI": [], "bench": []})
    
    # Live tracker state for Patna vs U Mumba
    live_state = None
    if match_id == 88001:
        live_state = {
            "status": "LIVE - 2nd Half",
            "timeRemaining": "05:14",
            "raidPoints": {"home": 18, "away": 15},
            "tacklePoints": {"home": 8, "away": 7},
            "allOutPoints": {"home": 2, "away": 2},
            "extraPoints": {"home": 0, "away": 2},
            "activeRaid": {
                "raider": "Sudhakar M (PAT)",
                "status": "In Progress",
                "defendersActive": 5
            }
        }
        
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
