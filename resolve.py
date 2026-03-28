import os

def resolve_file(filepath):
    if not os.path.exists(filepath): return
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    out = []
    in_head = False
    in_remote = False
    
    for line in lines:
        if line.startswith('<<<<<<< HEAD'):
            in_head = True
            continue
        elif line.startswith('======='):
            in_head = False
            in_remote = True
            continue
        elif line.startswith('>>>>>>>'):
            in_remote = False
            continue
            
        if in_remote:
            continue
        out.append(line)
        
    with open(filepath, 'w') as f:
        f.writelines(out)

files = [
    'frontend/lib/presentation/screens/client/market_list_screen.dart',
    'frontend/lib/presentation/screens/client/pharmacy_list_screen.dart',
    'frontend/lib/presentation/screens/client/restaurant_list_screen.dart'
]

for f in files:
    resolve_file(f)
    print("Resolved", f)
