import os

def main():
    os.chdir('circus.robocalc.sleec')
    os.system('mvn clean install')
    os.system('mvn compile')
    os.system('mvn package')
    
if __name__ == '__main__':
    main()
