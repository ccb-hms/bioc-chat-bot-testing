## OllamaRag demo on  O2
3/6/24

### overview
This will try to demonstrate running llama2 on O2 cluster with a local Chroma vector storage. This Chroma db has 4 pdf versions of vignettes related to [SummarizedExperiment](https://bioconductor.org/packages/release/bioc/html/SummarizedExperiment.html) which were processed with `pyPDF` and embedded into vectors with the `ggml-all-MiniLM-L6-v2-f1` sentence transformer model. I'm not sure who made it but its part of huggingface's `sentence-transformers` library.


1. allocate resources in a interactive node, we will use the `gpu_ccb` partition for this demo but you can run this on the regular `gpu` queue.

`srun --account=gentleman_rcg7_contrib --pty -p interactive -t 0-01:00 --mem 16G -c 4 -p gpu_ccb --gres=gpu:1 /bin/bash`

`module load gcc/9.2.0 cuda/12.1 python/3.10.11`

2. start a tmux session in that interactive session (also take note of the node you're working on)

`tmux new -s ollamasession`

3. run the ollama container, be sure to put the model weights on the scratch folder
` export APPTAINERENV_OLLAMA_MODELS="/n/scratch/users/t/tyl916/ollama/models`

` singularity instance start --nv -B /n/scratch/users/t/tyl916  /n/app/singularity/containers/shared/ollama-0.1.27.sif "ollama"`

`singularity shell instance://ollama`

`Apptainer> ollama serve`

`ctrl + B , d`


4. after following all those steps you can now use ollama on the Compute Node to have a CLI for models on http://127.0.0.1:11434
`curl -X POST http://127.0.0.1:11434/api/generate -d '{
  "model": "llama2",
  "prompt":"Write a haiku about the blue sky"
 }'`



8. since the service is running on the compute node at PORT 11434, requests to the model can used in python scripts, we will use a python terminal session to prototype the process.

```python
from langchain.llms import Ollama
ollama = Ollama(base_url='http://127.0.0.1:11434',model="llama2")
print(ollama.invoke("make a haiku about green hills zone from sonic"))
```


9. Demonstrate RAG
```python
from langchain_community.embeddings.sentence_transformer import (
    SentenceTransformerEmbeddings,
)
from langchain_community.vectorstores import Chroma
from langchain.chains import RetrievalQA


embedding_function = SentenceTransformerEmbeddings(model_name="all-MiniLM-L6-v2")
question = "How many classes are there in the SummarizedExperiment package?"

# load from disk
minibioc_db = Chroma(persist_directory="/home/tyl916/bioc_vignettes/chroma_db", embedding_function=embedding_function)
docs = minibioc_db.similarity_search(query)
print(docs[0].page_content)

qachain=RetrievalQA.from_chain_type(ollama, retriever=minibioc_db.as_retriever())
qachain({"query": question})

```

```python
# the new LangChain Expression Language (LCEL) way
from langchain import hub

# Retrieve and generate using the relevant data from vector store
retriever = minibioc_db.as_retriever(search_type="similarity", search_kwargs={"k": 6})
prompt = hub.pull("rlm/rag-prompt")

rag_chain = (
    {"context": retriever | format_docs, "question": RunnablePassthrough()}
    | prompt
    | ollama
    | StrOutputParser()
)

rag_chain.invoke("How many classes are there in the SummarizedExperiment package?")
