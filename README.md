# rocketchat-confluence-tina

A  Rocketchat bot that searches confluence for relevant articles, and improves the result with a QA algorithm, with the Tina API.

This uses a classical QA architecture design, by first retreiving a list of relevant documents from atlassian confluence search, then applying QA algorithms (using transformers) on each article, through a machine learning pipeline defined in TINA (My AI platform for CTG)
