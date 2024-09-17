#
# finetuning sample
#
# 参考:finetuning_EDA.ipynb

import numpy as np
#from tqdm.auto import tqdm

import torch
import torch.nn as nn

from datasets import load_dataset
from transformers import (
    set_seed,
    BitsAndBytesConfig,
    AutoModelForSequenceClassification,
    AutoTokenizer,
    TrainingArguments,
)
from transformers.modeling_outputs import ModelOutput
from peft import LoraConfig, PeftModel
from trl import SFTTrainer

#import spacy
#from sklearn.feature_extraction.text import TfidfVectorizer
#from sklearn.cluster import KMeans
#from sklearn.metrics.pairwise import cosine_similarity

# 定数の定義
SEED_NUMBER=42

# シードを固定する
set_seed(SEED_NUMBER)

# データのロード
dataset = load_dataset(
    "shunk031/livedoor-news-corpus",
    train_ratio=0.8,
    val_ratio=0.1,
    test_ratio=0.1,
    random_state=42,
    shuffle=True,
    trust_remote_code=True,
)
num_categories = len(set(dataset["train"]["category"]))
max_seq_length = 512

#print(dataset["train"][0])


# モデルロード
model_name = "elyza/ELYZA-japanese-Llama-2-7b"

bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
#    bnb_4bit_compute_dtype=torch.bfloat16,
     bnb_4bit_compute_dtype=torch.float,
    bnb_4bit_use_double_quant=True,
#    bnb_4bit_quant_storage=torch.bfloat16,
    bnb_4bit_quant_storage=torch.float,
)

pretrained = AutoModelForSequenceClassification.from_pretrained(
    model_name,
    num_labels=num_categories,
    quantization_config=bnb_config,
#    torch_dtype=torch.bfloat16,
    torch_dtype=torch.float,
    low_cpu_mem_usage=True,
)
tokenizer = AutoTokenizer.from_pretrained(model_name, max_seq_length=max_seq_length)

tokenizer.pad_token = tokenizer.eos_token
pretrained.config.pad_token_id = pretrained.config.eos_token_id

#print(pretrained)

class LivedoorNet(nn.Module):
    def __init__(self, pretrained):
        super().__init__()
        self.pretrained = pretrained
        self.config = self.pretrained.config
    
    def forward(
        self,
        input_ids,
        category=None,
        attention_mask=None,
        output_attentions=None,
        output_hidden_states=None,
        return_dict=None,
        inputs_embeds=None,
        labels=None,
    ):
        outputs = self.pretrained(
            input_ids,
            attention_mask=attention_mask,
            output_attentions=output_attentions,
            output_hidden_states=output_hidden_states,
            return_dict=return_dict,
        )
        
        loss_fct = nn.CrossEntropyLoss()
        loss = loss_fct(outputs.logits, category)
        return ModelOutput(
            loss=loss,
            logits=outputs.logits,
            past_key_values=outputs.past_key_values,
            hidden_states=outputs.hidden_states,
            attentions=outputs.attentions,
        )

model = LivedoorNet(pretrained)

# LoRAの設定

peft_config = LoraConfig(
    r=32,
    lora_alpha=32,
    lora_dropout=0.1,
    bias="none",
    task_type="SEQ_CLS",
    target_modules=[
        "q_proj",
        "k_proj", 
        "v_proj", 
        "o_proj",
        "gate_proj", 
        "up_proj", 
        "down_proj",
        ],
)

# 保存されているモデルを読み込む
import os

#model_path =  "models/lora/" + model_name
#if os.path.isfile(model_path):
#    model = PeftModel.from_pretrained(model, "models/lora/" + model_name)

# finetuningの設定

training_args = TrainingArguments(
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    output_dir="outputs_cls",
    label_names=["category"],
    max_steps=500,
    eval_steps=100,
    logging_steps=100,
    save_steps=100,
    learning_rate=5e-5,
    evaluation_strategy="steps",
    logging_strategy="steps",
    save_strategy="steps",
    load_best_model_at_end=True,
)

# trainerの設定
trainer = SFTTrainer(
    model=model,
    args=training_args,
    tokenizer=tokenizer,
    max_seq_length=max_seq_length,
    train_dataset=dataset["train"],
    eval_dataset=dataset["validation"],
    dataset_text_field="title",
    peft_config=peft_config,
)

trainer.train_dataset = trainer.train_dataset.add_column("category", dataset["train"]["category"])
trainer.eval_dataset = trainer.eval_dataset.add_column("category", dataset["validation"]["category"])

def accuracy(trainer, dataset, batch_size=4):
    trainer.model.eval()
    num_correct_answers = 0
    num_answers = 0
#    for i in tqdm(range(0, len(dataset), batch_size)):
    for i in range(0, len(dataset), batch_size):
        examples = dataset[i:i+batch_size]
        encodings = trainer.tokenizer(
            examples["title"],
            padding=True,
            return_tensors="pt",
            )
        category = torch.tensor(examples["category"])
        with torch.no_grad():
            outputs = trainer.model(**encodings, category=category)
        num_correct_answers += (outputs.logits.argmax(-1) == category).sum()
        num_answers += len(examples["category"])
    trainer.model.train()
    return num_correct_answers / num_answers

print(accuracy(trainer, dataset["validation"]))

trainer.train()

print(accuracy(trainer, dataset["validation"]))

#trainer.model.save_pretrained("models/lora/" + model_name)