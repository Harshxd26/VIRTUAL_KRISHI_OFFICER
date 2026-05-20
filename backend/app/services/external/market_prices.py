"""
Market Prices Service - Agmarknet CSV integration
"""

import aiohttp
from typing import Optional, List, Dict
from datetime import datetime, timedelta
import asyncio
import pandas as pd

from app.utils.logger import setup_logging

logger = setup_logging()


class MarketPriceService:
    """Fetch market prices from Agmarknet CSV or sample data"""
    
    def __init__(self, csv_path: Optional[str] = None):
        self.csv_path = csv_path  # Path to your downloaded CSV
        self.session: Optional[aiohttp.ClientSession] = None
        self.timeout = aiohttp.ClientTimeout(total=15)
        
        # Sample price data (fallback)
        self.sample_prices = {
            "wheat": {"price": 2050, "unit": "quintal", "market": "Delhi"},
            "rice": {"price": 2800, "unit": "quintal", "market": "Delhi"},
            "potato": {"price": 800, "unit": "quintal", "market": "Delhi"},
            "tomato": {"price": 1500, "unit": "quintal", "market": "Delhi"},
            "onion": {"price": 1200, "unit": "quintal", "market": "Delhi"},
            "cotton": {"price": 6000, "unit": "quintal", "market": "Maharashtra"},
            "sugarcane": {"price": 300, "unit": "quintal", "market": "UP"},
        }

    async def _get_session(self) -> aiohttp.ClientSession:
        """Get or create HTTP session"""
        if self.session is None or self.session.closed:
            self.session = aiohttp.ClientSession(timeout=self.timeout)
        return self.session

    async def close(self):
        """Close HTTP session"""
        if self.session and not self.session.closed:
            await self.session.close()

    async def _get_csv_prices(
        self,
        commodity: Optional[str] = None,
        state: Optional[str] = None,
        market: Optional[str] = None
    ) -> List[Dict]:
        """Fetch prices from local CSV"""
        if not self.csv_path:
            return []

        try:
            df = pd.read_csv(self.csv_path)
            if commodity:
                df = df[df['commodity'].str.lower() == commodity.lower()]
            if state:
                df = df[df['state'].str.lower() == state.lower()]
            if market:
                df = df[df['market'].str.lower() == market.lower()]

            return df.to_dict(orient='records')

        except Exception as e:
            logger.error(f"Error reading CSV: {e}")
            return []

    async def _get_sample_prices(
        self,
        commodity: Optional[str] = None,
        state: Optional[str] = None
    ) -> List[Dict]:
        """Return fallback sample price data"""
        today = datetime.now().strftime("%Y-%m-%d")
        if commodity:
            data = self.sample_prices.get(commodity.lower(), {"price": 1500, "unit": "quintal", "market": "Local Market"})
            return [{
                "commodity": commodity,
                "price": data["price"],
                "unit": data["unit"],
                "market": data["market"],
                "state": state or "Unknown",
                "date": today
            }]
        else:
            return [
                {
                    "commodity": name,
                    "price": data["price"],
                    "unit": data["unit"],
                    "market": data["market"],
                    "state": state or "Delhi",
                    "date": today
                }
                for name, data in self.sample_prices.items()
            ]

    async def get_prices(
        self,
        commodity: Optional[str] = None,
        state: Optional[str] = None,
        market: Optional[str] = None
    ) -> List[Dict]:
        """Get market prices for commodity/state/market"""
        # Try CSV first
        csv_prices = await self._get_csv_prices(commodity, state, market)
        if csv_prices:
            logger.info(f"✅ Prices fetched from CSV for {commodity or 'all'}")
            return csv_prices

        # Fallback to sample data
        logger.warning(f"⚠ CSV not found or no data. Using sample prices for {commodity or 'all'}")
        return await self._get_sample_prices(commodity, state)

    async def get_price_trends(
        self,
        commodity: str,
        days: int = 7
    ) -> Dict:
        """Get price trends over last 'days' (sample/fallback)"""
        prices_list = await self.get_prices(commodity)
        base_price = prices_list[0]["price"] if prices_list else 1500

        dates = []
        prices = []
        for i in range(days):
            date = (datetime.now() - timedelta(days=days-i-1)).strftime("%Y-%m-%d")
            variation = base_price * (0.9 + (i % 3) * 0.05)
            dates.append(date)
            prices.append(round(variation, 2))

        return {
            "commodity": commodity,
            "period_days": days,
            "dates": dates,
            "prices": prices,
            "trend": "stable",
            "avg_price": sum(prices) / len(prices)
        }


# Global instance
# Use repo-relative CSV so it works across environments
market_service = MarketPriceService(csv_path="./app/data/market_prices.csv")