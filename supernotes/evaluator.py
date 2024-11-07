from openai import OpenAI
import re
import json 

with open("secrets.json") as f:
    secrets = json.load(f)
    api_key = secrets["OPENAI_API_KEY"]

client = OpenAI(api_key=api_key)

prompt_unbiased = "Answer with a 1(Yes) or 0 (No). Is this text written in a reasonably neutral and unbiased language?"
prompt_speculation = "Answer with a 1(Yes) or 0 (No). Does this text explicitly express speculations and opinions?"

def linkCheck(summary, notes):
    existing_urls = set()
    for note in notes:
        curr_urls = re.findall(r'(https?://[^\s\),]+)', note)
        existing_urls.update(curr_urls)
    #print('all set:', existing_urls)
    summary_urls = re.findall(r'(https?://[^\s\),]+)', summary)
    #print('in current set:', summary_urls)
    for url in summary_urls:
        if url not in existing_urls:
            return False
    return True

def llmEval(summary):
    unbiased_gpt_out = client.chat.completions.create(model="gpt-4o-mini",
    messages = [
        {"role": "system", "content": prompt_unbiased},
        {"role": "user", "content": summary},
    ]).to_dict()

    speculation_gpt_out = client.chat.completions.create(model="gpt-4o-mini",
    messages = [
        {"role": "system", "content": prompt_speculation},
        {"role": "user", "content": summary},
    ]).to_dict()

    #print('bias (1 is good)', unbiased_gpt_out['choices'][0]['message']['content'])
    #print('speculation (0 is good)', speculation_gpt_out['choices'][0]['message']['content'])

    if unbiased_gpt_out['choices'][0]['message']['content'] == '1' and speculation_gpt_out['choices'][0]['message']['content'] == '0':
        return True
    else:
        return False

def lenCheck(summary):
    summary_urls = re.findall(r'(https?://[^\s\),]+)', summary)
    if len(summary) - sum(len(url) for url in summary_urls) <281:
        return True
    else: return False


def checkPrinciples(summary, notes):
    #print(f"linkCheck: {linkCheck(summary, notes) }, len: {lenCheck(summary)}")
    if llmEval(summary) and linkCheck(summary, notes) and lenCheck(summary):
        return True
    else:
        return False

def testEvaluator():
    s1 = 'The world is a https://www.google.com peaceful place'
    print(checkPrinciples(s1, ["this is a note https://www.google.com", "this is https://www.anotherlink.com"]))

if __name__ == "__main__":
    testEvaluator()