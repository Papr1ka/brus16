import sys
import os
from IPython.display import Audio

SR = 44100

def save_audio(filename, samples):
    with open(filename, "wb") as f:
        f.write(Audio(samples, rate=SR).data)

def read_samples(file):
    with open(file) as f:
        data = f.readlines()
        samples = [int(num) for num in data]
    return samples

if __name__ == '__main__':
    FILENAME = os.path.abspath(sys.argv[1])
    samples = read_samples(FILENAME)
    save_audio(f"{FILENAME}.wav", samples)
