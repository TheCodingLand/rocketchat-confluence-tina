When  a question arrives in the bot:

- We query confluence search for most relevant docuements.
- Then, we use the question answering algorithm to perform selection of both the articles relevance and paragraph highlighting.

The pipeline for tina is very simple, as (we use distilbert models directly from huggingface in this case.)
We then return valid html for the bot, through a serverless function in Tina Functions system.

We expose it using the build in api cration system in Tina.

