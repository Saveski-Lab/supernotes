from openai import OpenAI
import json

with open("secrets.json") as f:
   secrets = json.load(f)
   api_key = secrets["OPENAI_API_KEY"]

client = OpenAI(api_key=api_key)

def get_embedding(text, model="text-embedding-ada-002"):
   text = str(text).replace("\n", " ")
   response = client.embeddings.create(
      input=text,
      model="text-embedding-3-small",
      dimensions=512)
   return response.data[0].embedding

def testEmbedder():
   test_embedding = get_embedding('hello world')
   print(len(test_embedding)) # sanity check

if __name__ == "__main__":
   testEmbedder()
   
