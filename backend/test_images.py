import requests

headers = {
    "x-rapidapi-host": "cricbuzz-cricket2.p.rapidapi.com",
    "x-rapidapi-key": "a5eac63245mshc1a65cb950faebfp1c7d8ajsnc48adb31d3ee"
}

# Let's try some variations for MI (860053)
urls = [
    "https://cricbuzz-cricket2.p.rapidapi.com/img/v1/i1/c860053/i.jpg",
    "https://cricbuzz-cricket2.p.rapidapi.com/img/v1/i1/c860053/i.jpg?p=det",
    "https://cricbuzz-cricket2.p.rapidapi.com/img/v1/i1/c860053/i.jpg?p=d",
    "https://cricbuzz-cricket2.p.rapidapi.com/img/v1/i1/c860053/i.jpg?p=tb",
    "https://cricbuzz-cricket2.p.rapidapi.com/img/v1/i1/c860053/i.jpg?p=gp",
    "https://cricbuzz-cricket2.p.rapidapi.com/img/v1/i1/860053/i.jpg",
    "https://cricbuzz-cricket2.p.rapidapi.com/img/v1/i1/t860053/i.jpg",
    "https://cricbuzz-cricket2.p.rapidapi.com/img/v1/i1/p860053/i.jpg",
]

for url in urls:
    try:
        r = requests.get(url, headers=headers, timeout=5)
        print(f"URL: {url} -> Status: {r.status_code}")
        if r.status_code == 200:
            print("  Content size:", len(r.content))
            # save first few bytes
            print("  First 20 bytes:", r.content[:20])
    except Exception as e:
        print(f"URL: {url} -> Error: {e}")
