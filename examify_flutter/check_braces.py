import sys

def check_braces(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    stack = []
    for i, line in enumerate(lines):
        for j, char in enumerate(line):
            if char == '{':
                stack.append(('{', i+1))
            elif char == '}':
                if not stack:
                    print(f"Extra closing brace at line {i+1}")
                    return
                stack.pop()
                
    if stack:
        print(f"Unclosed braces starting at:")
        for _, line in stack:
            print(f"Line {line}")
    else:
        print("Braces are perfectly matched!")

if __name__ == "__main__":
    check_braces(sys.argv[1])
