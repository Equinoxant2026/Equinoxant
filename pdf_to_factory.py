import fitz, re, json, random, os
from collections import defaultdict

PDF_PATH = "book.pdf"
OUTPUT = "assets/questions.json"

# --- YOUR DOMAIN SWAPS FOR UNPREDICTABLE FALSE (EDIT FOR YOUR BOOK) ---
FAKE_SWAPS = {
    "currents": ["voltages", "powers", "resistances"],
    "voltages": ["currents", "powers"],
    "junction": ["loop", "node", "branch"],
    "zero": ["infinite", "maximum", "one"],
    "KCL": ["KVL", "Ohm's Law", "Faraday's Law"],
    "KVL": ["KCL", "Ohm's Law"],
    "Durban": ["Toronto", "Ottawa", "Vancouver"],
    "South Africa": ["Canada", "Australia", "Germany"],
    "series": ["parallel", "short circuit", "open circuit"],
    "parallel": ["series", "short circuit"],
}

# --- COMMON HELPERS (from your free version) ---
def make_scramble_variants(word):
    word = word.strip()
    if len(word) < 3: return [word]
    variants = set()
    while len(variants) < 4:
        lst = list(word)
        random.shuffle(lst)
        v = ''.join(lst)
        if v.lower()!= word.lower(): variants.add(v)
    return list(variants)

def make_fill_variants(sentence):
    words = sentence.split()
    variants = []
    for idx in [0, len(words)//2, -1]:
        tmp = words.copy()
        ans = tmp[idx].strip('.,;:()')
        if len(ans) < 2: continue
        tmp[idx] = "____"
        q = ' '.join(tmp)
        variants.append((q, ans))
    return variants

def make_unpredictable_truefalse_free(sentence):
    words = sentence.split()
    for real, fakes in FAKE_SWAPS.items():
        for w in words:
            if real.lower() in w.lower():
                fake = random.choice(fakes)
                false_q = sentence.replace(w, fake)
                return [
                    {"type":"truefalse","q":sentence,"answer_text":"True","options":["True","False"],"scramble_variants":[],"time_limit":8},
                    {"type":"truefalse","q":false_q,"answer_text":"False","options":["True","False"],"scramble_variants":[],"time_limit":8}
                ]
    return [{"type":"truefalse","q":sentence,"answer_text":"True","options":["True","False"],"scramble_variants":[],"time_limit":8}]

def make_free_pool(sentence):
    pool = []
    for q_text, ans in make_fill_variants(sentence):
        pool.append({"type":"fill","q":q_text,"answer_text":ans,"options":[],"scramble_variants":[],"time_limit":12})
    key_word = max(sentence.split(), key=len).strip('.,;:()')
    pool.append({"type":"scramble","q":f"Unscramble key term from: '{sentence[:60]}...'","answer_text":key_word,"options":[],"scramble_variants":make_scramble_variants(key_word),"time_limit":12})
    pool.append({"type":"mcq","q":f"Which term is central to: '{sentence}'","answer_text":key_word,"options":[key_word, random.choice(["voltage","current","resistance","power"]), random.choice(["loop","junction","circuit"]), random.choice(["zero","infinite"])],"scramble_variants":[],"time_limit":15})
    pool.extend(make_unpredictable_truefalse_free(sentence))
    pool.append({"type":"law","q":f"State in your own words: {sentence}","answer_text":sentence,"options":[],"scramble_variants":[],"time_limit":40})
    return pool

def get_all_sentences():
    doc = fitz.open(PDF_PATH)
    text = ""
    START, END = 10, doc.page_count - 5
    for i in range(START, END):
        text += doc[i].get_text() + " "
    sentences = re.split(r'(?<=[.!?])\s+', text)
    all_s = [s.strip() for s in sentences if 6 <= len(s.split()) <= 35]
    all_s = [s for s in all_s if "Table of Contents" not in s and "References" not in s]
    print(f"FOUND ALL {len(all_s)} sentences")
    return all_s[:2000]

# --- AI MODE IF KEY EXISTS ---
def run_ai_mode(sentences):
    from openai import OpenAI
    client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    PROMPT = """
Source sentence: "{sentence}"

Create 5 question objects from THIS ONE sentence ONLY. Answer must be STRICTLY from sentence.

VERY IMPORTANT RULES FOR TRUE/FALSE - MUST FOLLOW:
- NEVER use "not", "no", "never", "isn't", "does not" to make false.
- To make FALSE, replace with a BELIEVABLE but wrong fact from same domain.
BAD: "Durban is not a South African city"
GOOD: "Durban is a Canadian city" or "Durban is capital of Australia"
BAD: "KCL does not say sum is zero"
GOOD: "KCL says sum of voltages around loop is zero" (swap KCL with KVL)

Other rules:
- MCQ: options 4, correct position random, never fixed b) for MOSFET
- Scramble: for key word, give 4 different scrambles: DOG -> ["OGD","GDO","DGO","GOD"]
- Fill: blank moves position
- Give fair time_limit: truefalse 8s, fill 12s, scramble 12s, mcq 15s, definition 35s, law 45s

Output JSON ONLY: {{"questions": [{{"type":"mcq","q":"...","answer_text":"...","options":["..."],"scramble_variants":[],"time_limit":15}}] }}
Sentence: "{sentence}"
"""
    all_data = []
    for i, s in enumerate(sentences):
        print(f"AI {i}/{len(sentences)} {s[:60]}")
        try:
            resp = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role":"user","content": PROMPT.format(sentence=s)}],
                response_format={"type":"json_object"}
            )
            data = json.loads(resp.choices[0].message.content)
            qs = data.get("questions", [])
            # ensure fields + anti-cramming variants merged
            for q in qs:
                if q.get("type")=="scramble" and not q.get("scramble_variants"):
                    q["scramble_variants"] = make_scramble_variants(q.get("answer_text",""))
                if "scramble_variants" not in q: q["scramble_variants"] = []
                if "options" not in q: q["options"] = []
            if not qs: qs = make_free_pool(s) # fallback
            all_data.append({"source":s,"pool":qs})
        except Exception as e:
            print(f"AI Error {e}, using free for this sentence")
            all_data.append({"source":s,"pool":make_free_pool(s)})
    return all_data

# --- MAIN ---
sentences = get_all_sentences()
if os.getenv("OPENAI_API_KEY"):
    print("OPENAI_API_KEY found -> Running AI smart mode with Canadian-city rule")
    final = run_ai_mode(sentences)
else:
    print("No OPENAI_API_KEY -> Running FREE mode with FAKE_SWAPS (Durban=Canadian)")
    final = [{"source":s,"pool":make_free_pool(s)} for s in sentences]

os.makedirs("assets", exist_ok=True)
with open(OUTPUT,'w',encoding='utf-8') as f:
    json.dump(final,f,indent=2,ensure_ascii=False)

print(f"DONE MERGED - {len(final)} sentences saved to {OUTPUT}")
