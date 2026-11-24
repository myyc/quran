#!/usr/bin/env python3
"""Build assets/quran.json from tool/raw (run: uv run tool/build_assets.py).

Sources:
- alquran.cloud: quran-uthmani (Arabic), en.sahih, en.pickthall, en.yusufali
- fawazahmed0/quran-api: eng-mustafakhattaba (Clear Quran, Khattab)
- spa5k/tafsir_api: en-tafisr-ibn-kathir (per-surah files in tool/raw/tafsir)

Ayah 1 of every surah except 1 and 9 has the basmala stripped from the
Arabic text; the app renders it in the surah header instead.
"""
import json
import re

RAW = "tool/raw"
OUT = "assets/quran.json"


def load(name):
    return json.load(open(f"{RAW}/{name}.json"))["data"]["surahs"]


ar = load("quran_arabic")
BASMALA = ar[0]["ayahs"][0]["text"].lstrip("﻿").strip()
# Surahs 95 and 97 write the initial ba with shadda (بِّ instead of بِ).
BASMALA_VARIANTS = [BASMALA, "بِّ" + BASMALA[2:]]
editions = {
    "sahih": load("quran_en"),
    "pickthall": load("en_pickthall"),
    "yusufali": load("en_yusufali"),
}
khattab = {
    (v["chapter"], v["verse"]): v["text"]
    for v in json.load(open(f"{RAW}/khattab.json"))["quran"]
}

surahs = []
for s in ar:
    n = s["number"]
    ayahs = []
    for a in s["ayahs"]:
        k = a["numberInSurah"]
        text = a["text"].lstrip("﻿").strip()
        if k == 1 and n not in (1, 9):
            variant = next((b for b in BASMALA_VARIANTS if text.startswith(b)),
                           None)
            assert variant, f"basmala mismatch {n}:1"
            text = text[len(variant):].strip()
        tr = {key: ed[n - 1]["ayahs"][k - 1]["text"].strip()
              for key, ed in editions.items()}
        tr["khattab"] = khattab[(n, k)].strip()
        ayahs.append({
            "a": k,
            "ar": text,
            "j": a["juz"],
            "p": a["page"],
            "s": bool(a.get("sajda")),
            "tr": tr,
        })
    surahs.append({
        "n": n,
        "name": s["name"],
        "ename": s["englishName"],
        "tname": s["englishNameTranslation"],
        "type": s["revelationType"],
        "ayahs": ayahs,
    })

json.dump({"surahs": surahs}, open(OUT, "w"), ensure_ascii=False,
          separators=(",", ":"))

import os
os.makedirs("assets/tafsir", exist_ok=True)
for s in ar:
    n = s["number"]
    tafsir = {
        item["ayah"]: re.sub(r"\n{3,}", "\n\n", item["text"].strip())
        for item in json.load(open(f"{RAW}/tafsir/{n}.json"))
    }
    json.dump(tafsir, open(f"assets/tafsir/{n}.json", "w"),
              ensure_ascii=False, separators=(",", ":"))

print(f"wrote {OUT}: {len(surahs)} surahs, "
      f"{sum(len(s['ayahs']) for s in surahs)} ayahs, "
      f"plus {len(ar)} per-surah tafsir files")
