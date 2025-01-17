import os
import re

def remove_comments(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        code = file.read()

    # Remove single-line comments (//)
    code = re.sub(r'//.*', '', code)

    # Remove multi-line comments (/* ... */)
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)

    # Remove empty lines left after removing comments
    code = re.sub(r'\n\s*\n', '\n', code)

    return code

def process_directory(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.swift'):
                file_path = os.path.join(root, file)
                cleaned_code = remove_comments(file_path)
                
                # Overwrite the file with cleaned code
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(cleaned_code)
                print(f"Processed {file_path}")

if __name__ == "__main__":
    project_dir = input("Enter the path to your Swift project: ")
    if os.path.isdir(project_dir):
        process_directory(project_dir)
        print("All comments have been removed.")
    else:
        print("Invalid directory path.")

