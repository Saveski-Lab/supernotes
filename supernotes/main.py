import numpy as np
import itertools
from summarizer import get_summaries, prompt_generator
from embedder import get_embedding
from phm import predict_rating_sample
from aggregator import aggregate, sample_users
from evaluator import checkPrinciples, linkCheck

## Constants ========
NUM_RATERS = 1000
NUM_SUMMARIES = 101
## ==================

def get_note_indices(notes, note_list):
    note_indices = []
    for note in note_list:
        if note in notes:
            note_indices.append(notes.index(note))
    return note_indices

def run_pipeline(tweet, notes, tags=[], principle_checks=True):

    if len(tags) == 0:
        note_combination_list = []
        for r in range(2, len(notes) + 1): 
            combinations = list(itertools.combinations(notes, r))
            note_combination_list.extend(combinations)

        all_notes_combinations = [list(comb) for comb in note_combination_list]
        summaries = []
        summarised_notes = []

        print(f"======= Getting Candidate Summaries (# notes: {len(notes)}) =======")
        for index,note_list in enumerate(all_notes_combinations):
            note_indices = get_note_indices(notes, note_list)

            #print("======= Generating Prompt =======")
            generated_prompt = prompt_generator(tweet, note_list)

            #print("======= Getting Candidate Summaries =======")
            out = get_summaries(generated_prompt, max((NUM_SUMMARIES//len(all_notes_combinations),1)))
            out = out.to_dict() if hasattr(out, 'to_dict') else out
            
            for choice in out['choices']:
                if 'content' in choice['message'].keys():
                    summaries.append(choice['message']['content'])
                    summarised_notes.append(note_indices)
            #time.sleep(60)
    else:
        note_combination_list = []
        tag_combination_list = []
        for r in range(2, len(notes) + 1): 
            combinations = list(itertools.combinations(notes, r))
            tag_combinations = list(itertools.combinations(tags, r))
            note_combination_list.extend(combinations)
            tag_combination_list.extend(tag_combinations)


        all_notes_combinations = [list(comb) for comb in note_combination_list]
        all_tags_combinations = [list(comb) for comb in tag_combination_list]
        summaries = []
        summarised_notes = []

        print(f"======= Getting Candidate Summaries (# notes: {len(notes)}) =======")
        for index,note_list in enumerate(all_notes_combinations):
            note_indices = get_note_indices(notes, note_list)

            #print("======= Generating Prompt =======")
            generated_prompt = prompt_generator(tweet, note_list, all_tags_combinations[index])

            #print("======= Getting Candidate Summaries =======")
            out = get_summaries(generated_prompt, max((NUM_SUMMARIES//len(all_notes_combinations),1)))
            out = out.to_dict() if hasattr(out, 'to_dict') else out
            
            for choice in out['choices']:
                if 'content' in choice['message'].keys():
                    summaries.append(choice['message']['content'])
                    summarised_notes.append(note_indices)
            #time.sleep(60)
    
    summaries_filtered = []            
    if principle_checks:
        print(f"======= Checking for principle-alignment =======")
        for summary in summaries:
            print(summary)
            print(checkPrinciples(summary,notes))
            if checkPrinciples(summary,notes):
                summaries_filtered.append(summary)
            
    else:
        print(f"======= Checking for links & Length =======")
        for summary in summaries:
            if linkCheck(summary,notes):
                summaries_filtered.append(summary)
    
    print("======= Getting Summary Embeddings =======")
    summary_embeddings = []
    for summary in summaries_filtered:
        curr_embedding = get_embedding(summary)
        summary_embeddings.append(curr_embedding)
    
    curr_tweet_embedding = get_embedding(tweet)

    print("======= Sampling Synthetic Raters =======")
    users = sample_users(NUM_RATERS) # same users rate all summaries
    users_mat = np.array(users)
    user_factors = np.transpose(np.expand_dims(users_mat[:,0], axis=0)) # for aggregating
    user_intercepts = np.transpose(np.expand_dims(users_mat[:,1], axis=0)) # for aggregating

    print("======= Scoring Summaries =======")
    summary_scores = []
    for summary_embedding in summary_embeddings:
        rm_input = []
        for user in users:
            rm_input.append(user + summary_embedding + curr_tweet_embedding)
        preds = np.array(predict_rating_sample(rm_input))
        ratings = np.transpose(np.expand_dims(preds, axis=0))
        summary_score = aggregate(ratings, user_intercepts, user_factors)
        summary_scores.append(summary_score[1][0])
    
    return (summaries_filtered, summarised_notes, summary_scores)

def testSupernote():
    # dummy example from https://communitynotes.x.com/guide/en/contributing/examples
    curr_tweet = "Another big day at the Supreme Court ending with a police car being lit on fire. 😨"
    curr_notes = ["This photo was taken in Toronto at a protest of the 2010 G20 summit where G20 officials met to discuss the world economy, not at the Supreme Court in Washington D.C. You can see the car in this photo being lit on fire via a local Toronto news broadcast: https://www.youtube.com/watch",
                "The last time it was reported that a police car was lit on fire outside the Supreme Court was on 7/15/2020. This photo is not from that incident. This photo was taken in Toronto at a protest of the 2010 G20 summit. https://www.cbsnews.com/news/, https://www.cp24.com/breaking/",
                "Wow, people really hate cops. They just park there car to go into the office and it’s suddenly fair game to be torched. Some of you need to relax.",
                "This is totally made up. There are no reports of a fire outside the Supreme Court today. X should ban this account for spreading lies. https://www.supremecourt.gov/"]
    tags_on_notes = [['helpfulGoodSources', 'helpfulClear', 'helpfulAddressesClaim'],
                     ['helpfulGoodSources', 'helpfulClear', 'helpfulAddressesClaim'],
                     ['notHelpfulSourcesMissingOrUnreliable','notHelpfulOpinionSpeculationOrBias','notHelpfulMissingKeyPoints'],
                     ['notHelpfulSourcesMissingOrUnreliable', 'notHelpfulIncorrect','notHelpfulOpinionSpeculationOrBias']]
    ## ==================
    
    (summary, summarised_note_indices, score) = run_pipeline(curr_tweet, curr_notes, tags_on_notes, principle_checks=False)
    max_score_index = score.index(max(score))
    best_summary = summary[max_score_index]
    print(best_summary) # Supernote

if __name__ == "__main__":
    testSupernote()