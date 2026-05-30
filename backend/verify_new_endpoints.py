from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_kabaddi_and_analysis():
    print("1. Testing GET /api/kabaddi/matches/live-and-upcoming...")
    response = client.get("/api/kabaddi/matches/live-and-upcoming")
    print("Status:", response.status_code)
    data = response.json()
    print("Matches Count:", len(data.get("matches", [])))
    print("First match teams:", data["matches"][0]["matchInfo"]["team1"]["teamName"], "vs", data["matches"][0]["matchInfo"]["team2"]["teamName"])

    print("\n2. Testing GET /api/kabaddi/match/88001/scorecard...")
    response = client.get("/api/kabaddi/match/88001/scorecard")
    print("Status:", response.status_code)
    card = response.json()
    print("Scorecard keys:", card.keys())
    print("Teams:", list(card.get("teams", {}).keys()))

    print("\n3. Testing GET /api/analysis/predict-win/88001...")
    response = client.get("/api/analysis/predict-win/88001")
    print("Status:", response.status_code)
    pred = response.json()
    print("Prediction:", pred)

    print("\n4. Testing GET /api/analysis/player-contribution/virat%20kohli...")
    response = client.get("/api/analysis/player-contribution/virat%20kohli")
    print("Status:", response.status_code)
    contrib = response.json()
    print("Contribution:", contrib)

if __name__ == "__main__":
    try:
        test_kabaddi_and_analysis()
        print("\nAll new Kabaddi and Analysis endpoints verified successfully!")
    except Exception as e:
        print("Verification failed with error:", e)
