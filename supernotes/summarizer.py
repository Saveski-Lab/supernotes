from openai import OpenAI
import json 

with open("secrets.json") as f:
    secrets = json.load(f)
    api_key = secrets["OPENAI_API_KEY"]

client = OpenAI(api_key=api_key)

prompt_1 = """
Twitter has a crowd-sourced fact-checking program, called Community Notes. Here, users can write 'notes' on potentially misleading content. Each note needs to be rated by enough number of diversely-opinionated people (note-raters) for it to be shown publicly alongside the piece of content. 

Your job is to craft a 'supernote' summarising main points from existing notes (which I will provide). This supernote should be able to replace all existing notes. The goal of the supernote is to maximise consensus among diversely opinionated note-raters. It should be in unbiased language, not argumentative, cite high-quality sources (links) whenever applicable and should not add/ make-up new facts. It should also be within 280 characters.
"""

def get_summaries(test_string, num=1, initial_prompt=prompt_1, temp=0.95, top_p=0.8):
    completion = client.chat.completions.create(model="gpt-4o-mini",
    messages = [
        {"role": "system", "content": initial_prompt},
        {"role": "user", "content": test_string},
    ],
    n=num,
    temperature=temp,
    max_tokens=800,
    top_p=top_p,
    frequency_penalty=0,
    presence_penalty=0,
    stop=None)
    return completion

def prompt_generator(tweet, notes, tags=[]):
    if len(tags) == 0:
        prompt = f"Original Tweet: {tweet}\n\nNotes: \n"
        for num in range(len(notes)):
            prompt += f"{num + 1}. {notes[num]}\n\n"
    else:
        prompt = f"Original Tweet: {tweet}\n\nNotes: \n"
        for num in range(len(notes)):
            prompt += f"{num + 1}. {notes[num]} (Tags: "
            for tag in tags[num]:
                prompt += tag+', '
            prompt = prompt[:-2]    
            prompt += ")\n\n"
    return prompt

def prompt_generator_notweet(notes):
    prompt = f"Notes: \n"
    for num in range(len(notes)):
        prompt += f"{num + 1}. {notes[num]}\n\n"
    return prompt

if __name__ == "__main__":
    curr_tweet = "Another big day at the Supreme Court ending with a police car being lit on fire. 😨"
    curr_notes = ["This photo was taken in Toronto at a protest of the 2010 G20 summit where G20 officials met to discuss the world economy, not at the Supreme Court in Washington D.C. You can see the car in this photo being lit on fire via a local Toronto news broadcast: https://www.youtube.com/watch...",
                "The last time it was reported that a police car was lit on fire outside the Supreme Court was on 7/15/2020. This photo is not from that incident. This photo was taken in Toronto at a protest of the 2010 G20 summit. https://www.cbsnews.com/news/..., https://www.cp24.com/breaking/...",
                "Wow, people really hate cops. They just park there car to go into the office and it’s suddenly fair game to be torched. Some of you need to relax.",
                "This is totally made up. There are no reports of a fire outside the Supreme Court today. X should ban this account for spreading lies. https://www.supremecourt.gov/"]
    tags_on_notes = [['helpfulGoodSources', 'helpfulClear', 'helpfulAddressesClaim'],
                     ['helpfulGoodSources', 'helpfulClear', 'helpfulAddressesClaim'],
                     ['notHelpfulSourcesMissingOrUnreliable','notHelpfulOpinionSpeculationOrBias','notHelpfulMissingKeyPoints'],
                     ['notHelpfulSourcesMissingOrUnreliable', 'notHelpfulIncorrect','notHelpfulOpinionSpeculationOrBias']]

    generated_prompt = prompt_generator(curr_tweet, curr_notes)
    print(generated_prompt)

    generated_prompt = prompt_generator(curr_tweet, curr_notes, tags_on_notes)
    print(generated_prompt)

    out = get_summaries(generated_prompt, 3)
    out = out.to_dict() if hasattr(out, 'to_dict') else out

    for choice in out['choices']:
        if 'content' in choice['message'].keys():
            print(choice['message']['content'])
         