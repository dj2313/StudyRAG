from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    GROQ_API_KEY: str = ""
    CHROMA_DB_PATH: str = "./chroma_db"
    SQLITE_PATH: str = "sqlite:///./studyrag.db"
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    MAX_CHUNK_SIZE: int = 800
    TOP_K_RETRIEVAL: int = 4

    class Config:
        env_file = ".env"

settings = Settings()
