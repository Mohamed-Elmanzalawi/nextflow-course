# pairing.py: queue channels and value channels, in Python (Lesson 5.1).
# A queue channel behaves like an iterator: each item is used once.
# A process with several inputs pairs them like zip(): the shortest wins.
import itertools

numbers = iter([1, 2, 3])                     # channel.of(1, 2, 3)
letters = iter(["a", "b"])                    # channel.of('a', 'b')
for number, letter in zip(numbers, letters):  # PAIR(numbers, letters)
    print(f"{number} + {letter}")             # 3 never finds a partner

reads = ["cov_a_R1", "cov_b_R1", "hsa_rna_R1"]

print("-- the reference in a queue channel: channel.fromPath('ref.fa')")
# one item, used up by the first sample
for r, ref in zip(reads, iter(["ref.fa"])):
    print(f"{r} mapped against {ref}")

print("-- the reference as a value: channel.value(file('ref.fa'))")
# never runs out
for r, ref in zip(reads, itertools.repeat("ref.fa")):
    print(f"{r} mapped against {ref}")
