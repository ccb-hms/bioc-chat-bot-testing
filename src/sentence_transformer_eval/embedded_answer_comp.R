library(fastverse)
library(pheatmap)
library(tibble)
library(ggplot2)

options(digits = 2)
q1 = fread("azure-gpt4-RAG/gpt4_with_scramble.csv")
q2 = fread("llama2-RAG/llama_bioc_qa.csv")

q_df = q1 |> cbind(q2 |> slt(5:6)) |> as_tibble()

grd_ans = fread("output/ground_answer_embed.csv") |> 
    mtt(QID = paste0("question", 1:10)) |> 
    melt(id.vars = "QID") |> 
    roworder(QID) |> 
    dplyr::rename(grd_val = value)

ans_list = list.files("output", pattern = "[0-9].csv", full.names = TRUE) |> 
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
    join(grd_ans, how = "left", validate = "m:1") |> 
    mtt(dot_contrib = value * grd_val) |> 
    fgroup_by(QID, source_model) |> 
    smr(cos_sim = fsum(dot_contrib))

# plot_input = cos_sim_df |> 
#     mtt(QID = factor(QID, levels = paste0("question", 1:10)))
# 
# plot_input |> 
#     ggplot(aes(QID, cos_sim)) + 
#     geom_col(aes(group = source_model,
#                  fill = source_model),
#              position = position_dodge()) + 
#     ylim(0,1) + 
#     scale_fill_manual(values = pals::cols25(4)) + 
#     theme_bw() + 
#     theme(axis.text.x = element_text(angle = 90, vjust = .5)) + 
#     labs(title = "Cosine similarity between model answers and ground truth answer")
# 
# # Q4, where GPT4 temp0 seems to have done much better than the others
# q_df |> sbt(QID == "question4") |> get_elem("Response")
# q_df |> sbt(QID == "question4") |> slt(5:8) |> names()
# q_df |> sbt(QID == "question4") |> slt(5:8) |> unlist() |> cat(sep = "\n\n########\n\n")
# 
# # Let's look at the worst one
# q2 |> as_tibble() |> sbt(QID == "question6") |> get_elem("Question") |> cat()
# q2 |> as_tibble() |> sbt(QID == "question6") |> get_elem("Response") |> cat()
# q2 |> as_tibble() |> sbt(QID == "question6") |> get_elem("Response_llama2_Bioc_RAG") |> cat()
# q1 |> as_tibble() |> sbt(QID == "question6") |> get_elem("Response_Azure_Bioc_RAG") |> cat()
# 
# q2 |> as_tibble() |> sbt(QID == "question9") |> get_elem("Question")

hm_input = ans_df |> 
    rbind(grd_ans |> mtt(source_model = "ground truth") |> dplyr::rename(value = grd_val))

hm_wide = hm_input |> 
    roworder(QID, source_model) |> 
    tidyr::pivot_wider(id_cols = c("QID", "source_model"), names_from = "variable") |> 
    as.data.table() |> 
    mtt(rn = paste0(QID, source_model)) |> 
    column_to_rownames("rn") 

hm_anno = hm_wide |> 
    slt(1:2) |> 
    set_rownames(rownames(hm_wide))

# pheatmap(hm_wide |> slt(-(1:2)) |> as.matrix(), 
#          cluster_rows = FALSE, cluster_cols = FALSE, 
#          gaps_row = seq(5, 45, by = 5), #annotation_row = hm_anno |> slt(2),
#          annotation_colors = pals::cols25(25), labels_col = "",
#          color = pals::coolwarm(100))

# tmp = hm_wide |> uwot::umap()

tmp |> as.data.table() |> 
    cbind(hm_anno) |> 
    mtt(grnd_truth = source_model == "ground truth") |> 
    ggplot(aes(V1, V2)) + 
    geom_point(aes(color = QID,
                   shape = grnd_truth), size = 3) + 
    theme_bw() + 
    scale_color_manual(values = pals::cols25())

tmp |> as.data.table() |> 
    cbind(hm_anno) |> 
    join(plot_input) |> 
    mtt(grd = (source_model == "ground truth")*1 + 1,
        cos_sim = dplyr::case_when(is.na(cos_sim) ~ 1,
                        TRUE ~ cos_sim)) |> 
    ggplot(aes(V1, V2)) + 
    geom_point(aes(color = QID,
                   shape = source_model, 
                   size = cos_sim)) + 
    theme_bw() + 
    labs(x = "UMAP1", y = "UMAP2", size = "cos_sim") + 
    scale_color_manual(values = pals::cols25()) + 
    scale_size_area()

# ggsave("~/Desktop/tmp.png", w = 12, h = 9)    
