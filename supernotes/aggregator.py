import numpy as np
import pandas as pd


def aggregate(ratings, userIntercept, userFactor, globalIntercept = 0.177):

    # m1 = m2 x m3
    m1 = ratings - userIntercept - globalIntercept
    m2 = np.hstack((userFactor, np.ones((len(userFactor),1))))
    m3 = np.linalg.lstsq(m2, m1, rcond=None)[0]
    return m3

def sample_users(num):
    df = pd.read_csv('..communitynotes/data/helpfulness_scores.tsv', sep='\t',low_memory=False)
    df = df.drop_duplicates(subset=['raterParticipantId']).dropna()
    df = df[['coreRaterFactor1','coreRaterIntercept']]
    sample = df.sample(n = num).values.tolist()
    return(sample)

def testAggregator():
    ratings = np.array([1.0 for i in range(100)])
    ratings = np.transpose(np.expand_dims(ratings, axis=0))

    users = sample_users(100) 
    users_mat = np.array(users)

    user_factors = np.transpose(np.expand_dims(users_mat[:,0], axis=0))
    user_intercepts = np.transpose(np.expand_dims(users_mat[:,1], axis=0))

    B = np.matrix([[3.4,1],[5.2,1],[6.1,1]])
    new_v = np.hstack((user_factors, np.ones((len(user_factors),1))))

    out = aggregate(ratings,user_intercepts,user_factors)
    print(out)

if __name__ == "__main__":
    testAggregator()