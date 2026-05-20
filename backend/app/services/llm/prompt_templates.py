class PromptTemplates:
    """
    Central place to store all prompt templates used by the LLM.
    """

    SYSTEM_PROMPT = """
You are KrishiMitra, an agricultural assistant AI. Your job is to:
- Understand farmer queries
- Use weather, soil, and crop data if available
- Provide precise, actionable guidance
- Use simple language
- Avoid over-confident or harmful advice
"""

    QUERY_CLASSIFICATION_PROMPT = """
Classify this user query into one of the following categories:
- WEATHER
- SOIL
- CROP
- MARKET
- PEST
- GENERAL

Query: "{query}"

Return only the category name.
"""

    ANSWER_GENERATION_PROMPT = """
You are KrishiMitra — an AI agriculture expert.

User Query:
{query}

Retrieved Knowledge:
{context}

Generate a helpful, accurate, actionable answer.
Use simple language in bullet points if possible.
"""

    FALLBACK_PROMPT = """
The system could not retrieve enough data to answer fully.

User query:
{query}

Give a general guidance answer, but include a disclaimer.
"""

    @classmethod
    def get_system_prompt(cls):
        return cls.SYSTEM_PROMPT

    @classmethod
    def get_query_classification_prompt(cls, query: str):
        return cls.QUERY_CLASSIFICATION_PROMPT.format(query=query)

    @classmethod
    def get_answer_generation_prompt(cls, query: str, context: str):
        return cls.ANSWER_GENERATION_PROMPT.format(query=query, context=context)

    @classmethod
    def get_fallback_prompt(cls, query: str):
        return cls.FALLBACK_PROMPT.format(query=query)
