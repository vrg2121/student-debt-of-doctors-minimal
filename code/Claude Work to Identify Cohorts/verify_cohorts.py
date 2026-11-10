"""
verify_cohorts.py

Picks 10 random cohorts from the output file and checks every condition
against the config in compute_cohorts.py. Reports PASS/FAIL per cohort.

Usage: double-click verify.bat (after run.bat has produced the output CSV).
"""

import pandas as pd
import random

from compute_cohorts import (
    INPUT_FILE,
    OUTPUT_FILE,
    MIN_COHORT_LEN,
    MAX_COHORT_LEN,
    MAX_YEAR_TO_YEAR_START_CHANGE,
    MAX_COHORT_START_RANGE,
    MIN_TUITION_BILL_RANGE,
)

RANDOM_SEED = None  # set an integer to reproduce; None = different each run
N_TO_CHECK = 10


def main():
    df_in  = pd.read_csv(INPUT_FILE)
    df_out = pd.read_csv(OUTPUT_FILE)

    # Lookup of starting tuition: tuition[grad_year - 3] for each (school, gy)
    tuition_lookup = {
        (r.med_school, int(r.grad_year)): r.tuition
        for r in df_in.itertuples(index=False)
    }
    # Lookup of skipped_year flag for each (school, gy)
    skip_lookup = {
        (r.med_school, int(r.grad_year)): r.skipped_year
        for r in df_in.itertuples(index=False)
    }

    cohort_ids = sorted(df_out.loc[df_out["Cohort_ID"] > 0, "Cohort_ID"].unique())
    if not cohort_ids:
        print("No cohorts found to verify.")
        return

    if RANDOM_SEED is not None:
        random.seed(RANDOM_SEED)
    sample_ids = random.sample(cohort_ids, min(N_TO_CHECK, len(cohort_ids)))

    print("=" * 72)
    print(f"VERIFYING {len(sample_ids)} RANDOMLY SELECTED COHORTS")
    print("=" * 72)
    print(f"Active config thresholds:")
    print(f"  Cohort length range:                 {MIN_COHORT_LEN}-{MAX_COHORT_LEN} years")
    print(f"  Max year-to-year start tuition diff: ${MAX_YEAR_TO_YEAR_START_CHANGE:.1f}k")
    print(f"  Max cohort start tuition range:      ${MAX_COHORT_START_RANGE:.1f}k")
    print(f"  Min cohort tuition_bill range:       ${MIN_TUITION_BILL_RANGE:.1f}k")
    print()

    overall_pass = True

    for cid in sample_ids:
        rows = df_out[df_out["Cohort_ID"] == cid].sort_values("grad_year")
        school = rows["med_school"].iloc[0]
        grad_years = rows["grad_year"].astype(int).tolist()
        bills = rows["tuition_bill"].tolist()

        print(f"Cohort {cid}: {school}")
        print(f"  grad_years   : {grad_years}")
        print(f"  tuition_bill : {[f'${b:.2f}k' for b in bills]}")

        checks = []

        # 1. Single school
        all_same_school = (rows["med_school"] == school).all()
        checks.append(("single school",
                       all_same_school,
                       f"all rows have med_school = {school!r}"))

        # 2. Length in [MIN, MAX]
        L = len(grad_years)
        checks.append((f"length 2-4 (got {L})",
                       MIN_COHORT_LEN <= L <= MAX_COHORT_LEN,
                       ""))

        # 3. Consecutive grad_years (no gaps)
        gaps = [grad_years[i+1] - grad_years[i] for i in range(L - 1)]
        consec = all(g == 1 for g in gaps)
        checks.append((f"consecutive grad_years (gaps {gaps})",
                       consec,
                       ""))

        # 4. Eligibility: tuition_bill non-null AND skipped_year != 1 for all members
        eligible = (rows["tuition_bill"].notna() & (rows["skipped_year"] != 1)).all()
        checks.append(("all rows have tuition_bill non-null and skipped_year != 1",
                       eligible,
                       ""))

        # 5. Starting tuition lookup successful (= tuition[gy-3] exists)
        start_tuitions = []
        all_start_found = True
        for gy in grad_years:
            st = tuition_lookup.get((school, gy - 3))
            if st is None or pd.isna(st):
                all_start_found = False
                break
            start_tuitions.append(float(st))
        checks.append(("starting tuition data exists (tuition at grad_year-3)",
                       all_start_found,
                       (f"start_tuitions = {[f'${s:.2f}k' for s in start_tuitions]}"
                        if all_start_found else "MISSING")))

        if all_start_found:
            # 6. Year-to-year start tuition <= MAX_YEAR_TO_YEAR_START_CHANGE
            yty_diffs = [abs(start_tuitions[i+1] - start_tuitions[i])
                         for i in range(len(start_tuitions) - 1)]
            yty_ok = all(d <= MAX_YEAR_TO_YEAR_START_CHANGE for d in yty_diffs)
            checks.append((
                f"year-to-year start tuition <= ${MAX_YEAR_TO_YEAR_START_CHANGE:.1f}k",
                yty_ok,
                f"yty diffs = {[f'${d:.2f}k' for d in yty_diffs]} (max = ${max(yty_diffs) if yty_diffs else 0:.2f}k)"
            ))

            # 7. Range of starting tuition <= MAX_COHORT_START_RANGE
            start_range = max(start_tuitions) - min(start_tuitions)
            start_ok = start_range <= MAX_COHORT_START_RANGE
            checks.append((
                f"start tuition range <= ${MAX_COHORT_START_RANGE:.1f}k",
                start_ok,
                f"range = ${start_range:.2f}k"
            ))

        # 8. Range of tuition_bill >= MIN_TUITION_BILL_RANGE
        bill_range = max(bills) - min(bills)
        bill_ok = bill_range >= MIN_TUITION_BILL_RANGE
        checks.append((
            f"tuition_bill range >= ${MIN_TUITION_BILL_RANGE:.1f}k",
            bill_ok,
            f"range = ${bill_range:.2f}k"
        ))

        # Print results
        cohort_pass = True
        for name, ok, detail in checks:
            mark = "PASS" if ok else "FAIL"
            line = f"    [{mark}] {name}"
            if detail:
                line += f"  ({detail})"
            print(line)
            if not ok:
                cohort_pass = False

        # 9. Non-overlap is a global property; skip per-cohort, but verify at the end.
        if not cohort_pass:
            overall_pass = False
        print()

    # Global non-overlap check across ALL cohorts
    print("-" * 72)
    print("Global non-overlap check across all cohorts:")
    by_school = df_out[df_out["Cohort_ID"] > 0].groupby("med_school")
    overlap_violations = 0
    for school, sdf in by_school:
        # For each (school, grad_year), Cohort_ID should appear exactly once.
        # Since each row has exactly one Cohort_ID, the test is: are any cohorts
        # of this school sharing a grad_year? Each row only has one ID, so
        # what we're really checking is that within a school, cohort IDs partition
        # a contiguous block correctly. We trust uniqueness of (school, grad_year)
        # in the input data, so just confirm rows aren't double-counted:
        if sdf.duplicated(subset=["med_school", "grad_year"]).any():
            overlap_violations += 1
    if overlap_violations == 0:
        print("  [PASS] no two cohorts share a (school, grad_year) row")
    else:
        print(f"  [FAIL] {overlap_violations} schools have row-level overlap")
        overall_pass = False

    print()
    print("=" * 72)
    print("OVERALL:", "ALL CHECKS PASSED" if overall_pass else "SOME CHECKS FAILED")
    print("=" * 72)


if __name__ == "__main__":
    main()
