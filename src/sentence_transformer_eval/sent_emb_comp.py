#!/usr/bin/env python
# coding: utf-8

# In[1]:


# %pip install sentence_transformers polars


# 
# ## Goals
# 
# 1. Run the Qs through multiple LLMs to get answers
# 2. Run the answers through (multiple?) sentence embedding models
# 3. Compute the cosine distance between the embedded answers against the embedded ground truth answer.
# 4. Rank LLMs by cosine similarity to embedded ground truth.
# 

# In[2]:


from pathlib import Path
import polars as pl
import transformers
import torch
import numpy as np
import random as rd
from sentence_transformers import SentenceTransformer

device = torch.device("cuda")

model2 = SentenceTransformer('pritamdeka/S-PubMedBert-MS-MARCO')


# In[3]:


torch.cuda.get_device_name(0)


# ### part 1
# We will attempt this query on the QA sample of 10 bioconductor support threads. Thought of using [ ](https://huggingface.co/mchochlov/codebert-base-cd-ft) but it probably makes more sense to use the [multi-QA pretrained](https://www.sbert.net/docs/pretrained_models.html#multi-qa-models) encoders 

# In[4]:


model = SentenceTransformer('multi-qa-MiniLM-L6-cos-v1')
# Embeds input sentences to 384 dimensions.


# In[5]:


q_df = pl.read_csv('/home/ang9994/bioc_ai/data/gpt4_with_scramble.csv', separator = "\t")
q_df2 = pl.read_csv('/home/ang9994/bioc_ai/data/llama_bioc_qa.csv')
q_df.select(pl.col("Question", "Response"))


# In[6]:


comb_df = pl.concat([q_df, q_df2.select(pl.col("Response_llama2_Bioc_RAG", "Response_llama2_Temp0"))], how = "horizontal")


# In[7]:


comb_df


# In[8]:


questions = q_df['Question'].to_list()
answers = q_df['Response'].to_list()


# In[9]:


# embed the curated responses ('answers' in this case)
grd_embed = model.encode(answers)
grd_embed2 = model2.encode(answers)
grd_embed.shape # no parentheses, DUH GHAZI! numpy sucks.


# In[10]:


pl.from_numpy(grd_embed).write_csv("/home/ang9994/bioc_ai/output/ground_answer_embed.csv")
pl.from_numpy(grd_embed2).write_csv("/home/ang9994/bioc_ai/output/m2/ground_answer_embed_m2.csv")


# In[11]:


#ans_list = [comb_df.select(pl.col("Response_Azure_GPT4_Temp0")).item(idx,0),
#                comb_df.select(pl.col("Response_Azure_Bioc_RAG")).item(idx,0),
#               comb_df.select(pl.col("Response_llama2_Bioc_RAG")).item(idx,0),
#               comb_df.select(pl.col("Response_llama2_Temp0")).item(idx,0)]
#    
#query_embedding = model.encode(ans_list, convert_to_tensor=True)


# In[12]:


# %% time

df = pl.DataFrame(
    {
        "models": ["Response_Azure_GPT4_Temp0", 
                   "Response_Azure_Bioc_RAG",
                   "Response_llama2_Bioc_RAG",
                   "Response_llama2_Temp0",
                   "scrambled_ground_truth",
                   "scrambled_mixed_ground_truth",
                   "scrabble_match_nword",
                   "scrabble_match_nchar",
                   "reembed_ground_truth"]
    }
)

print(df)

df.write_csv("/home/ang9994/bioc_ai/output/model_df.csv")


# In[13]:


for idx, query in enumerate(questions):

    ans_list = [comb_df.select(pl.col("Response_Azure_GPT4_Temp0")).item(idx,0),
                comb_df.select(pl.col("Response_Azure_Bioc_RAG")).item(idx,0),
                comb_df.select(pl.col("Response_llama2_Bioc_RAG")).item(idx,0),
                comb_df.select(pl.col("Response_llama2_Temp0")).item(idx,0),
                comb_df.select(pl.col("scrambled_ground_truth")).item(idx,0),
                comb_df.select(pl.col("scrambled_mixed_ground_truth")).item(idx,0),
                comb_df.select(pl.col("scrabble_match_nword")).item(idx,0),
                comb_df.select(pl.col("scrabble_match_nchar")).item(idx,0),
                comb_df.select(pl.col("reembed_ground_truth")).item(idx,0)]
    
    query_embedding = model.encode(ans_list, convert_to_tensor=True).cpu().numpy()
    m2_emb = model2.encode(ans_list, convert_to_tensor=True).cpu().numpy()

    pl.from_numpy(query_embedding).write_csv("/home/ang9994/bioc_ai/output/" + str(idx) + ".csv")
    pl.from_numpy(m2_emb).write_csv("/home/ang9994/bioc_ai/output/m2/" + str(idx) + "_m2.csv")


# Do all the evaluations in RStudio because Jupyter is what you'd get if you turned Jar Jar Binks into an IDE.
