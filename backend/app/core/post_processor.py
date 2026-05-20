"""
Post Processor - Validates and formats LLM responses
"""

import re
from typing import Dict, Any
from dataclasses import dataclass
from app.core.context_builder import Context
from app.models.response_models import IntentClassification
from app.utils.logger import setup_logging

logger = setup_logging()


@dataclass
class ProcessedResponse:
    """Processed response object"""
    answer: str
    validated: bool
    modifications: list


class PostProcessor:
    """Post-process and validate LLM responses"""
    
    def __init__(self):
        # Sanity check patterns
        self.sanity_checks = {
            "no_hallucination": [
                r"as an ai",
                r"i don't have access",
                r"i cannot browse",
                r"i don't know",
            ],
            "remove_patterns": [
                r"^(answer:|response:)\s*",
                r"\[citation needed\]",
                r"\(source:.*?\)",
            ],
            "quality_checks": {
                "min_length": 50,
                "max_length": 2000,
            }
        }
    
    async def process(
        self,
        response_text: str,
        context: Context,
        intent: IntentClassification
    ) -> ProcessedResponse:
        """
        Post-process LLM response
        
        Args:
            response_text: Raw LLM response
            context: Context used for generation
            intent: Query intent
            
        Returns:
            ProcessedResponse with validated and formatted answer
        """
        modifications = []
        
        # 1. Clean response
        cleaned = self._clean_response(response_text)
        if cleaned != response_text:
            modifications.append("cleaned_formatting")
        
        # 2. Remove hallucination patterns
        dehallucinated = self._remove_hallucinations(cleaned)
        if dehallucinated != cleaned:
            modifications.append("removed_hallucinations")
        
        # 3. Validate content
        is_valid, validation_message = self._validate_content(
            dehallucinated,
            context,
            intent
        )
        
        if not is_valid:
            modifications.append(f"validation_warning:{validation_message}")
        
        # 4. Format response
        formatted = self._format_response(dehallucinated, intent)
        if formatted != dehallucinated:
            modifications.append("formatted_structure")
        
        # 5. Add disclaimer if needed
        final_response = self._add_disclaimer(formatted, intent)
        if final_response != formatted:
            modifications.append("added_disclaimer")
        
        logger.info(f"Post-processed response: {len(modifications)} modifications")
        
        return ProcessedResponse(
            answer=final_response,
            validated=is_valid,
            modifications=modifications
        )
    
    def _clean_response(self, text: str) -> str:
        """Clean formatting and artifacts"""
        # Remove leading/trailing whitespace
        text = text.strip()
        
        # Remove common prefixes
        for pattern in self.sanity_checks["remove_patterns"]:
            text = re.sub(pattern, "", text, flags=re.IGNORECASE)
        
        # Fix multiple newlines
        text = re.sub(r'\n{3,}', '\n\n', text)
        
        # Fix multiple spaces
        text = re.sub(r' {2,}', ' ', text)
        
        return text.strip()
    
    def _remove_hallucinations(self, text: str) -> str:
        """Remove common hallucination patterns"""
        text_lower = text.lower()
        
        for pattern in self.sanity_checks["no_hallucination"]:
            if re.search(pattern, text_lower):
                logger.warning(f"Detected hallucination pattern: {pattern}")
                # Remove the sentence containing the pattern
                sentences = text.split('.')
                filtered = [s for s in sentences if not re.search(pattern, s.lower())]
                text = '. '.join(filtered)
        
        return text
    
    def _validate_content(
        self,
        text: str,
        context: Context,
        intent: IntentClassification
    ) -> tuple[bool, str]:
        """Validate response content"""
        # Check length
        min_len = self.sanity_checks["quality_checks"]["min_length"]
        max_len = self.sanity_checks["quality_checks"]["max_length"]
        
        if len(text) < min_len:
            return False, f"Response too short ({len(text)} chars, min {min_len})"
        
        if len(text) > max_len:
            logger.warning(f"Response too long ({len(text)} chars), truncating")
            return True, "Response truncated"
        
        # Check if response is relevant to query
        if context.metadata.get("query"):
            query_lower = context.metadata["query"].lower()
            text_lower = text.lower()
            
            # Extract key terms from query
            key_terms = [w for w in query_lower.split() if len(w) > 3]
            
            # Check if at least some key terms appear in response
            matching_terms = sum(1 for term in key_terms if term in text_lower)
            relevance_ratio = matching_terms / len(key_terms) if key_terms else 0
            
            if relevance_ratio < 0.2:
                return False, "Response may not be relevant to query"
        
        return True, "Valid"
    
    def _format_response(self, text: str, intent: IntentClassification) -> str:
        """Format response based on intent"""
        # Intent-specific formatting
        if intent.primary_intent == "crop_cultivation":
            # Ensure structured format for cultivation advice
            if not any(marker in text.lower() for marker in ["step", "requirement", "method"]):
                # Add structure hint
                pass  # Text is already good
        
        # Ensure proper paragraph breaks
        paragraphs = text.split('\n\n')
        paragraphs = [p.strip() for p in paragraphs if p.strip()]
        
        # Limit to reasonable number of paragraphs
        if len(paragraphs) > 6:
            paragraphs = paragraphs[:6]
            paragraphs.append("For more detailed information, please consult with local agricultural experts.")
        
        return '\n\n'.join(paragraphs)
    
    def _add_disclaimer(self, text: str, intent: IntentClassification) -> str:
        """Add appropriate disclaimers"""
        disclaimers = {
            "pest_management": "\n\nNote: Always follow safety guidelines when using pesticides. Consult with agricultural extension officers for proper dosage and application methods.",
            "market_prices": "\n\nNote: Market prices vary by location and time. Please verify current rates at your local mandi.",
            "government_schemes": "\n\nNote: Eligibility criteria and benefits may vary. Please visit official websites or contact local authorities for the most current information.",
        }
        
        disclaimer = disclaimers.get(intent.primary_intent)
        
        if disclaimer and disclaimer not in text:
            return text + disclaimer
        
        return text