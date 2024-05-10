library(tidyverse)
library(words)

d = read_csv("data/top_10_qs_with_azure_RAG.csv")

scramble = function(sent) {
    words = strsplit(sent, " ")[[1]]
    n = length(words)
    sample(words, size = n, replace = FALSE) |> paste(collapse = " ")
}

sample_n_words = function(baseline) {
    n_word = strsplit(baseline, " ")[[1]] |> 
        length()
    
    words |> 
        slice_sample(n = n_word) |> 
        pull(word) |> 
        paste(collapse = " ")
}

sample_n_char = function(baseline, word_df) {
    n_char = nchar(baseline)
    
    samp_nchar = 0
    i = 0
    word_vec = vector("character", length = 1000)
    
    while(samp_nchar < n_char) {
        i = i+1
        
        next_word = sample(word_df$word, size = 1)
        
        word_vec[i] = next_word
        
        samp_nchar = samp_nchar + nchar(next_word) + 1
    }
    
    paste0(word_vec[1:i], collapse = " ")
}

set.seed(123)

resp_word_df = d |>
    pull(Response) |> 
    paste0(collapse = " ") |>
    str_split_1(pattern = " ") |>
    tibble(word = _)

d = d |> 
    mutate(scrambled_ground_truth = map_chr(Response, scramble),
           scrambled_mixed_ground_truth = map_chr(Response,
                                                  sample_n_char,
                                                  word_df = resp_word_df),
           scrabble_match_nword = map_chr(Response,
                                          sample_n_words),
           scrabble_match_nchar = map_chr(Response, 
                                          sample_n_char,
                                          word_df = words),
           reembed_ground_truth = Response) 

d |> 
    write_tsv('data/gpt4_with_scramble.csv', quote = "all")
