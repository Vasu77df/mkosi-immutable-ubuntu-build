#!/bin/python3

import argparse
import os
import subprocess
from contextlib import contextmanager

parser = argparse.ArgumentParser(description="A simple docker wrapper to run mkosi in a docker container", usage="whaled-mkosi --build")
parser.add_argument("--run")
parser.add_argument("-d", "--debug", action="store_true", help="Verbose Logging")
parser.add_argument("-b", "--build", action="store_true", help="Build mkosi-builder container and run the image build")
args = parser.parse_args()


@contextmanager
def step_wrapper(stepname: str):
    print(f'Running {stepname}')
    try:
        yield
    except Exception:
        print(f'Exception during {stepname}')
        raise


def main():
    with step_wrapper('Listing Docker Cont'):
        print('steps')


try:
    main()
except Exception as e:
    print('we gotta exception houston', e)

## Docker command to incorporate
## Docker commands that I have to run.
# docker build -t mkosi-image-builder .
# docker run --tty --interactive --privilged --name=os-image-build mkosi-image-builder
# docker start os-image-build 
# docker attach os-image-build
# docker container rm os-image-build
