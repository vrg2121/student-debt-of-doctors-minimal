"""
compute_cohorts.py

Identifies non-overlapping medical school cohorts based on tuition variation
rules, and writes a copy of the input CSV with a new Cohort_ID column.

To tweak any of the thresholds, edit the values in the CONFIG block below
and re-run (double-click run.bat again). All amounts are in thousands of
2014-adjusted dollars (matching the units in the source data).
"""

import pandas as pd

# ============================ CONFIG ============================
INPUT_FILE  = "cms-aamc-allmedschoolyears.csv"
OUTPUT_FILE = "cms-aamc-allmedschoolyears-with-cohorts.csv"

# Cohort length must be in this range (inclusive). Per the project spec
# this should stay 2..4 unless that requirement changes.
MIN_COHORT_LEN = 2
MAX_COHORT_LEN = 4

# Maximum allowed year-to-year change in STARTING tuition (tuition in the
# year a cohort member entered med school = tuition[grad_year - 3])
# between consecutive members of a cohort. In $thousands.
MAX_YEAR_TO_YEAR_START_CHANGE = 2.0

# Maximum allowed range (max - min) of STARTING tuition across the
# entire cohort. In $thousands.
MAX_COHORT_START_RANGE = 2.0

# Minimum required range (max - min) of TUITION_BILL across the
# entire cohort. In $thousands.
MIN_TUITION_BILL_RANGE = 10.0
# ================================================================


def find_candidates_for_school(school_df, tuition_lookup):
    """
    Return a list of valid candidate cohorts for one school.
    Each candidate is a dict with keys:
        school, grad_years (list), length, orig_indices (list),
        var (tuition_bill range), start_year
    """
    school = school_df["med_school"].iloc[0]

    # Eligibility: tuition_bill present AND skipped_year != 1
    eligible = school_df[
        school_df["tuition_bill"].notna() & (school_df["skipped_year"] != 1)
    ].sort_values("grad_year").reset_index()
    # 'index' column holds original DataFrame index

    if eligible.empty:
        return []

    # Group eligible rows into runs of consecutive grad_years
    runs = []
    cur = []
    for _, row in eligible.iterrows():
        gy = int(row["grad_year"])
        if cur and gy != cur[-1]["grad_year"] + 1:
            runs.append(cur)
            cur = []
        cur.append({
            "grad_year":    gy,
            "orig_idx":     row["index"],
            "tuition_bill": float(row["tuition_bill"]),
        })
    if cur:
        runs.append(cur)

    candidates = []
    for run in runs:
        n = len(run)
        for length in range(MIN_COHORT_LEN, MAX_COHORT_LEN + 1):
            for start in range(0, n - length + 1):
                members = run[start:start + length]
                grad_years = [m["grad_year"] for m in members]

                # Look up STARTING tuition (tuition[grad_year - 3]) for each member
                start_tuitions = []
                ok = True
                for gy in grad_years:
                    st = tuition_lookup.get((school, gy - 3))
                    if st is None or pd.isna(st):
                        ok = False
                        break
                    start_tuitions.append(float(st))
                if not ok:
                    continue

                # Year-to-year change in starting tuition between consecutive members
                if any(
                    abs(start_tuitions[i + 1] - start_tuitions[i]) > MAX_YEAR_TO_YEAR_START_CHANGE
                    for i in range(len(start_tuitions) - 1)
                ):
                    continue

                # Total range of starting tuition across cohort
                if max(start_tuitions) - min(start_tuitions) > MAX_COHORT_START_RANGE:
                    continue

                # Range of tuition_bill across cohort
                bills = [m["tuition_bill"] for m in members]
                bill_range = max(bills) - min(bills)
                if bill_range < MIN_TUITION_BILL_RANGE:
                    continue

                candidates.append({
                    "school":        school,
                    "grad_years":    grad_years,
                    "length":        length,
                    "orig_indices":  [m["orig_idx"] for m in members],
                    "var":           bill_range,
                    "start_year":    grad_years[0],
                })
    return candidates


def select_non_overlapping(candidates):
    """
    Weighted interval scheduling DP.

    Objective: maximize the number of cohorts.
    Tie-breakers (in order):
        1. Prefer shorter cohorts (2 > 3 > 4).
        2. Prefer cohorts with larger tuition_bill range (variation).
        3. Prefer cohorts that start earlier in time.

    These priorities are encoded into a scalar weight where each level
    of priority is on a vastly different scale, so higher-priority terms
    always dominate lower-priority ones.
    """
    if not candidates:
        return []

    # Weight encoding (per cohort):
    #   COUNT_UNIT             -> +1 cohort
    #   SHORTNESS_UNIT * (5-L) -> shorter cohort gets a bonus
    #   var                    -> tuition_bill range
    # Total weight is the sum across selected cohorts.
    COUNT_UNIT     = 10**12
    SHORTNESS_UNIT = 10**6
    # Variation values are at most a few hundred thousand (in $thousands, ~50)
    # so they sit safely below SHORTNESS_UNIT.

    for c in candidates:
        c["weight"] = (
            COUNT_UNIT
            + SHORTNESS_UNIT * (5 - c["length"])
            + c["var"]
        )

    # Sort by end year (last grad_year), then start_year for tie-breaking later
    cands = sorted(candidates, key=lambda c: (c["grad_years"][-1], c["start_year"]))
    n = len(cands)

    # p[i] = index of the latest cohort j < i whose end_year < cands[i].start_year
    # (i.e., the latest cohort that does not overlap with i). -1 if none.
    p = [-1] * n
    for i in range(n):
        si = cands[i]["start_year"]
        for j in range(i - 1, -1, -1):
            if cands[j]["grad_years"][-1] < si:
                p[i] = j
                break

    # OPT[i] = best total weight achievable using cands[0..i-1]
    OPT = [0] * (n + 1)
    for i in range(1, n + 1):
        idx = i - 1
        prev_weight = OPT[p[idx] + 1] if p[idx] >= 0 else 0
        incl = cands[idx]["weight"] + prev_weight
        excl = OPT[i - 1]
        OPT[i] = max(incl, excl)

    # Backtrack to recover the selected cohorts
    selected = []
    i = n
    while i > 0:
        idx = i - 1
        prev_weight = OPT[p[idx] + 1] if p[idx] >= 0 else 0
        incl = cands[idx]["weight"] + prev_weight
        excl = OPT[i - 1]
        if incl >= excl:
            selected.append(cands[idx])
            i = (p[idx] + 1) if p[idx] >= 0 else 0
        else:
            i -= 1
    selected.reverse()
    return selected


def main():
    df = pd.read_csv(INPUT_FILE)

    # Build {(school, grad_year): tuition} lookup for fast starting-tuition queries
    tuition_lookup = {
        (r.med_school, int(r.grad_year)): r.tuition
        for r in df.itertuples(index=False)
    }

    df["Cohort_ID"] = 0
    next_cohort_id = 1

    # Process each school independently. groupby preserves alphabetical order.
    for school, school_df in df.groupby("med_school", sort=True):
        candidates = find_candidates_for_school(school_df, tuition_lookup)
        if not candidates:
            continue
        selected = select_non_overlapping(candidates)
        # Number cohorts in chronological order within each school
        selected.sort(key=lambda c: c["start_year"])
        for c in selected:
            for idx in c["orig_indices"]:
                df.at[idx, "Cohort_ID"] = next_cohort_id
            next_cohort_id += 1

    df.to_csv(OUTPUT_FILE, index=False)
    print_summary(df)
    print(f"\nWrote: {OUTPUT_FILE}")


def print_summary(df):
    cohort_rows = df[df["Cohort_ID"] > 0]
    n_cohorts  = cohort_rows["Cohort_ID"].nunique()
    n_assigned = len(cohort_rows)
    n_total    = len(df)

    print()
    print("=" * 64)
    print("COHORT ASSIGNMENT SUMMARY")
    print("=" * 64)
    print(f"Configuration:")
    print(f"  Cohort length range:                 {MIN_COHORT_LEN}-{MAX_COHORT_LEN} years")
    print(f"  Max year-to-year start tuition diff: ${MAX_YEAR_TO_YEAR_START_CHANGE:.1f}k")
    print(f"  Max cohort start tuition range:      ${MAX_COHORT_START_RANGE:.1f}k")
    print(f"  Min cohort tuition_bill range:       ${MIN_TUITION_BILL_RANGE:.1f}k")
    print()
    print(f"Results:")
    print(f"  Total cohorts found:        {n_cohorts}")
    print(f"  Rows assigned to a cohort:  {n_assigned} / {n_total}")
    print(f"  Schools with >=1 cohort:    {cohort_rows['med_school'].nunique()}")
    print(f"  Schools in dataset:         {df['med_school'].nunique()}")

    if n_cohorts > 0:
        sizes = cohort_rows.groupby("Cohort_ID").size()
        dist  = sizes.value_counts().sort_index()
        print()
        print(f"Cohort length distribution:")
        for length, count in dist.items():
            print(f"  {length}-year cohorts: {count}")

        print()
        print(f"First 5 cohorts (for spot-checking):")
        print("-" * 64)
        for cid in sorted(cohort_rows["Cohort_ID"].unique())[:5]:
            c = cohort_rows[cohort_rows["Cohort_ID"] == cid]
            school = c["med_school"].iloc[0]
            years  = c["grad_year"].tolist()
            bills  = c["tuition_bill"].tolist()
            print(f"  Cohort {cid}: {school}")
            print(f"    grad_years: {years}")
            print(f"    tuition_bill: {[f'{b:.2f}' for b in bills]}  (range = {max(bills) - min(bills):.2f})")


if __name__ == "__main__":
    main()
