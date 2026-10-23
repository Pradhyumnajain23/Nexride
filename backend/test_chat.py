import urllib.request, json

def post(path, body):
    req = urllib.request.Request(
        "http://127.0.0.1:8000" + path,
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())

queries = [
    "Where is bus 401A?",
    "How to go from Majestic to Whitefield?",
    "When will route 500D arrive?",
    "Book a ticket from KR Puram to MG Road",
    "Hello NEXRIDE!",
]

print("=== HYBRID CHATBOT TESTS ===\n")
with open("chat_test_output.txt", "w", encoding="utf-8") as f:
    for q in queries:
        res = post("/chat/", {"message": q})
        f.write(f"User: {q}\n")
        f.write(f"Intent: {res['intent']} | Entities: {res['entities']}\n")
        f.write(f"Bot : {res['reply']}\n\n")
print("Done writing to chat_test_output.txt")
