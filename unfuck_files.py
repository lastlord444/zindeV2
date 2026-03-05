import os

def fix_corruption(file_path):
    with open(file_path, 'rb') as f:
        data = f.read()
    
    # Check if the file starts with \xc3\xa7
    if data.startswith(b'\xc3\xa7'):
        # Try to decode by taking every 3rd byte starting from 2
        # A corrupted file 'c3 a7 X' is 3 bytes per original byte X.
        # But wait, what if the original byte was NOT a single byte?
        # Let's see: \xc3\xa7 is 2 bytes. So followed by X (1 byte).
        # Let's just remove all \xc3\xa7
        new_data = data.replace(b'\xc3\xa7', b'')
        
        # Write it back safely
        with open(file_path, 'wb') as f:
            f.write(new_data)
        return True
    return False

if __name__ == '__main__':
    lib_dir = r"d:\zindeV.2.0\lib"
    fixed_count = 0
    for root, dirs, files in os.walk(lib_dir):
        for name in files:
            if name.endswith('.dart'):
                filepath = os.path.join(root, name)
                if fix_corruption(filepath):
                    fixed_count += 1
    print(f"Fixed {fixed_count} files!")
