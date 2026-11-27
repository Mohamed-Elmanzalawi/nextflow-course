# params.py: precedence.nf written as plain Python (Lesson 3.3).
# argparse plays the part of the params block: a type, a default,
# and --name on the command line to override it.
import argparse
import json

parser = argparse.ArgumentParser()
# params { title: String = 'from the script' }
parser.add_argument("--title", type=str, default="from the script")
# like: nextflow run … -params-file
parser.add_argument("--params-file")

# A params file sits between the script's default and the command line:
first, _ = parser.parse_known_args()
if first.params_file:
    with open(first.params_file) as fh:
        parser.set_defaults(**json.load(fh))  # the file beats the default
args = parser.parse_args()  # and the command line beats both

print(f"title = {args.title}")
