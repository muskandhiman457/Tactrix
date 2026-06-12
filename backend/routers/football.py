import requests
import time
import random
from fastapi import APIRouter
from typing import Dict, List, Optional

router = APIRouter(
    prefix="/api/football",
    tags=["Football"]
)

RAPIDAPI_HOST = "free-api-live-football-data.p.rapidapi.com"
RAPIDAPI_KEY = "a5eac63245mshc1a65cb950faebfp1c7d8ajsnc48adb31d3ee"

# Mock FIFA World Cup 2026 Matches
MOCK_WORLD_CUP_MATCHES = [
    {
        "id": "77001",
        "home": {"id": "6095", "name": "USA", "short": "USA", "score": 2},
        "away": {"id": "6088", "name": "Mexico", "short": "MEX", "score": 1},
        "notStarted": False,
        "tournamentName": "FIFA World Cup 2026",
        "venue": "Azteca Stadium, Mexico City",
        "startDate": int(time.time() * 1000) - 4500000, # started 75 mins ago
        "status": {
            "finished": False,
            "started": True,
            "reason": {
                "short": "2H 72'",
                "long": "Second Half (72')"
            }
        }
    },
    {
        "id": "77002",
        "home": {"id": "6320", "name": "Argentina", "short": "ARG", "score": 0},
        "away": {"id": "8244", "name": "France", "short": "FRA", "score": 0},
        "notStarted": True,
        "tournamentName": "FIFA World Cup 2026",
        "venue": "SoFi Stadium, Los Angeles",
        "startDate": int(time.time() * 1000) + 7200000, # starts in 2 hours
        "status": {
            "finished": False,
            "started": False,
            "reason": {
                "short": "21:00",
                "long": "Starts at 21:00 IST"
            }
        }
    },
    {
        "id": "77003",
        "home": {"id": "9907", "name": "Portugal", "short": "POR", "score": 0},
        "away": {"id": "9906", "name": "Spain", "short": "ESP", "score": 0},
        "notStarted": True,
        "tournamentName": "FIFA World Cup 2026",
        "venue": "MetLife Stadium, NY/NJ",
        "startDate": int(time.time() * 1000) + 86400000, # starts in 24 hours
        "status": {
            "finished": False,
            "started": False,
            "reason": {
                "short": "Pre",
                "long": "Upcoming Match"
            }
        }
    },
    {
        "id": "77004",
        "home": {"id": "6321", "name": "Brazil", "short": "BRA", "score": 0},
        "away": {"id": "8498", "name": "England", "short": "ENG", "score": 0},
        "notStarted": True,
        "tournamentName": "FIFA World Cup 2026",
        "venue": "Mercedes-Benz Stadium, Atlanta",
        "startDate": int(time.time() * 1000) + 172800000, # starts in 48 hours
        "status": {
            "finished": False,
            "started": False,
            "reason": {
                "short": "Pre",
                "long": "Upcoming Match"
            }
        }
    },
    {
        "id": "77005",
        "home": {"id": "8148", "name": "Germany", "short": "GER", "score": 0},
        "away": {"id": "6175", "name": "Japan", "short": "JPN", "score": 0},
        "notStarted": True,
        "tournamentName": "FIFA World Cup 2026",
        "venue": "Hard Rock Stadium, Miami",
        "startDate": int(time.time() * 1000) + 259200000, # starts in 72 hours
        "status": {
            "finished": False,
            "started": False,
            "reason": {
                "short": "Pre",
                "long": "Upcoming Match"
            }
        }
    }
]


# Database of National Teams Playing XI and Bench Rosters
WORLD_CUP_ROSTERS = {
    "USA": {
        "short": "USA",
        "playingXI": [
            {"name": "Matt Turner", "role": "GK", "number": "1", "nationality": "USA", "stats": "Saves: 3, Clean Sheets: 1"},
            {"name": "Sergiño Dest", "role": "DF", "number": "2", "nationality": "USA", "stats": "Interceptions: 4, Tackles: 2"},
            {"name": "Chris Richards", "role": "DF", "number": "3", "nationality": "USA", "stats": "Clearances: 6, Blocks: 2"},
            {"name": "Tim Ream", "role": "DF", "number": "13", "nationality": "USA", "stats": "Passing Accuracy: 91%"},
            {"name": "Antonee Robinson", "role": "DF", "number": "5", "nationality": "USA", "stats": "Crosses: 4, Key Passes: 1"},
            {"name": "Tyler Adams", "role": "MF", "number": "4", "nationality": "USA", "stats": "Recoveries: 8, Tackles: 3"},
            {"name": "Weston McKennie", "role": "MF", "number": "8", "nationality": "USA", "stats": "Assists: 1, Yellow Cards: 1"},
            {"name": "Yunus Musah", "role": "MF", "number": "6", "nationality": "USA", "stats": "Dribbles: 3, Pass Accuracy: 88%"},
            {"name": "Timothy Weah", "role": "FW", "number": "21", "nationality": "USA", "stats": "Shots: 2, Key Passes: 1"},
            {"name": "Folarin Balogun", "role": "FW", "number": "20", "nationality": "USA", "stats": "Goals: 1, Shots on Target: 2"},
            {"name": "Christian Pulisic", "role": "FW", "number": "10", "nationality": "USA", "stats": "Goals: 1, Shots: 4, Captain"}
        ],
        "bench": [
            {"name": "Ethan Horvath", "role": "GK", "number": "18", "nationality": "USA", "stats": "Did Not Play"},
            {"name": "Cameron Carter-Vickers", "role": "DF", "number": "24", "nationality": "USA", "stats": "Did Not Play"},
            {"name": "Joe Scally", "role": "DF", "number": "19", "nationality": "USA", "stats": "Did Not Play"},
            {"name": "Johnny Cardoso", "role": "MF", "number": "15", "nationality": "USA", "stats": "Did Not Play"},
            {"name": "Gio Reyna", "role": "MF", "number": "7", "nationality": "USA", "stats": "Subs on: 75', Pass Accuracy: 100%"},
            {"name": "Brenden Aaronson", "role": "MF", "number": "11", "nationality": "USA", "stats": "Did Not Play"},
            {"name": "Ricardo Pepi", "role": "FW", "number": "9", "nationality": "USA", "stats": "Did Not Play"}
        ]
    },
    "Mexico": {
        "short": "MEX",
        "playingXI": [
            {"name": "Guillermo Ochoa", "role": "GK", "number": "13", "nationality": "Mexico", "stats": "Saves: 4, Captain"},
            {"name": "Jorge Sánchez", "role": "DF", "number": "19", "nationality": "Mexico", "stats": "Tackles: 4, Blocks: 1"},
            {"name": "César Montes", "role": "DF", "number": "3", "nationality": "Mexico", "stats": "Clearances: 5"},
            {"name": "Johan Vásquez", "role": "DF", "number": "5", "nationality": "Mexico", "stats": "Interceptions: 3"},
            {"name": "Jesús Gallardo", "role": "DF", "number": "23", "nationality": "Mexico", "stats": "Tackles: 2"},
            {"name": "Edson Álvarez", "role": "MF", "number": "4", "nationality": "Mexico", "stats": "Recoveries: 7, Passing: 89%"},
            {"name": "Luis Chávez", "role": "MF", "number": "24", "nationality": "Mexico", "stats": "Shots: 3, Pass Accuracy: 84%"},
            {"name": "Orbelín Pineda", "role": "MF", "number": "17", "nationality": "Mexico", "stats": "Key Passes: 2"},
            {"name": "Uriel Antuna", "role": "FW", "number": "15", "nationality": "Mexico", "stats": "Crosses: 5, Key Passes: 1"},
            {"name": "Santiago Giménez", "role": "FW", "number": "11", "nationality": "Mexico", "stats": "Goals: 1, Shots: 3"},
            {"name": "Hirving Lozano", "role": "FW", "number": "22", "nationality": "Mexico", "stats": "Shots on Target: 1, Yellow Cards: 1"}
        ],
        "bench": [
            {"name": "Luis Malagón", "role": "GK", "number": "1", "nationality": "Mexico", "stats": "Did Not Play"},
            {"name": "Julián Araujo", "role": "DF", "number": "2", "nationality": "Mexico", "stats": "Did Not Play"},
            {"name": "Luis Romo", "role": "MF", "number": "7", "nationality": "Mexico", "stats": "Did Not Play"},
            {"name": "Erick Sánchez", "role": "MF", "number": "14", "nationality": "Mexico", "stats": "Did Not Play"},
            {"name": "César Huerta", "role": "FW", "number": "21", "nationality": "Mexico", "stats": "Subs on: 80', Dribbles: 1"},
            {"name": "Julián Quiñones", "role": "FW", "number": "16", "nationality": "Mexico", "stats": "Did Not Play"}
        ]
    },
    "Argentina": {
        "short": "ARG",
        "playingXI": [
            {"name": "Emiliano Martínez", "role": "GK", "number": "23", "nationality": "Argentina", "stats": "Saves: 0, Clean Sheets: 0"},
            {"name": "Nahuel Molina", "role": "DF", "number": "26", "nationality": "Argentina", "stats": "Tackles: 0"},
            {"name": "Cristian Romero", "role": "DF", "number": "13", "nationality": "Argentina", "stats": "Clearances: 0"},
            {"name": "Nicolás Otamendi", "role": "DF", "number": "19", "nationality": "Argentina", "stats": "Clearances: 0"},
            {"name": "Nicolás Tagliafico", "role": "DF", "number": "3", "nationality": "Argentina", "stats": "Tackles: 0"},
            {"name": "Rodrigo De Paul", "role": "MF", "number": "7", "nationality": "Argentina", "stats": "Passes: 0"},
            {"name": "Enzo Fernández", "role": "MF", "number": "24", "nationality": "Argentina", "stats": "Passes: 0"},
            {"name": "Alexis Mac Allister", "role": "MF", "number": "20", "nationality": "Argentina", "stats": "Passes: 0"},
            {"name": "Lionel Messi", "role": "FW", "number": "10", "nationality": "Argentina", "stats": "Shots: 0, Captain"},
            {"name": "Lautaro Martínez", "role": "FW", "number": "22", "nationality": "Argentina", "stats": "Goals: 0"},
            {"name": "Julián Álvarez", "role": "FW", "number": "9", "nationality": "Argentina", "stats": "Shots: 0"}
        ],
        "bench": [
            {"name": "Gerónimo Rulli", "role": "GK", "number": "1", "nationality": "Argentina", "stats": "Did Not Play"},
            {"name": "Gonzalo Montiel", "role": "DF", "number": "4", "nationality": "Argentina", "stats": "Did Not Play"},
            {"name": "Lisandro Martínez", "role": "DF", "number": "25", "nationality": "Argentina", "stats": "Did Not Play"},
            {"name": "Leandro Paredes", "role": "MF", "number": "5", "nationality": "Argentina", "stats": "Did Not Play"},
            {"name": "Giovani Lo Celso", "role": "MF", "number": "16", "nationality": "Argentina", "stats": "Did Not Play"},
            {"name": "Angel Di María", "role": "FW", "number": "11", "nationality": "Argentina", "stats": "Did Not Play"},
            {"name": "Alejandro Garnacho", "role": "FW", "number": "17", "nationality": "Argentina", "stats": "Did Not Play"}
        ]
    },
    "France": {
        "short": "FRA",
        "playingXI": [
            {"name": "Mike Maignan", "role": "GK", "number": "16", "nationality": "France", "stats": "Saves: 0"},
            {"name": "Jules Koundé", "role": "DF", "number": "5", "nationality": "France", "stats": "Tackles: 0"},
            {"name": "Dayot Upamecano", "role": "DF", "number": "4", "nationality": "France", "stats": "Blocks: 0"},
            {"name": "William Saliba", "role": "DF", "number": "17", "nationality": "France", "stats": "Clearances: 0"},
            {"name": "Theo Hernández", "role": "DF", "number": "22", "nationality": "France", "stats": "Crosses: 0"},
            {"name": "Aurélien Tchouaméni", "role": "MF", "number": "8", "nationality": "France", "stats": "Recoveries: 0"},
            {"name": "N'Golo Kanté", "role": "MF", "number": "13", "nationality": "France", "stats": "Tackles: 0"},
            {"name": "Antoine Griezmann", "role": "MF", "number": "7", "nationality": "France", "stats": "Key Passes: 0"},
            {"name": "Ousmane Dembélé", "role": "FW", "number": "11", "nationality": "France", "stats": "Dribbles: 0"},
            {"name": "Kylian Mbappé", "role": "FW", "number": "10", "nationality": "France", "stats": "Shots: 0, Captain"},
            {"name": "Bradley Barcola", "role": "FW", "number": "25", "nationality": "France", "stats": "Shots: 0"}
        ],
        "bench": [
            {"name": "Brice Samba", "role": "GK", "number": "1", "nationality": "France", "stats": "Did Not Play"},
            {"name": "Benjamin Pavard", "role": "DF", "number": "2", "nationality": "France", "stats": "Did Not Play"},
            {"name": "Ibrahima Konaté", "role": "DF", "number": "24", "nationality": "France", "stats": "Did Not Play"},
            {"name": "Eduardo Camavinga", "role": "MF", "number": "6", "nationality": "France", "stats": "Did Not Play"},
            {"name": "Youssouf Fofana", "role": "MF", "number": "19", "nationality": "France", "stats": "Did Not Play"},
            {"name": "Kingsley Coman", "role": "FW", "number": "20", "nationality": "France", "stats": "Did Not Play"},
            {"name": "Olivier Giroud", "role": "FW", "number": "9", "nationality": "France", "stats": "Did Not Play"}
        ]
    },
    "Portugal": {
        "short": "POR",
        "playingXI": [
            {"name": "Diogo Costa", "role": "GK", "number": "22", "nationality": "Portugal", "stats": "Saves: 0"},
            {"name": "Diogo Dalot", "role": "DF", "number": "2", "nationality": "Portugal", "stats": "Tackles: 0"},
            {"name": "Rúben Dias", "role": "DF", "number": "4", "nationality": "Portugal", "stats": "Clearances: 0"},
            {"name": "António Silva", "role": "DF", "number": "24", "nationality": "Portugal", "stats": "Blocks: 0"},
            {"name": "João Cancelo", "role": "DF", "number": "20", "nationality": "Portugal", "stats": "Crosses: 0"},
            {"name": "João Neves", "role": "MF", "number": "15", "nationality": "Portugal", "stats": "Recoveries: 0"},
            {"name": "João Palhinha", "role": "MF", "number": "6", "nationality": "Portugal", "stats": "Tackles: 0"},
            {"name": "Bruno Fernandes", "role": "MF", "number": "8", "nationality": "Portugal", "stats": "Key Passes: 0"},
            {"name": "Bernardo Silva", "role": "FW", "number": "10", "nationality": "Portugal", "stats": "Key Passes: 0"},
            {"name": "Cristiano Ronaldo", "role": "FW", "number": "7", "nationality": "Portugal", "stats": "Shots: 0, Captain"},
            {"name": "Rafael Leão", "role": "FW", "number": "17", "nationality": "Portugal", "stats": "Dribbles: 0"}
        ],
        "bench": [
            {"name": "Rui Patrício", "role": "GK", "number": "1", "nationality": "Portugal", "stats": "Did Not Play"},
            {"name": "Pepe", "role": "DF", "number": "3", "nationality": "Portugal", "stats": "Did Not Play"},
            {"name": "Nuno Mendes", "role": "DF", "number": "19", "nationality": "Portugal", "stats": "Did Not Play"},
            {"name": "Vitinha", "role": "MF", "number": "23", "nationality": "Portugal", "stats": "Did Not Play"},
            {"name": "Otávio", "role": "MF", "number": "25", "nationality": "Portugal", "stats": "Did Not Play"},
            {"name": "João Félix", "role": "FW", "number": "11", "nationality": "Portugal", "stats": "Did Not Play"},
            {"name": "Gonçalo Ramos", "role": "FW", "number": "9", "nationality": "Portugal", "stats": "Did Not Play"}
        ]
    },
    "Spain": {
        "short": "ESP",
        "playingXI": [
            {"name": "Unai Simón", "role": "GK", "number": "23", "nationality": "Spain", "stats": "Saves: 0"},
            {"name": "Dani Carvajal", "role": "DF", "number": "2", "nationality": "Spain", "stats": "Tackles: 0"},
            {"name": "Robin Le Normand", "role": "DF", "number": "3", "nationality": "Spain", "stats": "Clearances: 0"},
            {"name": "Aymeric Laporte", "role": "DF", "number": "14", "nationality": "Spain", "stats": "Blocks: 0"},
            {"name": "Marc Cucurella", "role": "DF", "number": "24", "nationality": "Spain", "stats": "Tackles: 0"},
            {"name": "Rodri", "role": "MF", "number": "16", "nationality": "Spain", "stats": "Passes: 0, Captain"},
            {"name": "Fabián Ruiz", "role": "MF", "number": "8", "nationality": "Spain", "stats": "Passes: 0"},
            {"name": "Pedri", "role": "MF", "number": "20", "nationality": "Spain", "stats": "Passes: 0"},
            {"name": "Lamine Yamal", "role": "FW", "number": "19", "nationality": "Spain", "stats": "Dribbles: 0"},
            {"name": "Álvaro Morata", "role": "FW", "number": "7", "nationality": "Spain", "stats": "Shots: 0"},
            {"name": "Nico Williams", "role": "FW", "number": "17", "nationality": "Spain", "stats": "Shots: 0"}
        ],
        "bench": [
            {"name": "David Raya", "role": "GK", "number": "1", "nationality": "Spain", "stats": "Did Not Play"},
            {"name": "Nacho", "role": "DF", "number": "4", "nationality": "Spain", "stats": "Did Not Play"},
            {"name": "Alejandro Grimaldo", "role": "DF", "number": "12", "nationality": "Spain", "stats": "Did Not Play"},
            {"name": "Martín Zubimendi", "role": "MF", "number": "18", "nationality": "Spain", "stats": "Did Not Play"},
            {"name": "Dani Olmo", "role": "MF", "number": "10", "nationality": "Spain", "stats": "Did Not Play"},
            {"name": "Ferran Torres", "role": "FW", "number": "11", "nationality": "Spain", "stats": "Did Not Play"},
            {"name": "Ayoze Pérez", "role": "FW", "number": "9", "nationality": "Spain", "stats": "Did Not Play"}
        ]
    },
    "Brazil": {
        "short": "BRA",
        "playingXI": [
            {"name": "Alisson Becker", "role": "GK", "number": "1", "nationality": "Brazil", "stats": "Saves: 0"},
            {"name": "Danilo", "role": "DF", "number": "2", "nationality": "Brazil", "stats": "Tackles: 0, Captain"},
            {"name": "Marquinhos", "role": "DF", "number": "3", "nationality": "Brazil", "stats": "Clearances: 0"},
            {"name": "Gabriel Magalhães", "role": "DF", "number": "4", "nationality": "Brazil", "stats": "Blocks: 0"},
            {"name": "Wendell", "role": "DF", "number": "6", "nationality": "Brazil", "stats": "Tackles: 0"},
            {"name": "Bruno Guimarães", "role": "MF", "number": "5", "nationality": "Brazil", "stats": "Passes: 0"},
            {"name": "João Gomes", "role": "MF", "number": "15", "nationality": "Brazil", "stats": "Tackles: 0"},
            {"name": "Lucas Paquetá", "role": "MF", "number": "8", "nationality": "Brazil", "stats": "Key Passes: 0"},
            {"name": "Raphinha", "role": "FW", "number": "11", "nationality": "Brazil", "stats": "Crosses: 0"},
            {"name": "Rodrygo", "role": "FW", "number": "10", "nationality": "Brazil", "stats": "Shots: 0"},
            {"name": "Vinícius Júnior", "role": "FW", "number": "7", "nationality": "Brazil", "stats": "Dribbles: 0"}
        ],
        "bench": [
            {"name": "Bento", "role": "GK", "number": "12", "nationality": "Brazil", "stats": "Did Not Play"},
            {"name": "Éder Militão", "role": "DF", "number": "14", "nationality": "Brazil", "stats": "Did Not Play"},
            {"name": "Guilherme Arana", "role": "DF", "number": "16", "nationality": "Brazil", "stats": "Did Not Play"},
            {"name": "Douglas Luiz", "role": "MF", "number": "18", "nationality": "Brazil", "stats": "Did Not Play"},
            {"name": "Andreas Pereira", "role": "MF", "number": "19", "nationality": "Brazil", "stats": "Did Not Play"},
            {"name": "Endrick", "role": "FW", "number": "9", "nationality": "Brazil", "stats": "Did Not Play"},
            {"name": "Gabriel Martinelli", "role": "FW", "number": "22", "nationality": "Brazil", "stats": "Did Not Play"}
        ]
    },
    "England": {
        "short": "ENG",
        "playingXI": [
            {"name": "Jordan Pickford", "role": "GK", "number": "1", "nationality": "England", "stats": "Saves: 0"},
            {"name": "Kyle Walker", "role": "DF", "number": "2", "nationality": "England", "stats": "Tackles: 0"},
            {"name": "John Stones", "role": "DF", "number": "5", "nationality": "England", "stats": "Clearances: 0"},
            {"name": "Marc Guéhi", "role": "DF", "number": "6", "nationality": "England", "stats": "Blocks: 0"},
            {"name": "Kieran Trippier", "role": "DF", "number": "12", "nationality": "England", "stats": "Crosses: 0"},
            {"name": "Kobbie Mainoo", "role": "MF", "number": "26", "nationality": "England", "stats": "Passing: 0"},
            {"name": "Declan Rice", "role": "MF", "number": "4", "nationality": "England", "stats": "Recoveries: 0"},
            {"name": "Jude Bellingham", "role": "MF", "number": "10", "nationality": "England", "stats": "Key Passes: 0"},
            {"name": "Bukayo Saka", "role": "FW", "number": "7", "nationality": "England", "stats": "Dribbles: 0"},
            {"name": "Harry Kane", "role": "FW", "number": "9", "nationality": "England", "stats": "Shots: 0, Captain"},
            {"name": "Phil Foden", "role": "FW", "number": "11", "nationality": "England", "stats": "Shots: 0"}
        ],
        "bench": [
            {"name": "Aaron Ramsdale", "role": "GK", "number": "13", "nationality": "England", "stats": "Did Not Play"},
            {"name": "Ezri Konsa", "role": "DF", "number": "14", "nationality": "England", "stats": "Did Not Play"},
            {"name": "Trent Alexander-Arnold", "role": "DF", "number": "8", "nationality": "England", "stats": "Did Not Play"},
            {"name": "Conor Gallagher", "role": "MF", "number": "16", "nationality": "England", "stats": "Did Not Play"},
            {"name": "Cole Palmer", "role": "MF", "number": "21", "nationality": "England", "stats": "Did Not Play"},
            {"name": "Eberechi Eze", "role": "FW", "number": "20", "nationality": "England", "stats": "Did Not Play"},
            {"name": "Ollie Watkins", "role": "FW", "number": "19", "nationality": "England", "stats": "Did Not Play"}
        ]
    },
    "Germany": {
        "short": "GER",
        "playingXI": [
            {"name": "Manuel Neuer", "role": "GK", "number": "1", "nationality": "Germany", "stats": "Saves: 0"},
            {"name": "Joshua Kimmich", "role": "DF", "number": "6", "nationality": "Germany", "stats": "Key Passes: 0"},
            {"name": "Antonio Rüdiger", "role": "DF", "number": "2", "nationality": "Germany", "stats": "Clearances: 0"},
            {"name": "Jonathan Tah", "role": "DF", "number": "4", "nationality": "Germany", "stats": "Blocks: 0"},
            {"name": "Maximilian Mittelstädt", "role": "DF", "number": "3", "nationality": "Germany", "stats": "Crosses: 0"},
            {"name": "Robert Andrich", "role": "MF", "number": "23", "nationality": "Germany", "stats": "Tackles: 0"},
            {"name": "Toni Kroos", "role": "MF", "number": "8", "nationality": "Germany", "stats": "Passes: 0"},
            {"name": "Ilkay Gündogan", "role": "MF", "number": "21", "nationality": "Germany", "stats": "Key Passes: 0, Captain"},
            {"name": "Jamal Musiala", "role": "FW", "number": "10", "nationality": "Germany", "stats": "Dribbles: 0"},
            {"name": "Kai Havertz", "role": "FW", "number": "7", "nationality": "Germany", "stats": "Shots: 0"},
            {"name": "Florian Wirtz", "role": "FW", "number": "17", "nationality": "Germany", "stats": "Shots: 0"}
        ],
        "bench": [
            {"name": "Marc-André ter Stegen", "role": "GK", "number": "22", "nationality": "Germany", "stats": "Did Not Play"},
            {"name": "Waldemar Anton", "role": "DF", "number": "24", "nationality": "Germany", "stats": "Did Not Play"},
            {"name": "David Raum", "role": "DF", "number": "15", "nationality": "Germany", "stats": "Did Not Play"},
            {"name": "Pascal Gross", "role": "MF", "number": "5", "nationality": "Germany", "stats": "Did Not Play"},
            {"name": "Leroy Sané", "role": "FW", "number": "19", "nationality": "Germany", "stats": "Did Not Play"},
            {"name": "Thomas Müller", "role": "FW", "number": "13", "nationality": "Germany", "stats": "Did Not Play"},
            {"name": "Niclas Füllkrug", "role": "FW", "number": "9", "nationality": "Germany", "stats": "Did Not Play"}
        ]
    },
    "Japan": {
        "short": "JPN",
        "playingXI": [
            {"name": "Zion Suzuki", "role": "GK", "number": "1", "nationality": "Japan", "stats": "Saves: 0"},
            {"name": "Yukinari Sugawara", "role": "DF", "number": "2", "nationality": "Japan", "stats": "Tackles: 0"},
            {"name": "Ko Itakura", "role": "DF", "number": "4", "nationality": "Japan", "stats": "Clearances: 0"},
            {"name": "Koki Machida", "role": "DF", "number": "15", "nationality": "Japan", "stats": "Blocks: 0"},
            {"name": "Hiroki Ito", "role": "DF", "number": "21", "nationality": "Japan", "stats": "Crosses: 0"},
            {"name": "Wataru Endo", "role": "MF", "number": "6", "nationality": "Japan", "stats": "Tackles: 0, Captain"},
            {"name": "Hidemasa Morita", "role": "MF", "number": "5", "nationality": "Japan", "stats": "Passes: 0"},
            {"name": "Takefusa Kubo", "role": "MF", "number": "20", "nationality": "Japan", "stats": "Key Passes: 0"},
            {"name": "Takumi Minamino", "role": "FW", "number": "8", "nationality": "Japan", "stats": "Shots: 0"},
            {"name": "Kaoru Mitoma", "role": "FW", "number": "7", "nationality": "Japan", "stats": "Dribbles: 0"},
            {"name": "Ayase Ueda", "role": "FW", "number": "9", "nationality": "Japan", "stats": "Goals: 0"}
        ],
        "bench": [
            {"name": "Daiya Maekawa", "role": "GK", "number": "23", "nationality": "Japan", "stats": "Did Not Play"},
            {"name": "Shogo Taniguchi", "role": "DF", "number": "3", "nationality": "Japan", "stats": "Did Not Play"},
            {"name": "Takehiro Tomiyasu", "role": "DF", "number": "22", "nationality": "Japan", "stats": "Did Not Play"},
            {"name": "Ao Tanaka", "role": "MF", "number": "17", "nationality": "Japan", "stats": "Did Not Play"},
            {"name": "Daichi Kamada", "role": "MF", "number": "14", "nationality": "Japan", "stats": "Did Not Play"},
            {"name": "Ritsu Doan", "role": "FW", "number": "10", "nationality": "Japan", "stats": "Did Not Play"},
            {"name": "Daizen Maeda", "role": "FW", "number": "11", "nationality": "Japan", "stats": "Did Not Play"}
        ]
    }
}

# Live match simulation state (for USA vs Mexico, ID 77001)
SIMULATION_STATE = {
    "initialized": False,
    "last_update_time": 0.0,
    "elapsed_minutes": 72,
    "home_score": 2,
    "away_score": 1,
    "events": [
        {"time": "14'", "type": "goal", "player": "Christian Pulisic (USA)", "team": "home", "detail": "Assist by Weston McKennie"},
        {"time": "38'", "type": "goal", "player": "Santiago Giménez (MEX)", "team": "away", "detail": "Header from a corner kick"},
        {"time": "65'", "type": "goal", "player": "Folarin Balogun (USA)", "team": "home", "detail": "Low shot into the bottom corner"},
        {"time": "68'", "type": "yellow", "player": "Weston McKennie (USA)", "team": "home", "detail": "Tactical foul"}
    ],
    "stats": {
        "possession": {"home": 54, "away": 46},
        "shots": {"home": 14, "away": 10},
        "shotsOnTarget": {"home": 6, "away": 4},
        "corners": {"home": 6, "away": 4},
        "fouls": {"home": 11, "away": 13},
        "saves": {"home": 3, "away": 4},
        "offside": {"home": 2, "away": 1},
        "yellowCards": {"home": 1, "away": 2},
        "redCards": {"home": 0, "away": 0},
    },
    "player_stats": {
        "Christian Pulisic": {"goals": 1, "shots": 4, "key_passes": 2},
        "Folarin Balogun": {"goals": 1, "shots": 2, "key_passes": 0},
        "Santiago Giménez": {"goals": 1, "shots": 3, "key_passes": 0},
        "Matt Turner": {"saves": 3},
        "Guillermo Ochoa": {"saves": 4},
        "Weston McKennie": {"assists": 1, "yellow_cards": 1},
        "Timothy Weah": {"shots": 2, "key_passes": 1},
        "Edson Álvarez": {"recoveries": 7, "tackles": 3},
        "Hirving Lozano": {"shots_on_target": 1, "yellow_cards": 1},
    }
}

def clamp(val, minimum, maximum):
    return max(minimum, min(val, maximum))

def progress_live_match_simulation():
    global SIMULATION_STATE
    now = time.time()
    
    if not SIMULATION_STATE["initialized"]:
        SIMULATION_STATE["initialized"] = True
        SIMULATION_STATE["last_update_time"] = now
        return
        
    elapsed = now - SIMULATION_STATE["last_update_time"]
    # 15 seconds of real time = 1 minute of match time
    minutes_to_add = int(elapsed / 15)
    
    if minutes_to_add > 0:
        SIMULATION_STATE["last_update_time"] += minutes_to_add * 15
        
        for _ in range(minutes_to_add):
            if SIMULATION_STATE["elapsed_minutes"] >= 95:
                # Reset simulation loop
                SIMULATION_STATE["elapsed_minutes"] = 70
                SIMULATION_STATE["home_score"] = 2
                SIMULATION_STATE["away_score"] = 1
                SIMULATION_STATE["events"] = [
                    {"time": "14'", "type": "goal", "player": "Christian Pulisic (USA)", "team": "home", "detail": "Assist by Weston McKennie"},
                    {"time": "38'", "type": "goal", "player": "Santiago Giménez (MEX)", "team": "away", "detail": "Header from a corner kick"},
                    {"time": "65'", "type": "goal", "player": "Folarin Balogun (USA)", "team": "home", "detail": "Low shot into the bottom corner"},
                    {"time": "68'", "type": "yellow", "player": "Weston McKennie (USA)", "team": "home", "detail": "Tactical foul"}
                ]
                SIMULATION_STATE["stats"] = {
                    "possession": {"home": 54, "away": 46},
                    "shots": {"home": 14, "away": 10},
                    "shotsOnTarget": {"home": 6, "away": 4},
                    "corners": {"home": 6, "away": 4},
                    "fouls": {"home": 11, "away": 13},
                    "saves": {"home": 3, "away": 4},
                    "offside": {"home": 2, "away": 1},
                    "yellowCards": {"home": 1, "away": 2},
                    "redCards": {"home": 0, "away": 0},
                }
                SIMULATION_STATE["player_stats"] = {
                    "Christian Pulisic": {"goals": 1, "shots": 4, "key_passes": 2},
                    "Folarin Balogun": {"goals": 1, "shots": 2, "key_passes": 0},
                    "Santiago Giménez": {"goals": 1, "shots": 3, "key_passes": 0},
                    "Matt Turner": {"saves": 3},
                    "Guillermo Ochoa": {"saves": 4},
                    "Weston McKennie": {"assists": 1, "yellow_cards": 1},
                    "Timothy Weah": {"shots": 2, "key_passes": 1},
                    "Edson Álvarez": {"recoveries": 7, "tackles": 3},
                    "Hirving Lozano": {"shots_on_target": 1, "yellow_cards": 1},
                }
                break
                
            SIMULATION_STATE["elapsed_minutes"] += 1
            minute = SIMULATION_STATE["elapsed_minutes"]
            
            # Fluctuate possession slightly
            poss_change = random.randint(-2, 2)
            SIMULATION_STATE["stats"]["possession"]["home"] = clamp(SIMULATION_STATE["stats"]["possession"]["home"] + poss_change, 35, 65)
            SIMULATION_STATE["stats"]["possession"]["away"] = 100 - SIMULATION_STATE["stats"]["possession"]["home"]
            
            # 30% chance of a minor event
            r = random.random()
            if r < 0.30:
                event_type = random.choice(["foul", "corner", "offside", "shot"])
                is_home = random.random() < 0.55
                team_side = "home" if is_home else "away"
                opp_side = "away" if is_home else "home"
                
                if event_type == "foul":
                    SIMULATION_STATE["stats"]["fouls"][team_side] += 1
                elif event_type == "corner":
                    SIMULATION_STATE["stats"]["corners"][team_side] += 1
                elif event_type == "offside":
                    SIMULATION_STATE["stats"]["offside"][team_side] += 1
                elif event_type == "shot":
                    SIMULATION_STATE["stats"]["shots"][team_side] += 1
                    if random.random() < 0.40:
                        SIMULATION_STATE["stats"]["shotsOnTarget"][team_side] += 1
                        SIMULATION_STATE["stats"]["saves"][opp_side] += 1
                        gk_name = "Matt Turner" if opp_side == "home" else "Guillermo Ochoa"
                        if gk_name in SIMULATION_STATE["player_stats"]:
                            SIMULATION_STATE["player_stats"][gk_name]["saves"] = SIMULATION_STATE["player_stats"].get(gk_name, {}).get("saves", 0) + 1
                        
                        shooter = random.choice(["Christian Pulisic", "Folarin Balogun", "Timothy Weah"]) if is_home else random.choice(["Santiago Giménez", "Hirving Lozano", "Uriel Antuna"])
                        if shooter not in SIMULATION_STATE["player_stats"]:
                            SIMULATION_STATE["player_stats"][shooter] = {"goals": 0, "shots": 0, "key_passes": 0}
                        SIMULATION_STATE["player_stats"][shooter]["shots"] = SIMULATION_STATE["player_stats"][shooter].get("shots", 0) + 1
            
            # 6% chance of a yellow card
            elif r < 0.36:
                is_home = random.random() < 0.50
                team_side = "home" if is_home else "away"
                SIMULATION_STATE["stats"]["yellowCards"][team_side] += 1
                card_player = random.choice(["Tyler Adams", "Sergiño Dest", "Yunus Musah"]) if is_home else random.choice(["Jorge Sánchez", "Edson Álvarez", "Johan Vásquez"])
                SIMULATION_STATE["events"].append({
                    "time": f"{minute}'",
                    "type": "yellow",
                    "player": f"{card_player} ({'USA' if is_home else 'MEX'})",
                    "team": team_side,
                    "detail": "Foul stopping a counter-attack"
                })
                if card_player not in SIMULATION_STATE["player_stats"]:
                    SIMULATION_STATE["player_stats"][card_player] = {}
                SIMULATION_STATE["player_stats"][card_player]["yellow_cards"] = SIMULATION_STATE["player_stats"][card_player].get("yellow_cards", 0) + 1

            # 4% chance of a goal
            elif r < 0.40:
                is_home = random.random() < 0.60
                team_side = "home" if is_home else "away"
                team_short = "USA" if is_home else "MEX"
                
                if is_home:
                    SIMULATION_STATE["home_score"] += 1
                else:
                    SIMULATION_STATE["away_score"] += 1
                    
                scorer = random.choice(["Christian Pulisic", "Folarin Balogun", "Weston McKennie"]) if is_home else random.choice(["Santiago Giménez", "Hirving Lozano", "Luis Chávez"])
                assist_player = random.choice(["Timothy Weah", "Yunus Musah", "Sergiño Dest"]) if is_home else random.choice(["Orbelín Pineda", "Uriel Antuna", "Edson Álvarez"])
                
                if scorer not in SIMULATION_STATE["player_stats"]:
                    SIMULATION_STATE["player_stats"][scorer] = {"goals": 0, "shots": 0}
                SIMULATION_STATE["player_stats"][scorer]["goals"] = SIMULATION_STATE["player_stats"][scorer].get("goals", 0) + 1
                SIMULATION_STATE["player_stats"][scorer]["shots"] = SIMULATION_STATE["player_stats"][scorer].get("shots", 0) + 1
                
                if assist_player not in SIMULATION_STATE["player_stats"]:
                    SIMULATION_STATE["player_stats"][assist_player] = {"assists": 0}
                SIMULATION_STATE["player_stats"][assist_player]["assists"] = SIMULATION_STATE["player_stats"][assist_player].get("assists", 0) + 1
                
                SIMULATION_STATE["events"].append({
                    "time": f"{minute}'",
                    "type": "goal",
                    "player": f"{scorer} ({team_short})",
                    "team": team_side,
                    "detail": f"Goal scored! Assisted by {assist_player}."
                })
                
        # Update mock match score and status
        MOCK_WORLD_CUP_MATCHES[0]["home"]["score"] = SIMULATION_STATE["home_score"]
        MOCK_WORLD_CUP_MATCHES[0]["away"]["score"] = SIMULATION_STATE["away_score"]
        MOCK_WORLD_CUP_MATCHES[0]["status"]["reason"]["short"] = f"2H {SIMULATION_STATE['elapsed_minutes']}'"
        MOCK_WORLD_CUP_MATCHES[0]["status"]["reason"]["long"] = f"Second Half ({SIMULATION_STATE['elapsed_minutes']}')"

def get_updated_player_stats(player_name, role, default_stats):
    if player_name not in SIMULATION_STATE["player_stats"]:
        return default_stats
    
    p_sim = SIMULATION_STATE["player_stats"][player_name]
    
    if role == "GK":
        saves = p_sim.get("saves", 3)
        return f"Saves: {saves}, Clean Sheets: 0"
        
    parts = []
    if "goals" in p_sim or "goals" in default_stats:
        goals = p_sim.get("goals", 0)
        parts.append(f"Goals: {goals}")
    if "assists" in p_sim:
        assists = p_sim.get("assists", 0)
        parts.append(f"Assists: {assists}")
    if "shots" in p_sim or "shots" in default_stats:
        shots = p_sim.get("shots", 4 if player_name == "Christian Pulisic" else (3 if player_name == "Santiago Giménez" else 2))
        parts.append(f"Shots: {shots}")
    if "yellow_cards" in p_sim:
        yc = p_sim.get("yellow_cards", 0)
        parts.append(f"Yellow Cards: {yc}")
    if "key_passes" in p_sim:
        kp = p_sim.get("key_passes", 0)
        parts.append(f"Key Passes: {kp}")
        
    if not parts:
        return default_stats
        
    suffix = ", Captain" if "Captain" in default_stats else ""
    return ", ".join(parts) + suffix

@router.get("/players/search")
def search_football_players(search: str = "m"):
    url = f"https://{RAPIDAPI_HOST}/football-players-search"
    querystring = {"search": search}
    headers = {
        "x-rapidapi-host": RAPIDAPI_HOST,
        "x-rapidapi-key": RAPIDAPI_KEY
    }
    
    try:
        response = requests.get(url, headers=headers, params=querystring, timeout=5)
        if response.status_code == 200:
            data = response.json()
            if data.get("status") == "success" and data.get("results"):
                return data
    except Exception:
        pass
        
    # Local fallback search over national teams rosters
    search_lower = search.lower()
    local_results = []
    seen_names = set()
    
    for team_name, roster in WORLD_CUP_ROSTERS.items():
        all_players = roster.get("playingXI", []) + roster.get("bench", [])
        for p in all_players:
            p_name = p.get("name", "")
            if search_lower in p_name.lower():
                if p_name not in seen_names:
                    seen_names.add(p_name)
                    local_results.append({
                        "id": p.get("number", "10"),
                        "name": p_name,
                        "role": p.get("role", "FW"),
                        "team": team_name,
                        "nationality": p.get("nationality", team_name)
                    })
                    
    return {"status": "success", "results": local_results[:20]}

@router.get("/matches/live")
def get_live_football_matches():
    progress_live_match_simulation()
    return {"status": "success", "matches": [MOCK_WORLD_CUP_MATCHES[0]]}

@router.get("/leagues/popular")
def get_popular_leagues():
    # Return mock world cup tournament as popular league
    return {
        "status": "success",
        "leagues": [
            {"id": "wc2026", "name": "FIFA World Cup 2026", "logo": "https://images.fotmob.com/image_resources/logo/leaguelogo/42.png"}
        ]
    }

@router.get("/matches/by-date")
def get_matches_by_date(date: str):
    progress_live_match_simulation()
    return {"status": "success", "matches": MOCK_WORLD_CUP_MATCHES}

@router.get("/matches/by-league")
def get_matches_by_league(leagueid: str):
    progress_live_match_simulation()
    return {"status": "success", "matches": MOCK_WORLD_CUP_MATCHES, "response": {"matches": MOCK_WORLD_CUP_MATCHES}}

@router.get("/matches/live-and-upcoming")
def get_live_and_upcoming_football_matches():
    progress_live_match_simulation()
    return {"status": "success", "matches": MOCK_WORLD_CUP_MATCHES}

@router.get("/match/{match_id}/scorecard")
def get_football_scorecard(match_id: int):
    progress_live_match_simulation()
    
    # Mapping for teams details
    mapping = {
        77001: ("USA", "Mexico"),
        77002: ("Argentina", "France"),
        77003: ("Portugal", "Spain"),
        77004: ("Brazil", "England"),
        77005: ("Germany", "Japan")
    }
    
    if match_id not in mapping:
        return {"status": "error", "message": "World Cup match scorecard not found", "teams": {}}
        
    t1_name, t2_name = mapping[match_id]
    t1_roster = WORLD_CUP_ROSTERS.get(t1_name, {"playingXI": [], "bench": [], "short": t1_name[:3].upper()})
    t2_roster = WORLD_CUP_ROSTERS.get(t2_name, {"playingXI": [], "bench": [], "short": t2_name[:3].upper()})
    
    # Generate live tracking details for USA vs Mexico
    live_state = None
    if match_id == 77001:
        live_state = {
            "possession": SIMULATION_STATE["stats"]["possession"],
            "shots": SIMULATION_STATE["stats"]["shots"],
            "shotsOnTarget": SIMULATION_STATE["stats"]["shotsOnTarget"],
            "corners": SIMULATION_STATE["stats"]["corners"],
            "fouls": SIMULATION_STATE["stats"]["fouls"],
            "saves": SIMULATION_STATE["stats"]["saves"],
            "offside": SIMULATION_STATE["stats"]["offside"],
            "yellowCards": SIMULATION_STATE["stats"]["yellowCards"],
            "redCards": SIMULATION_STATE["stats"]["redCards"],
            "events": SIMULATION_STATE["events"]
        }
        
    t1_playing_updated = []
    for p in t1_roster.get("playingXI", []):
        p_copy = dict(p)
        p_copy["stats"] = get_updated_player_stats(p["name"], p["role"], p.get("stats", ""))
        t1_playing_updated.append(p_copy)
        
    t1_bench_updated = []
    for p in t1_roster.get("bench", []):
        p_copy = dict(p)
        p_copy["stats"] = get_updated_player_stats(p["name"], p["role"], p.get("stats", ""))
        t1_bench_updated.append(p_copy)

    t2_playing_updated = []
    for p in t2_roster.get("playingXI", []):
        p_copy = dict(p)
        p_copy["stats"] = get_updated_player_stats(p["name"], p["role"], p.get("stats", ""))
        t2_playing_updated.append(p_copy)
        
    t2_bench_updated = []
    for p in t2_roster.get("bench", []):
        p_copy = dict(p)
        p_copy["stats"] = get_updated_player_stats(p["name"], p["role"], p.get("stats", ""))
        t2_bench_updated.append(p_copy)

    return {
        "status": "success",
        "liveState": live_state,
        "teams": {
            t1_name: {
                "short": t1_roster.get("short", t1_name[:3].upper()),
                "players": t1_playing_updated + t1_bench_updated,
                "playingXI": t1_playing_updated,
                "bench": t1_bench_updated
            },
            t2_name: {
                "short": t2_roster.get("short", t2_name[:3].upper()),
                "players": t2_playing_updated + t2_bench_updated,
                "playingXI": t2_playing_updated,
                "bench": t2_bench_updated
            }
        }
    }

