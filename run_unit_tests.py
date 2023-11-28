import os
import subprocess
import time
import re

def remove_ext(filename):
    return os.path.splitext(filename)[0]


def getMethodNames(filename):
    
    os.chdir('xtend-gen/circus/robocalc/sleec/tests')
    text_file = open(filename)
    data = text_file.read()
    text_file.close()
    
    methodnames = re.findall(r'test_\w+', data)
    return methodnames


def runTest(methodname, cmd):

    print('\n--------------------------------------\n')
    
    with open(os.path.join('log', methodname + '.log'), 'w+') as f:
        print('Running ' + methodname + '...')
        cmd += '#' + methodname
        result = subprocess.run(cmd, shell=True, stdout = f, stderr = f)
        return result.returncode == 0


def main():
    start = time.time()
    os.chdir('circus.robocalc.sleec.tests')
    if not os.path.exists('log'):
        os.mkdir('log')    

    test_files = [f for f in os.listdir('xtend-gen/circus/robocalc/sleec/tests') if f.endswith('.java')]
    
    for f in test_files:
        cmd = 'mvn test -Dtest=' + remove_ext(f)
        methodnames = getMethodNames(f)
        os.chdir('../../../../..')
        for m in methodnames:
            result = runTest(m, cmd)
            if not result:
                print(m + ' failed.')
            else:
                print(m + ' passed.')    
            

if __name__ == '__main__':
    main()
