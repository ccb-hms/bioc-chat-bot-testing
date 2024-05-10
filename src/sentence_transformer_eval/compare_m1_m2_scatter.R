q1 = fread("~/bioc_ai/data/gpt4_with_scramble.csv")
q2 = fread("~/bioc_ai/data/llama_bioc_qa.csv")

q_df = q1 |> cbind(q2 |> slt(5:6)) |> as_tibble()

grd_ans = fread("~/bioc_ai/output/ground_answer_embed.csv") |> 
    mtt(QID = paste0("question", 1:10)) |> 
    melt(id.vars = "QID") |> 
    roworder(QID) |> 
    dplyr::rename(grd_val = value)

ans_list = list.files("~/bioc_ai/output/", pattern = "[0-9].csv", full.names = TRUE) |> 
    lapply(fread)

model_df = fread("~/bioc_ai/output/model_df.csv")

ans_df = ans_list |> 
    rbindlist() |> 
    mtt(QID = rep(paste0("question", 1:10),
                  each = nrow(ans_list[[1]])),
        source_model = rep(model_df$models,
                           times = 10)) |> 
    dplyr::relocate(QID, source_model) |> 
    melt(id.vars = c("QID", "source_model")) 

cos_sim_df = ans_df |> 
    join(grd_ans, how = "left", validate = "m:1", verbose = FALSE) |> 
    gby(QID, source_model) |>
    smr(cos_sim = cs(value, grd_val))

plot_input <- cos_sim_df |>
    mtt(source_model = gsub("Response_", "", source_model)) |>
    mtt(
        QID = factor(QID, levels = paste0("question", 1:10)),
        source_model = factor(source_model,
                              levels = c(
                                  "Azure_Bioc_RAG", "Azure_GPT4_Temp0",
                                  "llama2_Bioc_RAG", "llama2_Temp0",
                                  "scrambled_ground_truth", "scrambled_mixed_ground_truth",
                                  "scrabble_match_nchar", "scrabble_match_nword",
                                  "reembed_ground_truth"
                              )
        )
    )


q_df = q1 |> cbind(q2 |> slt(5:6)) |> as_tibble()

grd_ans = fread("~/bioc_ai/output/m2/ground_answer_embed_m2.csv") |> 
    mtt(QID = paste0("question", 1:10)) |> 
    melt(id.vars = "QID") |> 
    roworder(QID) |> 
    dplyr::rename(grd_val = value)

ans_list = list.files("~/bioc_ai/output/m2", pattern = "[0-9]_m2.csv", full.names = TRUE) |> 
    lapply(fread)

ans_df = ans_list |> 
    rbindlist() |> 
    mtt(QID = rep(paste0("question", 1:10),
                  each = nrow(ans_list[[1]])),
        source_model = rep(model_df$models,
                           times = 10)) |> 
    dplyr::relocate(QID, source_model) |> 
    melt(id.vars = c("QID", "source_model")) 

cos_sim_df = ans_df |> 
    join(grd_ans, how = "left", validate = "m:1", verbose = FALSE) |> 
    gby(QID, source_model) |>
    smr(cos_sim = cs(value, grd_val))

plot_input2 <- cos_sim_df |>
    mtt(source_model = gsub("Response_", "", source_model)) |>
    mtt(
        QID = factor(QID, levels = paste0("question", 1:10)),
        source_model = factor(source_model,
                              levels = c(
                                  "Azure_Bioc_RAG", "Azure_GPT4_Temp0",
                                  "llama2_Bioc_RAG", "llama2_Temp0",
                                  "scrambled_ground_truth", "scrambled_mixed_ground_truth",
                                  "scrabble_match_nchar", "scrabble_match_nword",
                                  "reembed_ground_truth"
                              )
        )
    )

plot_input |> 
    join(plot_input2, on = c("QID", "source_model")) |> 
    ggplot(aes(cos_sim, cos_sim_plot_input2)) + 
    geom_smooth(method = "lm", se = FALSE) + 
    geom_abline(lty = 2, color = "grey", slope = 1, intercept = 0) + 
    geom_point(aes(color = source_model)) + 
    facet_wrap(vars(QID))
