when  a question arrives in the bot

We query confluence search for most relevant docuements.
Then, within the list we select 3 of them and use the question answering algorithm to perform selection.

The pipeline for tina is very simple, as we use distilbert models directly from huggingface in this case.
We then return valid html for the bot, through a serverless function in Tina Functions system.
