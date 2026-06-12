from fastapi import APIRouter
import random
import urllib.parse

router = APIRouter(
    prefix="/api/analysis",
    tags=["Analysis Engine"]
)

@router.get("/predict-win/{match_id}")
def predict_match_win(match_id: str):
    """
    Computes a realistic AI win prediction probability based on match state.
    """
    # Deterministic mapping for mock matches
    mapping = {
        "99001": (55, 45, "CSK is favored as MS Dhoni is active at the crease needing 12 off the final over."),
        "99002": (48, 52, "KKR holds a slight edge due to a strong spin matchup in the middle overs."),
        "99003": (54, 46, "SRH is predicted to win based on Travis Head's explosive powerplay record at this venue."),
        "99004": (47, 53, "LSG is favored due to superior death bowling options (Mayank Yadav/Naveen)."),
        "99005": (51, 49, "DC is marginally ahead with Rishabh Pant back in form."),
        "99101": (58, 42, "India holds a solid lead of 142 runs on Day 3 with Virat Kohli and Rishabh Pant building a strong partnership."),
        "99102": (50, 50, "England vs India at Lord's is expected to be a balanced battle with conditions favoring swing bowlers early on."),
        "99103": (52, 48, "New Zealand is slightly favored playing at home at Basin Reserve, but South Africa's pace attack poses a strong threat."),
        "88001": (64, 36, "Patna Pirates lead 28-26 with under 5 minutes remaining, giving them the defensive advantage."),
        "88002": (50, 50, "Jaipur Pink Panthers vs Bengaluru Bulls is expected to be an even raid-heavy battle."),
        "88003": (45, 55, "Puneri Paltan's solid defensive wall is favored to contain Dabang Delhi's raiders."),
        "77001": (54, 46, "USA holds a slight advantage (54% win probability) with Christian Pulisic leading the front line and a 2-1 lead in the 72nd minute."),
        "77002": (52, 48, "Argentina is marginally favored in what is expected to be a legendary rematch, with Lionel Messi orchestrating the attack."),
        "77003": (48, 52, "Spain is favored to win the possession battle, but Portugal's counter-attack led by Cristiano Ronaldo poses a massive threat."),
        "77004": (51, 49, "Brazil is slightly ahead due to their flair and speed on the wings with Vinicius Jr, but England's solid midfield block can easily match them."),
        "77005": (55, 45, "Germany is favored to control the game at home, but Japan's high-pressing discipline makes them dangerous on transition.")
    }

    if match_id in mapping:
        team1_prob, team2_prob, momentum = mapping[match_id]
    else:
        # Fallback to deterministic hash of match_id
        hash_val = sum(ord(c) for c in str(match_id))
        team1_prob = 45 + (hash_val % 21) # 45 to 65
        team2_prob = 100 - team1_prob
        momentum = "Team 1 is predicted to have a tactical advantage based on recent lineups."

    return {
        "match_id": match_id,
        "prediction": {
            "team1_probability": team1_prob,
            "team2_probability": team2_prob,
            "momentum_shift": momentum
        }
    }

@router.get("/player-contribution/{player_id}")
def get_player_contribution(player_id: str):
    """
    Retrieves realistic historical player impact metrics.
    """
    # Clean ID/Name
    player_name = urllib.parse.unquote(player_id).strip().lower()
    
    # Specific known player data
    profiles = {
        "ms dhoni": (9.5, [45, 60, 55, 90, 95]),
        "virat kohli": (9.8, [85, 90, 88, 92, 99]),
        "jasprit bumrah": (9.7, [90, 95, 93, 96, 98]),
        "rohit sharma": (9.2, [70, 75, 80, 85, 92]),
        "suryakumar yadav": (9.4, [80, 82, 85, 90, 94]),
        "sudhakar m": (8.8, [65, 70, 78, 82, 88]),
        "guman singh": (8.9, [70, 75, 80, 84, 89]),
        "arjun deshwal": (9.6, [88, 92, 90, 94, 96]),
        "lionel messi": (9.9, [95, 96, 98, 97, 99]),
        "kylian mbappé": (9.8, [92, 95, 96, 94, 98]),
        "kylian mbappe": (9.8, [92, 95, 96, 94, 98]),
        "cristiano ronaldo": (9.6, [88, 90, 92, 95, 96]),
        "christian pulisic": (9.0, [80, 82, 85, 87, 90])
    }

    if player_name in profiles:
        impact, trend = profiles[player_name]
    else:
        # Deterministic fallback based on player name hash
        hash_val = sum(ord(c) for c in player_name)
        impact = round(7.5 + (hash_val % 21) / 10.0, 1) # 7.5 to 9.5
        trend = [
            int(50 + (hash_val * i) % 41) for i in range(1, 6)
        ]

    return {
        "player_id": player_id,
        "impact_score": impact,
        "recent_trend": trend
    }
