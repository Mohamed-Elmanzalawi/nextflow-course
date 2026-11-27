# retry.py: errorStrategy 'retry' and a dynamic memory directive (Lesson 4.2).

MAX_RETRIES = 2                          # maxRetries 2
memory_gb = lambda attempt: 1 * attempt  # memory { 1.GB * task.attempt }


# process FLAKY
def flaky(sample, attempt):
    print(f"[{sample}] attempt {attempt}: 1 CPU, {memory_gb(attempt)} GB")
    if attempt < 2:
        raise MemoryError("pretend we ran out of memory")   # exit 137
    return f"{sample}.txt"


# FLAKY(channel.of('s1', 's2'))
for sample in ["s1", "s2"]:
    # the first try, then up to MAX_RETRIES more
    for attempt in range(1, MAX_RETRIES + 2):
        try:
            print(f"[{sample}] done: {flaky(sample, attempt)}")
            break
        except MemoryError as err:       # errorStrategy 'retry'
            print(f"[{sample}] failed ({err}), retrying")
    else:
        raise SystemExit(f"{sample}: still failing after {MAX_RETRIES} retries")
