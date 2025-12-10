import subprocess
import os

directory = "examples"

expected_results = {
    "hello_world.lol": "HELLO WORLD!",
    "simple_arithmetic.lol": "15\n5\n15\n3\n1\n10\n3\n22\n-96",
    "logic_and_if_statements.lol": "FAIL\nWIN\nFAIL\nWIN\nn is 10\nx is WIN and y is FAIL",
    "loops.lol": "0\n1\n2\n3\n4\nSum from 0 to 4: 10\n5\n4\n3\n2\n1\n0\n-1\n-2\n"
                 "Outer: 0\nInner: 0\nInner: 1\nInner: 2\nOuter: 1\nInner: 0\nInner: 1\nInner: 2",
    "strings_and_concat.lol": "Hello, Dmitriy Kokorev!\nThe sum of 2 and 3 is 5.\n"
                              "Task status: WIN completed",
    "complex_usage.lol": "Iteration 0 continues\nIteration 1 continues\nIteration 2 continues\n"
                         "Alexey reached 3 at iteration 3\nIteration 4 continues\nResult is big: 10\n"
                         "Inner 0 in outer 0\nInner 1 in outer 0\nInner 0 in outer 1\nInner 1 in outer 1"
}

def run_interpreter(file_path):
    try:
        result = subprocess.run(
            ["./build/interpreter", file_path],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error processing file {file_path}: {e}")
        return None

def main():
    cnt = 0
    for filename in os.listdir(directory):
        file_path = os.path.join(directory, filename)
        if filename in expected_results:
            output = run_interpreter(file_path)
            expected = expected_results[filename]
            if output == expected:
                print(f"{filename}: OK")
            else:
                cnt += 1
                print(f"{filename}: Error!")
                print(f"Expected:\n{expected}")
                print(f"Received:\n{output}")
                print(expected.encode("utf-8"))
                print(output.encode("utf-8"))
    if (cnt == 0):
        print("Tests are passed!")

if __name__ == "__main__":
    main()

