# Supernotes: Driving Consensus in Crowd-Sourced Fact-Checking
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14848537.svg)](https://doi.org/10.5281/zenodo.14848537) 

[Soham De](https://www.sohamde.in), [Michiel Bakker](https://www.miba.dev/), [Jay Baxter](http://jaybaxter.net/), [Martin Saveski](https://faculty.washington.edu/msaveski/)

This repository contains code for replicating the analysis and experiments in the paper "Supernotes: Driving Consensus in Crowd-Sourced Fact-Checking" published in the proceedings of The ACM Web Conference 2025.

Open-sourced Community Notes data required for generating supernotes can be downloaded from [their website](https://communitynotes.x.com/guide/en/under-the-hood/download-data). The anonymized data from human experiments needed for replication will be available upon request.

## Code setup instructions
The code is split into two directories:
1. `supernotes`: contains our implementation of the supernotes generation framework (Sec 3)
2. `analyses`: contains code for analyzing and visualizing results of the human experiments (Sec 4)

Before running any of the scripts, please follow these steps to set up the directory:
1. Install the Python packages in `requirements.txt` 
2. Clone the [communitynotes repo](https://github.com/twitter/communitynotes.git) at the root directory (last verified with commit [#e8d6631](https://github.com/twitter/communitynotes/tree/e8d6631))
3. Download the latest data from community notes into the `communitynotes/data` directory
4. Move the `run_mf.py` script to `communitynotes/`

```
git clone <PATH TO THIS REPO>
cd supernotes-public
pip install -r requirements.txt
git clone https://github.com/twitter/communitynotes.git
mkdir -p communitynotes/data # download ratings data in this directory
mv run_mf.py communitynotes/
```

The supernotes framework is implemented in Python. All analyses and plottings are primarily done in R except for Figure 6 (which involves a scoring process in Python).

### Supernotes Implementation (Sec 3)
To generate a supernote, follow these steps. 
- _Configure secrets_: Generate an OpenAI key and update the value of OPENAI_API_KEY in `supernotes/secrets.json` 
- _Download CN Data_: Download Community Notes data from [their website](https://communitynotes.x.com/guide/en/under-the-hood/download-data) into the directory: `communitynotes/data`
- _Run example_: Run `supernotes/main.py` to generate a supernote as an example

#### Code file descriptions:
- _Summarization_: `supernotes/summarizer.py`  makes a call via OpenAI API to generate candidate supernotes
- _Text Embeddings_: `supernotes/embedder.py` makes a call via OpenAI API to get text embeddings for posts and notes
- _Principle Alignment_: `supernotes/evaluator.py` performs link/length checks and makes a call via OpenAI API to implement principle-alignment steps as described in Section 3
- _Aggregation_: `supernotes/aggregator.py` implements the Community Notes aggregation step described in Appendix B.1
- _Personalized Helpfulness Model_: `supernotes/phm.py` implements the Personalised Helpfulness Model described in Section 3 (and Appendix A)

### Analysis Replication (Sec 4)
To replicate the plots (and associated analyses) run the following scripts:
1. `analysis/plot_helpfulness.R`: requires access to survey data in `analysis/data` and plots both sub-figures in Figure 4, saves output file (`results_helpfulness.eps`) in `generated_plots`
2. `analysis/plot_winrates.R`: requires access to survey data in `analysis/data` and plots Figure 5, saves output file (`results_winrates.eps`) in `generated_plots`
3. `analysis/plot_cnscores.R`: requires access to `survey_notes_with_scores.csv` in `analysis/data` (run `communitynotes/run_mf.py` to generate this file) and plots Figure 6, saves output file (`results_cnscores.eps`) in `generated_plots`. 
4. `analysis/plot_tags.R`: requires access to survey data in `analysis/data` and plots Figure 7, saves output file (`results_tags.eps`) in `generated_plots`
5. `analysis/plot_ablation.R`: requires access to ablation data in `analysis/data` and plots Figure 8, saves output file (`results_winrates.eps`) in `generated_plots`
6. `analysis/analysis.R`: requires access to survey and ablation data in `analysis/data` and runs all statistical tests reported in Section 4.



## Citation
```
@inproceedings{de2025supernotes,
    title     = {Supernotes: Driving Consensus in Crowd-Sourced Fact-Checking},
    author    = {De, Soham and Baxter, Jay and Bakker, Michiel and Saveski, Martin},
    booktitle = {Proceedings of the {ACM} Web Conference 2025 ({WWW} '25)},
    year      = {2025},
    month     = {April 28--May 2},
    location  = {Sydney, NSW, Australia},
    publisher = {ACM},
    address   = {New York, NY, USA},
    pages     = {11},
    doi       = {10.1145/3696410.3714934}
}
```

## License

This code is licensed under the CC BY 4.0 license found in the LICENSE file.