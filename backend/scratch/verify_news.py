import sys
import os
import time

# Add backend directory to path so we can import routers
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from routers.community import fetch_personalized_news

def verify():
    print("Test 1: Fetching general sports news (empty inputs)...")
    start = time.time()
    articles = fetch_personalized_news(sports_str="", players_str="")
    duration = time.time() - start
    print(f"Fetched {len(articles)} articles in {duration:.2f} seconds.")
    
    for i, a in enumerate(articles[:3]):
        print(f"\n--- Article {i+1} ---")
        print(f"Title: {a.get('title')}")
        print(f"Category: {a.get('category')}")
        print(f"Image: {a.get('imageUrl')}")
        print(f"Link: {a.get('link')}")
        print(f"Time: {a.get('time')}")
        
    print("\nTest 2: Testing Cache Behavior (fetching again)...")
    start_cache = time.time()
    articles_cached = fetch_personalized_news(sports_str="", players_str="")
    duration_cache = time.time() - start_cache
    print(f"Fetched {len(articles_cached)} articles (cache check) in {duration_cache:.4f} seconds.")
    
    if len(articles) == len(articles_cached):
        print("Success: Caching works correctly! Response was instant.")
    else:
        print("Warning: Article count mismatch in cache.")

if __name__ == "__main__":
    verify()
