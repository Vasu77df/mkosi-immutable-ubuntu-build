#!/bin/python3

import argparse
import subprocess
import os
from contextlib import contextmanager

parser = argparse.ArgumentParser(description="A simple docker wrapper to run mkosi in a docker container", usage="whaled-mkosi --build")
parser.add_argument("-d", "--debug", actions="store_true", help="Verbose Logging")
parser.add_argument("--build", actions="store_true", help="Build mkosi-builder container and run the image build")
parser.add_argument("--run")


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
