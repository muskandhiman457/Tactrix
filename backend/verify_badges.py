from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_badge_calculations():
    print("Testing badge calculation endpoint /api/community/badges/calculate...")
    
    # Test case 1: Top Predictor trigger (>75%)
    payload_1 = {
        "uid": "test_user_1",
        "prediction_accuracy_rate": 82.0,
        "chat_activity_score": 10
    }
    response = client.post("/api/community/badges/calculate", json=payload_1)
    print("Status:", response.status_code)
    data = response.json()
    print("Response:", data)
    assert data["status"] == "success"
    assert len(data["badges"]) == 1
    assert data["badges"][0]["id"] == "top_predictor"
    print("Test case 1 passed (Top Predictor with 82%).")

    # Test case 2: Super Chatter trigger (>50)
    payload_2 = {
        "uid": "test_user_2",
        "prediction_accuracy_rate": 10.0,
        "chat_activity_score": 65
    }
    response = client.post("/api/community/badges/calculate", json=payload_2)
    data = response.json()
    assert len(data["badges"]) == 1
    assert data["badges"][0]["id"] == "super_chatter"
    print("Test case 2 passed (Super Chatter with 65).")

    # Test case 3: Both triggers
    payload_3 = {
        "uid": "test_user_3",
        "prediction_accuracy_rate": 0.85, # between 0.0 and 1.0 representation
        "chat_activity_score": 75
    }
    response = client.post("/api/community/badges/calculate", json=payload_3)
    data = response.json()
    assert len(data["badges"]) == 2
    badge_ids = {b["id"] for b in data["badges"]}
    assert "top_predictor" in badge_ids
    assert "super_chatter" in badge_ids
    print("Test case 3 passed (Both badges with 0.85 rate and 75 score).")

    # Test case 4: None
    payload_4 = {
        "uid": "test_user_4",
        "prediction_accuracy_rate": 45.0,
        "chat_activity_score": 30
    }
    response = client.post("/api/community/badges/calculate", json=payload_4)
    data = response.json()
    assert len(data["badges"]) == 0
    print("Test case 4 passed (No badges under threshold).")

if __name__ == "__main__":
    try:
        test_badge_calculations()
        print("\nAll badge assignment endpoints verified successfully!")
    except Exception as e:
        print("Verification failed with error:", e)
        import traceback
        traceback.print_exc()
