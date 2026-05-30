import requests

RAPIDAPI_HEADERS = {
    "x-rapidapi-host": "cricbuzz-cricket2.p.rapidapi.com",
    "x-rapidapi-key": "a5eac63245mshc1a65cb950faebfp1c7d8ajsnc48adb31d3ee"
}

match_id = 150964  # New Zealand vs Ireland

url = f"https://cricbuzz-cricket2.p.rapidapi.com/mcenter/v1/{match_id}/leanback"
try:
    r = requests.get(url, headers=RAPIDAPI_HEADERS, timeout=10)
    if r.status_code == 200:
        data = r.json()
        ms = data.get("miniscore", {})
        print("batsmanstriker:", ms.get("batsmanstriker"))
        print("batsmannonstriker:", ms.get("batsmannonstriker"))
        print("bowlerstriker:", ms.get("bowlerstriker"))
        print("bowlernonstriker:", ms.get("bowlernonstriker"))
        print("curovsstats:", ms.get("curovsstats"))
        print("crr:", ms.get("crr"))
        print("rrr:", ms.get("rrr"))
        print("target:", ms.get("target"))
        print("ballsrem:", ms.get("ballsrem"))
        print("batteamscore:", ms.get("batteamscore"))
except Exception as e:
    print("Error:", e)
