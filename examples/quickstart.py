"""PonyFlash SDK — end-to-end quickstart.

Run:
    pip install ponyflash
    export PONYFLASH_API_KEY="pf_xxx"
    python quickstart.py
"""

from ponyflash import PonyFlash, InsufficientCreditsError

client = PonyFlash()

# ── Check balance ──
balance = client.account.credits()
print(f"Credit balance: {balance.balance} {balance.currency}")

# ── List models ──
page = client.models.list()
for m in page.items:
    print(f"  {m.id} ({m.type})")

# ── Generate an image ──
try:
    gen = client.images.generate(
        model="image-pro-1",
        prompt="A magical forest with glowing mushrooms",
        size="1024x1024",
    )
    print(f"Image URL: {gen.url}")
    print(f"Credits used: {gen.credits}")
except InsufficientCreditsError as e:
    print(f"Not enough credits (balance={e.balance}, required={e.required})")
    link = client.account.recharge()
    print(f"Recharge at: {link.recharge_url}")

# ── Generate a video ──
try:
    gen = client.video.generate(
        model="video-gen-1",
        prompt="A timelapse of clouds moving over a mountain",
        size="1920x1080",
        duration=5,
    )
    print(f"Video URL: {gen.url}")
    print(f"Credits used: {gen.credits}")
except InsufficientCreditsError as e:
    print(f"Not enough credits: {e}")

# ── Generate speech ──
try:
    gen = client.speech.generate(
        model="speech-v1",
        input="Welcome to PonyFlash, the AI media generation platform.",
        voice="alloy",
    )
    print(f"Speech URL: {gen.url}")
except InsufficientCreditsError as e:
    print(f"Not enough credits: {e}")

# ── Generate music ──
try:
    gen = client.music.generate(
        model="music-gen-1",
        prompt="A calm acoustic guitar melody",
        instrumental=True,
        duration=30,
    )
    print(f"Music URL: {gen.url}")
except InsufficientCreditsError as e:
    print(f"Not enough credits: {e}")
