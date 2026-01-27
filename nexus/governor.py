# nexus/governor.py
import time
import asyncio

class TokenBucket:
    def __init__(self, rate, capacity):
        self.rate = rate
        self.capacity = capacity
        self.tokens = capacity
        self.last = time.monotonic()
        self.lock = asyncio.Lock()

    async def take(self, n):
        async with self.lock:
            now = time.monotonic()
            self.tokens = min(self.capacity, self.tokens + (now - self.last) * self.rate)
            self.last = now
            if self.tokens < n:
                await asyncio.sleep((n - self.tokens) / self.rate)
            self.tokens -= n

STREAM_CPU = TokenBucket(120, 240)
OLLAMA_CPU = TokenBucket(100, 200)
NET_IO     = TokenBucket(4, 8)     # 4 MB/s baseline
RAM_MB     = 8192

