import os
import subprocess
import sys
import re

if len(sys.argv) != 3:
    print('Usage: python auto_gen.py <target_directory> <desired_directory>')
    sys.exit(1)

directory = sys.argv[1]

# Get a list of all files in the directory
files = os.listdir(directory)

# Iterate over each file
for root, dirs, files in os.walk(directory):
    for file in files:
        # Construct the full file path
        filepath = os.path.join(root, file)

        if not filepath.endswith('.js'):
            continue

        # Pass the file path to the process and run it
        # Replace 'myprogram' with the name of your program
        content = open(filepath, "r")
        new_content = ""
        while True:
            line = content.readline()
            if not line:
                break
            if line.startswith('d8.file.execute'):
                new_line = re.sub(r'test/mjsunit', sys.argv[2], line)
                new_content += new_line
            else:
                new_content += line
        content.close()
        with open(filepath, "w") as f:
            f.write(new_content)

for root, dirs, files in os.walk(directory):
    for file in files:
        # Construct the full file path
        filepath = os.path.join(root, file)

        if not filepath.endswith('.js'):
            continue

        # Pass the file path to the process and run it
        # Replace 'myprogram' with the name of your program
        command = ["swift", "run", "-c", "debug", "FuzzILTool", "--compile", filepath]
        
        result = subprocess.run(command, capture_output=True, text=True)

        regex = r"FuzzIL program written to (.*).fzil"

        if re.search(regex, result.stdout):
            print(f"Successfully compiled {filepath}")
        else:
            print(f"Failed to compile {filepath}")
            print(result.stdout)
            sys.exit(1)
