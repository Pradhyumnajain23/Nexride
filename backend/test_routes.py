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

tests = [
    ("Majestic", "Electronic City"),
    ("Majestic", "Whitefield"),
    ("Jayanagar", "Indiranagar"),
    ("Kengeri", "MG Road"),
    ("Yelahanka", "Majestic"),
]

for origin, dest in tests:
    res = post("/ai/smart-route", {"origin": origin, "destination": dest})
    print(f"--- {origin} -> {dest} ---")
    print(f"  Reason: {res['reason']}")
    for r in res["recommended_routes"]:
        print(f"  [{r['route_number']}] {r['name']} | {r['distance_km']}km | {r['estimated_duration_min']}min | Rs.{r['fare']}")
    print()
