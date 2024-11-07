import pandas as pd
import numpy as np
import torch
import torch.nn.functional as F
import torchmetrics
import lightning.pytorch as pl
from sklearn.metrics import accuracy_score, f1_score, roc_auc_score, precision_score, recall_score


class TinyModel(pl.LightningModule):

    def __init__(self):
        super(TinyModel, self).__init__()

        self.linear1 = torch.nn.Linear(1026, 2048)
        self.linear2 = torch.nn.Linear(2048, 1024)
        self.linear3 = torch.nn.Linear(1024, 512)
        self.linear4 = torch.nn.Linear(512, 256)
        self.linear5 = torch.nn.Linear(256, 128)
        self.linear6 = torch.nn.Linear(128, 64)
        self.linear7 = torch.nn.Linear(64, 32)
        self.linear8 = torch.nn.Linear(32, 16)
        self.linear9 = torch.nn.Linear(16, 3)
        self.activation = torch.nn.ReLU()
        self.dropout1 = torch.nn.Dropout(0.25)
        self.dropout2 = torch.nn.Dropout(0.65)

        self.loss_fn = torch.nn.CrossEntropyLoss()

        self.accuracy = torchmetrics.Accuracy(task="multiclass", num_classes=3)
        self.f1_score = torchmetrics.F1Score(task="multiclass", num_classes=3)
        self.auroc = torchmetrics.AUROC(task="multiclass", num_classes=3)
        self.precision = torchmetrics.AveragePrecision(task="multiclass", num_classes=3, average='weighted')
        self.recall = torchmetrics.Recall(task="multiclass", average='weighted', num_classes=3)

    def forward(self, x):
        x = self.linear1(x)
        x = self.activation(x)
        x = self.dropout2(x)
        x = self.linear2(x)
        x = self.activation(x)
        x = self.linear3(x)
        x = self.activation(x)
        x = self.dropout2(x)
        x = self.linear4(x)
        x = self.activation(x)
        x = self.linear5(x)
        x = self.activation(x)
        x = self.dropout1(x)
        x = self.linear6(x)
        x = self.activation(x)
        x = self.linear7(x)
        x = self.activation(x)
        x = self.dropout1(x)
        x = self.linear8(x)
        x = self.activation(x)
        x = self.linear9(x)
        return x

    
def predict_rating(test_vals):
    model = TinyModel.load_from_checkpoint("phm_weights.ckpt", map_location=torch.device('cpu'))
    model.eval()
    preds = []

    for i in range(len(test_vals)):
        with torch.no_grad():
            y_hat = model(torch.FloatTensor(test_vals[i]))
            preds.append(np.argmax(y_hat.numpy())/2.0)
    return(preds)

def predict_rating_sample(test_vals):
    model = TinyModel()
    model = TinyModel.load_from_checkpoint("phm_weights.ckpt", map_location=torch.device('cpu'))
    model.eval()
    preds = []

    for i in range(len(test_vals)):
        with torch.no_grad():
            y_hat = model(torch.FloatTensor(test_vals[i]))
            probabilities = torch.softmax(y_hat, dim=0).numpy()
            label = np.random.choice(len(probabilities), p=probabilities)
            preds.append(label/2.0)
    return(preds)

def predict_rating_sample_argmax(test_vals):
    model = TinyModel()
    model = TinyModel.load_from_checkpoint("phm_weights.ckpt", map_location=torch.device('cpu'))
    model.eval()
    preds = []

    for i in range(len(test_vals)):
        with torch.no_grad():
            y_hat = model(torch.FloatTensor(test_vals[i]))
            probabilities = torch.softmax(y_hat, dim=0).numpy()
            label = np.argmax(probabilities)
            preds.append(label/2.0)
    return(preds)

def predict_rating_probs(test_vals):
    model = TinyModel()
    model = TinyModel.load_from_checkpoint("phm_weights.ckpt", map_location=torch.device('cpu'))
    model.eval()
    preds = []

    for i in range(len(test_vals)):
        with torch.no_grad():
            y_hat = model(torch.FloatTensor(test_vals[i]))
            probabilities = torch.softmax(y_hat, dim=0).numpy()
            label = np.random.choice(len(probabilities), p=probabilities)
            preds.append(label/2.0)
    return(probabilities)

def get_embedding(row,t_embeds,n_embeds):
    user_embedding = row['embedding']
    noteId = row['noteId']
    tweetId = row['tweetId']
    note_embedding = n_embeds[n_embeds['noteId'] == noteId]['embedding'].values[0]
    tweet_embedding = t_embeds[t_embeds['tweetId'] == tweetId]['embedding'].values[0]
    text_embedding = torch.tensor(user_embedding + note_embedding + tweet_embedding)
    return text_embedding

def testPHM():
    model = TinyModel()
    model = TinyModel.load_from_checkpoint("phm_weights.ckpt", map_location=torch.device('cpu'))
    model.eval()

    df = pd.read_pickle('ml_data/new_data/test.pkl')
    t_embeds = pd.read_pickle('ml_data/new_data/all_tweet_embeddings.pkl')
    n_embeds = pd.read_pickle('ml_data/new_data/all_note_embeddings.pkl')
    print(len(n_embeds))
    print(len(t_embeds))
    print(len(df))
    print(df.head())

    y_true = []
    y_pred = []
    y_probs = []

    for index, row in df.iterrows():
        input = get_embedding(row,t_embeds,n_embeds)
        with torch.no_grad():
            y_hat = model(torch.FloatTensor(input))
            probs = F.softmax(y_hat, dim=0).numpy()
            y_probs.append(probs)
            pred = torch.argmax(y_hat).item()  
            y_pred.append(pred)
            y_true.append(row['rating'])  

    y_true = np.array(y_true)
    y_pred = np.array(y_pred)
    y_probs = np.vstack(y_probs)

    # Calculate metrics
    acc = accuracy_score(y_true, y_pred)
    f1 = f1_score(y_true, y_pred, average='weighted')  
    auc = roc_auc_score(y_true, y_probs, multi_class='ovr')  
    precision = precision_score(y_true, y_pred, average='weighted')
    recall = recall_score(y_true, y_pred, average='weighted')

    print(f"Accuracy: {acc}")
    print(f"F1 Score: {f1}")
    print(f"AUC: {auc}")
    print(f"Precision: {precision}")
    print(f"Recall: {recall}")



    
if __name__ == "__main__":
    testPHM()