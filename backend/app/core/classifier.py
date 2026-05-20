"""
Query Intent Classifier
Classifies user queries into agricultural intents
"""

import re
from typing import Dict, List
from app.models.response_models import IntentClassification
from app.utils.logger import setup_logging

logger = setup_logging()


class QueryClassifier:
    """Classify agricultural queries by intent"""
    
    def __init__(self):
        # Define intent patterns and keywords
        self.intent_patterns = {
            "crop_cultivation": {
                "keywords": [
                    "plant", "grow", "cultivation", "sowing", "sow", "harvest",
                    "crop", "seed", "germination", "transplant", "yield",
                    "spacing", "depth", "season", "variety", "farming"
                ],
                "patterns": [
                    r"how to (grow|plant|cultivate)",
                    r"best time (to|for) (plant|sow|grow)",
                    r"when (to|should) (plant|sow|grow)",
                    r"(growing|planting|cultivation) (guide|method|technique)",
                ]
            },
            "pest_management": {
                "keywords": [
                    "pest", "disease", "insect", "fungus", "infection", "aphid",
                    "caterpillar", "borer", "rust", "blight", "wilt", "mold",
                    "control", "spray", "pesticide", "fungicide", "treatment"
                ],
                "patterns": [
                    r"(pest|disease|insect) (control|management|treatment)",
                    r"how to (control|manage|treat|prevent)",
                    r"(yellow|brown|white) (spots|leaves|patches)",
                    r"(aphid|caterpillar|borer|rust|blight)",
                ]
            },
            "weather_query": {
                "keywords": [
                    "weather", "rain", "rainfall", "temperature", "climate",
                    "forecast", "monsoon", "drought", "flood", "cold", "hot",
                    "humidity", "wind", "storm"
                ],
                "patterns": [
                    r"(weather|rain) (forecast|prediction|today|tomorrow)",
                    r"will it rain",
                    r"(temperature|climate) (today|tomorrow|this week)",
                    r"when (will|is) (rain|monsoon)",
                ]
            },
            "market_prices": {
                "keywords": [
                    "price", "rate", "market", "mandi", "sell", "selling",
                    "cost", "value", "worth", "rupees", "₹"
                ],
                "patterns": [
                    r"(price|rate|cost) (of|for|today)",
                    r"(market|mandi) (price|rate)",
                    r"how much (is|are|does)",
                    r"where to sell",
                    r"best (price|rate|market)",
                ]
            },
            "government_schemes": {
                "keywords": [
                    "scheme", "subsidy", "loan", "credit", "insurance",
                    "pm-kisan", "pmkisan", "kisan", "government", "yojana",
                    "benefit", "support", "assistance"
                ],
                "patterns": [
                    r"(government|pm) (scheme|yojana|program)",
                    r"(kisan|farmer) (credit|loan|insurance)",
                    r"how to (apply|register|enroll)",
                    r"(subsidy|benefit|assistance) (for|available)",
                ]
            },
            "soil_health": {
                "keywords": [
                    "soil", "fertility", "nutrient", "fertilizer", "manure",
                    "compost", "nitrogen", "phosphorus", "potassium", "npk",
                    "ph", "organic", "testing", "health card"
                ],
                "patterns": [
                    r"soil (test|testing|health|fertility|quality)",
                    r"(fertilizer|nutrient|manure) (recommendation|application)",
                    r"how to improve soil",
                    r"soil health card",
                    r"(nitrogen|phosphorus|potassium|npk) (deficiency|requirement)",
                ]
            }
        }
        
        # Crop names for entity extraction
        self.crop_names = [
            "wheat", "rice", "paddy", "maize", "corn", "bajra", "jowar",
            "barley", "ragi", "potato", "tomato", "onion", "garlic",
            "cotton", "sugarcane", "soybean", "groundnut", "peanut",
            "chickpea", "pigeon pea", "lentil", "mung bean", "black gram",
            "mustard", "sunflower", "safflower", "castor", "sesame"
        ]
    
    async def classify(self, query: str) -> IntentClassification:
        """
        Classify query intent
        
        Args:
            query: User query string
            
        Returns:
            IntentClassification with detected intent and entities
        """
        query_lower = query.lower()
        
        # Calculate scores for each intent
        intent_scores = {}
        
        for intent, config in self.intent_patterns.items():
            score = 0
            
            # Keyword matching
            for keyword in config["keywords"]:
                if keyword in query_lower:
                    score += 1
            
            # Pattern matching
            for pattern in config["patterns"]:
                if re.search(pattern, query_lower):
                    score += 2  # Patterns have higher weight
            
            intent_scores[intent] = score
        
        # Get primary intent (highest score)
        if max(intent_scores.values()) == 0:
            primary_intent = "general"
            confidence = 0.3
        else:
            primary_intent = max(intent_scores, key=intent_scores.get)
            # Normalize confidence (0-1)
            total_score = sum(intent_scores.values())
            confidence = intent_scores[primary_intent] / total_score if total_score > 0 else 0.5
            confidence = min(confidence, 0.95)  # Cap at 0.95
        
        # Extract entities
        entities = self._extract_entities(query_lower)
        
        # Determine data requirements
        requires_crop_data = primary_intent in ["crop_cultivation", "pest_management"] or bool(entities.get("crop"))
        requires_market_data = primary_intent == "market_prices"
        requires_scheme_info = primary_intent == "government_schemes"
        
        logger.info(f"Classified query as '{primary_intent}' (confidence: {confidence:.2f})")
        
        return IntentClassification(
            primary_intent=primary_intent,
            confidence=confidence,
            requires_crop_data=requires_crop_data,
            requires_market_data=requires_market_data,
            requires_scheme_info=requires_scheme_info,
            extracted_entities=entities
        )
    
    def _extract_entities(self, query: str) -> Dict[str, str]:
        """Extract entities like crop names, commodities"""
        entities = {}
        
        # Extract crop names
        for crop in self.crop_names:
            if crop in query:
                entities["crop"] = crop
                entities["commodity"] = crop
                break
        
        # Extract numbers (could be prices, quantities, etc.)
        numbers = re.findall(r'\d+', query)
        if numbers:
            entities["numbers"] = numbers
        
        return entities


# Example usage
if __name__ == "__main__":
    import asyncio
    
    async def test():
        classifier = QueryClassifier()
        
        test_queries = [
            "How to grow wheat in my farm?",
            "What is the current price of tomatoes?",
            "My rice crop has yellow leaves",
            "Will it rain tomorrow?",
            "How to apply for PM-KISAN scheme?",
            "Soil testing near me"
        ]
        
        for query in test_queries:
            result = await classifier.classify(query)
            print(f"\nQuery: {query}")
            print(f"Intent: {result.primary_intent} (confidence: {result.confidence:.2f})")
            print(f"Entities: {result.extracted_entities}")
    
    asyncio.run(test())