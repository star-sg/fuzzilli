import subprocess                              
import glob
import sys                                            
import re
import multiprocessing                       
from dataclasses import dataclass
                                                                                           
if len(sys.argv) != 3:
    print("Usage: compile.py path/to/FuzzILTool path/to/javascript_corpus_directory")
    sys.exit(-1)
                                                                                                                                                                                      
fuzzilTool = sys.argv[1]  
corpusDirectory = sys.argv[2]

def parseOutput(output):
    m = re.search("Unhandled node type (\w+)", output)
    if m:
        return f"Unhandled node {m.group(1)}"

    m = re.search("SyntaxError:", output)
    if m:
        return f"Syntax Error"

    m = re.search("Expected variable declaration as init part of a for-in loop", output)
    if m:
        return f"Invalid for-in loop"

    m = re.search("Unknown property key type: (\w+)", output)
    if m:
        return f"Unknown property key type: {m.group(1)}"

    m = re.search("Unsupported class declaration field: (\w+)", output)
    if m:
        return f"Unsupported class declaration field: {m.group(1)}"

    m = re.search("Assertion failed", output)
    if m:
        return f"Unknown assertion failure"

    m = re.search("Maximum call stack size exceeded", output)
    if m:
        return f"Stack overflow during parsing"

    m = re.search("Failed to parse .*: (\w+)", output)
    if m:
        return f"Other failure: {m.group(1)}"

    return output

def compileToFuzzIL(path):
    try:
        result = subprocess.run([fuzzilTool, "--compile", path], timeout=10, capture_output=True)
        print(".", end='')
        sys.stdout.flush()
        output = result.stdout.decode('utf-8')
        output = parseOutput(output).strip()
        return (result.returncode, output, path)
    except subprocess.TimeoutExpired as e:
        return (-1, "Timeout", path)
    except Exception as e:
        return (-1, str(e), path)

if __name__ == '__main__':
    corpus = glob.glob(f'{corpusDirectory}/*.js')

    with multiprocessing.Pool(multiprocessing.cpu_count() // 2) as p:
        results = p.map(compileToFuzzIL, corpus)
        print()

        @dataclass
        class Failure:
            count: int
            example: str

        failures = dict()
        successes = 0
        for code, msg, path in results:
            if code == 0:
                successes += 1
                continue

            if not msg in failures:
                failures[msg] = Failure(0, path)
            failures[msg].count += 1

        print()
        print("Failures:")
        for k, v in sorted(failures.items(), key=lambda item: item[1].count):
            print(f"{k}: {v.count} (e.g. {v.example})")

        total = len(results)
        print()
        print(f"Compiled {successes}/{total} samples")