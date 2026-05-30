from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_endpoints():
    print("1. Testing GET /api/community/posts...")
    response = client.get("/api/community/posts")
    print("Status:", response.status_code)
    posts = response.json()
    print("Fetched", len(posts), "posts.")
    # Safe printing without emoji characters causing issues on Windows stdout
    first_post_content = posts[0]["content"].encode('ascii', 'ignore').decode('ascii')
    print("First post:", first_post_content)

    print("\n2. Testing POST /api/community/posts...")
    post_data = {
        "name": "Alex Champion",
        "handle": "@alex_champ",
        "content": "This is a new test post for verification!"
    }
    response = client.post("/api/community/posts", json=post_data)
    print("Status:", response.status_code)
    new_post = response.json()
    print("Created post ID:", new_post["id"])
    print("Created post Content:", new_post["content"])

    print("\n3. Testing GET /api/community/posts again...")
    response = client.get("/api/community/posts")
    posts = response.json()
    print("Fetched", len(posts), "posts now.")
    
    post_id = new_post["id"]
    print(f"\n4. Testing POST /api/community/posts/{post_id}/like...")
    response = client.post(f"/api/community/posts/{post_id}/like?handle=@alex_champ")
    print("Status:", response.status_code)
    liked_post = response.json()
    print("Likes count:", liked_post["likes"])
    print("Liked by:", liked_post.get("liked_by", []))

    print(f"\n5. Testing POST /api/community/posts/{post_id}/comment...")
    comment_data = {
        "name": "Alex Champion",
        "handle": "@alex_champ",
        "content": "Adding a quick verification comment."
    }
    response = client.post(f"/api/community/posts/{post_id}/comment", json=comment_data)
    print("Status:", response.status_code)
    commented_post = response.json()
    print("Comments count:", len(commented_post["comments"]))
    print("Last comment content:", commented_post["comments"][-1]["content"])

    print("\n6. Testing GET /api/community/news...")
    response = client.get("/api/community/news")
    print("Status:", response.status_code)
    news = response.json()
    print("Fetched", len(news), "news items.")
    print("First news title:", news[0]["title"])

if __name__ == "__main__":
    try:
        test_endpoints()
        print("\nAll community router endpoints verified successfully!")
    except Exception as e:
        print("Verification failed with error:", e)
