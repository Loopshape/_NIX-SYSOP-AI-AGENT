import math
import re
from .persistence import update_entropy, get_word_frequency

def tokenize(text):
    return re.findall(r'\b\w{3,}\b', text.lower())

def calculate_entropy(text):
    tokens = tokenize(text)
    if not tokens:
        return 0.0
    
    # Simple Shannon Entropy on token frequencies within the text
    counts = {}
    for t in tokens:
        counts[t] = counts.get(t, 0) + 1
    
    total = len(tokens)
    entropy = 0.0
    for count in counts.values():
        p = count / total
        entropy -= p * math.log2(p)
        
    return entropy

def get_word_weight(word):
    freq = get_word_frequency(word)
    if freq == 0:
        return 1.0 # New word, high curiosity
    return 1.0 / (1.0 + math.log(1 + freq))

def process_text_entropy(text):
    tokens = tokenize(text)
    for t in tokens:
        update_entropy(t)
    return calculate_entropy(text)
