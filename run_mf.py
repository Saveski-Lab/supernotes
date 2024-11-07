from unittest.mock import patch
from public.scoring.pandas_utils import PandasPatcher
from public.scoring.matrix_factorization.matrix_factorization import MatrixFactorization
import public.scoring.constants as c

_pandasErrPatcher = PandasPatcher(fail=False)
safe_concat_err = _pandasErrPatcher.safe_concat()
safe_join_err = _pandasErrPatcher.safe_join()
safe_merge_err = _pandasErrPatcher.safe_merge()
safe_apply_err = _pandasErrPatcher.safe_apply()
safe_init_err = _pandasErrPatcher.safe_init()

merge_patcher = patch("pandas.DataFrame.merge", safe_merge_err)
join_patcher = patch("pandas.DataFrame.join", safe_join_err)
concat_patcher = patch("pandas.concat", safe_concat_err)
apply_patcher = patch("pandas.DataFrame.apply", safe_apply_err)
init_patcher = patch("pandas.DataFrame.__init__", safe_init_err)

merge_patcher.start()
join_patcher.start()
concat_patcher.start()
apply_patcher.start()
init_patcher.start()

import numpy as np
import pandas as pd
import os

DATA_ROOT = f"communitynotes/data/"
# NOTE_PATH = os.path.join(DATA_ROOT, "combined_notes_by_minute_parquet")
# RATINGS_PATH = os.path.join(DATA_ROOT, "combined_ratings_by_minute_parquet")
PRESCORING_RATER_MODEL_OUTPUT_PATH = os.path.join(DATA_ROOT, "helpfulness_scores.tsv")
NOTE_MODEL_OUTPUT_PATH = os.path.join(DATA_ROOT, "scored_notes.tsv")

# notes = pd.read_parquet(NOTE_PATH)
# ratings = pd.read_parquet(RATINGS_PATH)
prescoringRaterModelOutput = pd.read_csv(PRESCORING_RATER_MODEL_OUTPUT_PATH, sep='\t')
noteModelOutput = pd.read_csv(NOTE_MODEL_OUTPUT_PATH, sep='\t')

baselineRatings = pd.read_csv('data/baseline_results_withids.csv')
surveyRatings = pd.read_csv('data/survey_results_withids.csv')
surveyRatings['noteId'] = surveyRatings['noteId'].apply(lambda x: int(x.replace("SN","11110000")))
surveyRatings['noteId'] = pd.to_numeric(surveyRatings['noteId'], errors='coerce').astype('Int64')  # Use 'Int64' to handle NaNs
surveyRatings['noteId'] = surveyRatings['noteId'].astype(np.int64)
baselineRatings['noteId'] = baselineRatings['noteId'].astype(np.int64)

ratingCols = ['userId','noteId','rating']
concatRatings = pd.concat([baselineRatings[ratingCols], surveyRatings[ratingCols]])
noteModelOutput['noteId'] = noteModelOutput[c.noteIdKey].astype(str)
concatRatings['noteId'] = concatRatings['noteId'].astype(str)
concatRatings.rename(columns={'rating': 'helpfulNum'}, inplace=True)

concatRatings.rename(columns={'userId':c.raterParticipantIdKey}, inplace=True)
noteModelOutput['noteId'] = noteModelOutput['noteId'].astype(np.int64)
concatRatings['noteId'] = concatRatings['noteId'].astype(np.int64)
noteInit = concatRatings.merge(noteModelOutput, on='noteId')[['noteId', c.coreNoteInterceptKey, c.coreNoteFactor1Key]].drop_duplicates()
noteInit['noteId'] = noteInit['noteId'].astype(np.int64)
ratingsOnExistingNotes = concatRatings.merge(noteModelOutput, on='noteId')
ratingsOnExistingNotes['noteId'] = ratingsOnExistingNotes['noteId'].astype(np.int64)

noteInit.rename(columns={
    c.coreNoteInterceptKey: c.internalNoteInterceptKey, 
    c.coreNoteFactor1Key: c.internalNoteFactor1Key
}, inplace=True)

mf = MatrixFactorization()
noteParams, raterParams, _ = mf.run_mf(
    ratings=ratingsOnExistingNotes,
    noteInit=noteInit,
    globalInterceptInit=0.17, # this is the core global intercept from prescoring
    freezeNoteParameters=True,
    freezeGlobalParameters=True
)

concatRatings['noteId'] = concatRatings['noteId'].astype(int)

noteParamsLearned, _, _ = mf.run_mf(
    ratings=concatRatings,
    userInit = raterParams,
    globalInterceptInit=0.17,
    freezeRaterParameters=True,
    freezeGlobalParameters=True
)

noteModelOutput['noteId'] = noteModelOutput[c.noteIdKey].astype(np.int64)
npFinal = noteParamsLearned.merge(noteModelOutput[[c.noteIdKey, c.coreNoteInterceptKey, c.coreNoteFactor1Key]], on=c.noteIdKey, how='left')
npFinal['delta'] = npFinal[c.internalNoteInterceptKey] - npFinal[c.coreNoteInterceptKey]
npFinal[~pd.isna(npFinal['delta'])].sort_values(by='delta')
surveyNotesWithScores = surveyRatings.merge(npFinal, on='noteId')[['tweetId', 'noteId', 'type',  'sn', 'internalNoteIntercept', 'internalNoteFactor1']].drop_duplicates()
surveyNotesWithScores['wouldBeCRH'] = surveyNotesWithScores['internalNoteIntercept'] >= 0.4

surveyNotesWithScores.to_csv('../analysis/data/survey_notes_with_scores.csv')