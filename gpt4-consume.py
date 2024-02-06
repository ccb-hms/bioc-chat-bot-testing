import os
from openai import AzureOpenAI

client = AzureOpenAI(
  api_key = os.getenv("AZURE_OPENAI_KEY"),  
  api_version = "2023-03-15-preview",
  azure_endpoint = os.getenv("AZURE_OPENAI_ENDPOINT"),  
)

response = client.chat.completions.create(
    model="gpt-4", # model = "deployment_name".
    messages=[
        {"role": "system", "content": "Assistant is a Scientist acting as a resource for biomedical research."},
        {"role": "user", "content": "What are Yamanaka factors?"}
    ]
)

#print(response)
print(response.model_dump_json(indent=2))
print(response.choices[0].message.content)