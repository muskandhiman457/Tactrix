import requests

BASE_URL = "https://tactrix.onrender.com"

def verify():
    print("1. Checking /health endpoint...")
    try:
        r = requests.get(f"{BASE_URL}/health", timeout=10)
        print(f"Status: {r.status_code} | Response: {r.json()}")
    except Exception as e:
        print("Error checking /health:", e)

    print("\n2. Checking GET /api/community/posts...")
    try:
        r = requests.get(f"{BASE_URL}/api/community/posts", timeout=10)
        print(f"Status: {r.status_code}")
        posts = r.json()
        print(f"Successfully fetched {len(posts)} posts from the server.")
        if posts:
            print(f"Latest post by: {posts[0].get('name')} ({posts[0].get('handle')})")
            print(f"Content: {posts[0].get('content')}")
    except Exception as e:
        print("Error fetching posts:", e)

    print("\n3. Testing POST /api/community/posts to verify write capabilities...")
    test_post = {
        "name": "Render Verifier",
        "handle": "@render_test",
        "content": "This is a verification post to confirm the backend is live on the cloud! 🚀"
    }
    try:
        r = requests.post(f"{BASE_URL}/api/community/posts", json=test_post, timeout=10)
        print(f"Status: {r.status_code}")
        if r.status_code == 200:
            new_post = r.json()
            print(f"Success! Created post ID: {new_post.get('id')}")
            print(f"Content: {new_post.get('content')}")
        else:
            print(f"Failed to create post. Response: {r.text}")
    except Exception as e:
        print("Error writing post:", e)

if __name__ == "__main__":
    print(f"Starting verification for live URL: {BASE_URL}\n")
    verify()
