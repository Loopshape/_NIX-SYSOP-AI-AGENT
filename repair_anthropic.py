import re

with open('anthropic.py', 'r') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    stripped = line.strip()
    if stripped.startswith('"text": "'):
        # Extract everything after "text": "
        start_idx = line.find('"text": "') + 9
        # Find the last " before any comma and newline
        end_idx = line.rfind('"')
        if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
            prefix = line[:start_idx]
            content = line[start_idx:end_idx]
            suffix = line[end_idx+1:]
            
            # Unescape \" to "
            content = content.replace('\\"', '"')
            # Replace \n with actual newlines
            content = content.replace('\\n', '\n')
            # Replace \t with actual tabs
            content = content.replace('\\t', '\t')
            # Escape """ to avoid ending the string prematurely
            content = content.replace('"""', '\\"\\"\\"')
            
            new_line = f'{prefix}r"""{content}"""{suffix}'
            new_lines.append(new_line)
        else:
            new_lines.append(line)
    else:
        new_lines.append(line)

with open('anthropic.py', 'w') as f:
    f.writelines(new_lines)