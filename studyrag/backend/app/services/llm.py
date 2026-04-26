from groq import Groq
from ..config import settings

client = Groq(api_key=settings.GROQ_API_KEY)

def call_groq(model: str, messages: list, max_tokens: int = 500) -> str:
    """Wrapper for all Groq API text completions."""
    try:
        res = client.chat.completions.create(
            model=model,
            messages=messages,
            max_tokens=max_tokens
        )
        return res.choices[0].message.content
    except Exception as e:
        return f"Error: {str(e)}"
