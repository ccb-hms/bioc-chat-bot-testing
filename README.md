# Gen AI experiments for Bioconductor

Experiments to build Bioconductor chatbots using Gen AI

## Contents
1. infrastructure - scripts for interacting with azure and ollama models, creating RAG stores, retrieving data from Bioc, etc. 
2. evaluation - scripts for response quality evaluation and small manually-curated evaluation datasets in csv
    - embedding-based: semantic textual similarity between ground truth responses and model responses to questions from the support site
    - code-diffusion: using LLMs to correct code errors and discouraged coding practices
    - llm-as-a-judge: having an LLM evaluating the responses of an LLM 
