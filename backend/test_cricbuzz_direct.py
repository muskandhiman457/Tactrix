import requests

urls = [
    # Swedish flag imageId was 248454
    "https://www.cricbuzz.com/a/img/v1/100x100/i1/c248454/i.jpg",
    "https://www.cricbuzz.com/a/img/v1/152x152/i1/c248454/i.jpg",
    "https://www.cricbuzz.com/a/img/v1/50x50/i1/c248454/i.jpg",
    # Mumbai Indians imageId was 860053
    "https://www.cricbuzz.com/a/img/v1/100x100/i1/c860053/i.jpg",
    "https://www.cricbuzz.com/a/img/v1/152x152/i1/c860053/i.jpg",
]

for url in urls:
    try:
        r = requests.get(url, timeout=5, headers={"User-Agent": "Mozilla/5.0"})
        print(f"Direct URL: {url} -> Status: {r.status_code}")
        if r.status_code == 200:
            print("  Content size:", len(r.content))
            print("  First 10 bytes:", r.content[:10])
    except Exception as e:
        print(f"Direct URL: {url} -> Error: {e}")

# Let's also test via RapidAPI if it works with dimensions
rapidapi_headers = {
    "x-rapidapi-host": "cricbuzz-cricket2.p.rapidapi.com",
    "x-rapidapi-key": "a5eac63245mshc1a65cb950faebfp1c7d8ajsnc48adb31d3ee"
}
rapid_urls = [
    "https://cricbuzz-cricket2.p.rapidapi.com/img/v1/100x100/i1/c248454/i.jpg",
    "https://cricbuzz-cricket2.p.rapidapi.com/img/v1/152x152/i1/c248454/i.jpg",
]
for url in rapid_urls:
    try:
        r = requests.get(url, headers=rapidapi_headers, timeout=5)
        print(f"RapidAPI URL: {url} -> Status: {r.status_code}")
        if r.status_code == 200:
            print("  Content size:", len(r.content))
    except Exception as e:
        print(f"RapidAPI URL: {url} -> Error: {e}")
