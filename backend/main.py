from ollama import Client
import os

client = Client(
    host="https://ollama.com",
    headers={"Authorization": f"Bearer {os.environ.get('OLLAMA_API_KEY')}"},
)

messages = [
    {"role": "user", "content": "What is the capital of India?"},
]


for part in client.chat("gpt-oss:120b", messages=messages, stream=True):
    print(part["message"]["content"], end="", flush=True)
