"""Dump the main isolate's stack from the Dart VM service (uv run --with websockets)."""
import asyncio
import json
import sys

import websockets

BASE = sys.argv[1] if len(sys.argv) > 1 else "127.0.0.1:42257/Unyv0HHnB60="
WS = f"ws://{BASE}/ws"


async def main():
    async with websockets.connect(WS, max_size=64 * 1024 * 1024) as ws:
        counter = 0

        async def rpc(method, params=None):
            nonlocal counter
            counter += 1
            rid = counter
            await ws.send(json.dumps(
                {"jsonrpc": "2.0", "id": rid, "method": method, "params": params or {}}
            ))
            while True:
                msg = json.loads(await ws.recv())
                if msg.get("id") == rid:
                    if "error" in msg:
                        raise RuntimeError(msg["error"])
                    return msg["result"]

        vm = await rpc("getVM")
        for iso in vm["isolates"]:
            print(f"isolate {iso['id']} {iso['name']}")
        main_iso = next(i for i in vm["isolates"] if i["name"] == "main")
        iso_id = main_iso["id"]
        stack = await rpc("getStack", {"isolateId": iso_id, "limit": 40})
        print("\n--- main isolate stack ---")
        for frame in stack.get("frames", []):
            fn = frame.get("function", {})
            loc = frame.get("location", {})
            name = fn.get("name", "?")
            owner = fn.get("owner", {}).get("name", "")
            print(f"{frame.get('index')}: {owner}.{name} [{loc.get('script', {}).get('uri', '?')}]")


asyncio.run(main())
