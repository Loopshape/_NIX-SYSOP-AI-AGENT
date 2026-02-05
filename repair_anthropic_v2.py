import re

with open('anthropic.py', 'r') as f:
    content = f.read()

# Use a more robust regex to find the problematic text field
# and replace it with a triple-quoted raw string
# Looking for "text": "### USE THIS FOR THE DESIGN LAYOUT: ... "
pattern = r'("text":\s*)"(### USE THIS FOR THE DESIGN LAYOUT:.*?)"(\s*,?\s*})'
def replacer(match):
    prefix = match.group(1)
    text_content = match.group(2)
    suffix = match.group(3)
    
    # Unescape everything that was escaped for single-line double-quoted string
    text_content = text_content.replace('"', '"').replace('
', '
').replace('	', '	')
    # Escape triple quotes if any
    text_content = text_content.replace('"""', '"""')
    
    return f'{prefix}r"""{text_content}"""{suffix}'

# We need to handle multiple lines or very long lines
# re.DOTALL to let . match newlines if needed, but here it's all on one line currently
new_content = re.sub(pattern, replacer, content, flags=re.DOTALL)

with open('anthropic.py', 'w') as f:
    f.write(new_content)
