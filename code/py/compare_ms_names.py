import pandas as pd
from difflib import SequenceMatcher
import itertools


df = pd.read_csv("C:/dropbox/Phil Research Dropbox/Victoria Garcia/Student Debt of Doctors/Tuition Data/simon/student-debt-of-doctors/data/working/temp/doc_characteristics_contradictory_ms_wide.csv")


# Compare across med schoool columns
cols = ['ms1', 'ms2', 'ms3', 'ms4', 'ms5']



def similar(a, b):
    if pd.isna(a) or pd.isna(b):
        return None
    return SequenceMatcher(None, a, b).ratio()


for m1, m2 in itertools.combinations(cols, 2):
        ms_comp = f'{m1}_vs_{m2}'
        df[ms_comp] = df.apply(lambda row : similar(row[m1], row[m2]), axis=1)





