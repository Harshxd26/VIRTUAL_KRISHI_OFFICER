"""
LLM Client - Integration with Ollama and Groq
Generates contextual responses using retrieved information
"""

import aiohttp
import asyncio
from typing import Optional, Dict
import json

from app.config import settings
from app.services.llm.prompt_templates import PromptTemplates
from app.utils.logger import setup_logging

logger = setup_logging()


class OllamaClient:
    """Client for Ollama LLM"""
    
    def __init__(self):
        self.base_url = settings.OLLAMA_HOST
        self.model = settings.OLLAMA_MODEL
        self.temperature = settings.LLM_TEMPERATURE
        self.max_tokens = settings.LLM_MAX_TOKENS
        self.timeout = aiohttp.ClientTimeout(total=settings.LLM_TIMEOUT)
        self.session: Optional[aiohttp.ClientSession] = None
    
    async def _get_session(self) -> aiohttp.ClientSession:
        """Get or create HTTP session"""
        if self.session is None or self.session.closed:
            self.session = aiohttp.ClientSession(timeout=self.timeout)
        return self.session
    
    async def close(self):
        """Close HTTP session"""
        if self.session and not self.session.closed:
            await self.session.close()
    
    async def generate(
        self,
        query: str,
        context: str,
        intent: str,
        language: str = "en"
    ) -> str:
        """
        Generate response using LLM
        
        Args:
            query: User's question
            context: Retrieved context from RAG
            intent: Detected query intent
            language: Response language
        
        Returns:
            Generated answer
        """
        try:
            # Build prompt
            prompt = PromptTemplates.build_prompt(
                query=query,
                context=context,
                intent=intent,
                language=language
            )
            
            # Use Groq if enabled
            if settings.USE_GROQ and settings.GROQ_API_KEY:
                response = await self._generate_groq(prompt)
            else:
                response = await self._generate_ollama(prompt)
            
            return response
            
        except Exception as e:
            logger.error(f"LLM generation failed: {e}")
            return self._get_fallback_response(query, context)
    
    async def _generate_ollama(self, prompt: str) -> str:
        """Generate using Ollama"""
        try:
            session = await self._get_session()
            
            payload = {
                "model": self.model,
                "prompt": prompt,
                "stream": False,
                "options": {
                    "temperature": self.temperature,
                    "num_predict": self.max_tokens,
                }
            }
            
            async with session.post(
                f"{self.base_url}/api/generate",
                json=payload
            ) as response:
                if response.status != 200:
                    error_text = await response.text()
                    logger.error(f"Ollama API error: {response.status} - {error_text}")
                    raise Exception(f"Ollama API returned {response.status}")
                
                data = await response.json()
                answer = data.get("response", "").strip()
                
                logger.info(f"✅ Generated response via Ollama ({len(answer)} chars)")
                return answer
                
        except asyncio.TimeoutError:
            logger.error("Ollama request timeout")
            raise
        except Exception as e:
            logger.error(f"Ollama generation failed: {e}")
            raise
    
    async def _generate_groq(self, prompt: str) -> str:
        """Generate using Groq API (alternative free option)"""
        try:
            session = await self._get_session()
            
            payload = {
                "model": settings.GROQ_MODEL,
                "messages": [
                    {
                        "role": "system",
                        "content": "You are an expert agricultural advisor. Provide accurate, helpful, and practical advice to farmers."
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                "temperature": self.temperature,
                "max_tokens": self.max_tokens
            }
            
            headers = {
                "Authorization": f"Bearer {settings.GROQ_API_KEY}",
                "Content-Type": "application/json"
            }
            
            async with session.post(
                "https://api.groq.com/openai/v1/chat/completions",
                json=payload,
                headers=headers
            ) as response:
                if response.status != 200:
                    error_text = await response.text()
                    logger.error(f"Groq API error: {response.status} - {error_text}")
                    raise Exception(f"Groq API returned {response.status}")
                
                data = await response.json()
                answer = data["choices"][0]["message"]["content"].strip()
                
                logger.info(f"✅ Generated response via Groq ({len(answer)} chars)")
                return answer
                
        except Exception as e:
            logger.error(f"Groq generation failed: {e}")
            raise
    
    def _get_fallback_response(self, query: str, context: str) -> str:
        """Generate fallback response when LLM fails"""
        # Try to extract crop name from query
        crop_keywords = [
            "wheat", "rice", "paddy", "maize", "corn", "bajra", "jowar",
            "barley", "ragi", "potato", "tomato", "onion", "garlic",
            "cotton", "sugarcane", "soybean", "groundnut", "chickpea",
            "pigeon pea", "lentil", "mung bean", "mustard", "sunflower"
        ]
        
        detected_crop = None
        query_lower = query.lower()
        for crop in crop_keywords:
            if crop in query_lower:
                detected_crop = crop
                break
        
        # Provide helpful fallback based on context
        if context and len(context.strip()) > 50:
            # We have some context, use it
            return f"""Based on the available information:

{context[:800]}

Note: This response was generated from available data sources. For more specific and detailed guidance tailored to your exact situation, please:
1. Consult with your local agricultural extension officer
2. Contact agricultural helplines (Kisan Call Centre: 1800-180-1551)
3. Visit your nearest Krishi Vigyan Kendra (KVK)

For immediate assistance, you can also reach out to experienced farmers in your area.
"""
        
        # No context available
        if detected_crop:
            return f"""I understand you're asking about {detected_crop}. 

While I'm currently experiencing some technical limitations in generating a detailed response, here are some general recommendations:

1. **Consult Local Experts**: Visit your nearest Krishi Vigyan Kendra (KVK) or agricultural extension office for region-specific advice.

2. **Check Government Resources**: Visit agricultural department websites for crop-specific guidelines and best practices.

3. **Connect with Other Farmers**: Local farmer groups and cooperatives often have valuable practical knowledge.

4. **Use Agricultural Helplines**: Call Kisan Call Centre at 1800-180-1551 for immediate assistance.

I apologize for the inconvenience. The system is working to improve its response capabilities. Please try again later or use the escalation option to connect with a human expert.
"""
        
        return """I understand you have an agricultural question.

While I'm currently experiencing some technical limitations, here are ways to get help:

1. **Local Agricultural Extension Office**: Visit your nearest KVK or agricultural department office
2. **Kisan Call Centre**: Call 1800-180-1551 for immediate assistance
3. **Government Websites**: Check agricultural department websites for official guidelines
4. **Farmer Communities**: Connect with local farmer groups for practical advice

I apologize for the inconvenience. Please try again later or use the escalation option to connect with a human expert.
"""
    
    async def check_health(self) -> bool:
        """Check if LLM service is available"""
        try:
            if settings.USE_GROQ:
                return True  # Assume Groq is available if API key is set
            
            session = await self._get_session()
            async with session.get(f"{self.base_url}/api/tags") as response:
                return response.status == 200
                
        except Exception as e:
            logger.error(f"LLM health check failed: {e}")
            return False


class PromptTemplates:
    """Prompt templates for different intents"""
    
    @staticmethod
    def build_prompt(
        query: str,
        context: str,
        intent: str,
        language: str = "en"
    ) -> str:
        """Build appropriate prompt based on intent"""
        
        base_instruction = f"""You are an expert agricultural advisor helping farmers with their questions.

User Question: {query}

Relevant Information:
{context}

Instructions:
1. Answer the user's question accurately based on the provided information
2. Be practical and actionable in your advice
3. If the information is incomplete, acknowledge it and provide general guidance
4. Include specific numbers, timings, or measurements when available
5. Format your response in clear paragraphs
"""
        
        # Language mapping for better LLM understanding
        language_map = {
            "hi": "Hindi (हिन्दी)",
            "en": "English",
            "mr": "Marathi (मराठी)",
            "gu": "Gujarati (ગુજરાતી)",
            "te": "Telugu (తెలుగు)",
            "ta": "Tamil (தமிழ்)",
            "kn": "Kannada (ಕನ್ನಡ)",
            "ml": "Malayalam (മലയാളം)",
            "pa": "Punjabi (ਪੰਜਾਬੀ)",
            "bn": "Bengali (বাংলা)",
            "ur": "Urdu (اردو)"
        }
        
        if language != "en":
            lang_name = language_map.get(language, language)
            base_instruction += f"\n6. IMPORTANT: Respond entirely in {lang_name} language. All text, explanations, and advice must be in {lang_name}.\n"
        
        # Intent-specific instructions
        intent_instructions = {
            "crop_cultivation": """
7. Include information about: timing, soil requirements, climate, irrigation, and fertilizers
8. Mention common varieties if applicable
9. Provide step-by-step guidance when relevant
""",
            "pest_management": """
7. Clearly identify the pest or disease
8. Describe symptoms for verification
9. Suggest integrated pest management approach (cultural, biological, chemical)
10. Mention safety precautions for chemical control
""",
            "weather_query": """
7. Provide weather forecast data clearly
8. Relate weather to agricultural activities
9. Include specific recommendations based on upcoming weather
""",
            "market_prices": """
7. Present price information clearly with units
8. Mention location and date of prices
9. Suggest best practices for getting good prices
""",
            "government_schemes": """
7. Explain eligibility criteria clearly
8. Describe the benefits in detail
9. Provide application process steps
10. Include contact information or links if available
"""
        }
        
        prompt = base_instruction
        if intent in intent_instructions:
            prompt += intent_instructions[intent]
        
        prompt += "\n\nYour response:"
        
        return prompt


# Global instance
llm_client = OllamaClient()