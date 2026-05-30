import requests

try:
    print("Testing backend team logo proxy (MI: 860053)...")
    r = requests.get("http://localhost:8000/api/cricket/img/team/860053", timeout=5)
    print("Proxy Status:", r.status_code)
    print("Content size:", len(r.content))
    print("Content-Type:", r.headers.get("content-type"))
except Exception as e:
    print("Error:", e)
