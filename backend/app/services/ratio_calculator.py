"""
Ratio Calculator Service
Calculates all financial ratios for a given FinancialPeriod
"""
from decimal import Decimal
from django.core.exceptions import ValidationError
from app.models import FinancialPeriod, TradingAccount, ProfitAndLoss, BalanceSheet, OperationalMetrics
from app.config.ratio_benchmarks import *


class RatioCalculator:
    """Calculates financial ratios for co-operative societies"""
    
    def __init__(self, period: FinancialPeriod):
        """
        Initialize calculator with a FinancialPeriod
        
        Args:
            period: FinancialPeriod instance with all related data
        """
        self.period = period
        self._validate_period_data()
        
    def _validate_period_data(self):
        """Ensure all required financial statements exist"""
        if not hasattr(self.period, 'trading_account'):
            raise ValidationError("TradingAccount not found for this period")
        if not hasattr(self.period, 'profit_loss'):
            raise ValidationError("ProfitAndLoss not found for this period")
        if not hasattr(self.period, 'balance_sheet'):
            raise ValidationError("BalanceSheet not found for this period")
        if not hasattr(self.period, 'operational_metrics'):
            raise ValidationError("OperationalMetrics not found for this period")
    
    def calculate_base_variables(self):
        """Calculate base variables needed for ratio calculations"""
        bs = self.period.balance_sheet
        ta = self.period.trading_account
        
        working_fund = bs.working_fund
        own_funds = bs.own_funds
        average_stock = (ta.opening_stock + ta.closing_stock) / Decimal('2.0')
        cogs = ta.sales - ta.gross_profit
        
        return {
            'working_fund': working_fund,
            'own_funds': own_funds,
            'average_stock': average_stock,
            'cogs': cogs
        }
    
    def calculate_trading_ratios(self):
        """Calculate trading-related ratios"""
        ta = self.period.trading_account
        pl = self.period.profit_loss
        base_vars = self.calculate_base_variables()
        
        ratios = {}
        
        # Stock Turnover = COGS / Average Stock
        if base_vars['average_stock'] > 0:
            ratios['stock_turnover'] = float(base_vars['cogs'] / base_vars['average_stock'])
        else:
            ratios['stock_turnover'] = 0.0
        
        # Gross Profit Ratio = (Gross Profit / Sales) * 100
        if ta.sales > 0:
            ratios['gross_profit_ratio'] = float((ta.gross_profit / ta.sales) * Decimal('100.0'))
        else:
            ratios['gross_profit_ratio'] = 0.0
        
        # Net Profit Ratio = (Net Profit / Sales) * 100
        if ta.sales > 0:
            ratios['net_profit_ratio'] = float((pl.net_profit / ta.sales) * Decimal('100.0'))
        else:
            ratios['net_profit_ratio'] = 0.0
        
        return ratios
    
    def calculate_fund_structure_ratios(self):
        """Calculate fund structure ratios (all as % of Working Fund)"""
        bs = self.period.balance_sheet
        base_vars = self.calculate_base_variables()
        wf = base_vars['working_fund']
        
        ratios = {}
        
        if wf > 0:
            # Own Fund to WF = (Own Fund / WF) * 100
            ratios['own_fund_to_wf'] = float((base_vars['own_funds'] / wf) * Decimal('100.0'))
            
            # Deposits to WF = (Deposits / WF) * 100
            ratios['deposits_to_wf'] = float((bs.deposits / wf) * Decimal('100.0'))
            
            # Borrowings to WF = (Borrowings / WF) * 100
            ratios['borrowings_to_wf'] = float((bs.borrowings / wf) * Decimal('100.0'))
            
            # Loans to WF = (Loans / WF) * 100
            ratios['loans_to_wf'] = float((bs.loans_advances / wf) * Decimal('100.0'))
            
            # Investments to WF = (Investments / WF) * 100
            ratios['investments_to_wf'] = float((bs.investments / wf) * Decimal('100.0'))
        else:
            ratios['own_fund_to_wf'] = 0.0
            ratios['deposits_to_wf'] = 0.0
            ratios['borrowings_to_wf'] = 0.0
            ratios['loans_to_wf'] = 0.0
            ratios['investments_to_wf'] = 0.0
        
        return ratios
    
    def calculate_yield_cost_ratios(self):
        """Calculate yield and cost ratios"""
        bs = self.period.balance_sheet
        pl = self.period.profit_loss
        base_vars = self.calculate_base_variables()
        wf = base_vars['working_fund']
        
        ratios = {}
        
        # Cost of Deposits = (Interest on Deposits / Deposits) * 100
        if bs.deposits > 0:
            ratios['cost_of_deposits'] = float((pl.interest_on_deposits / bs.deposits) * Decimal('100.0'))
        else:
            ratios['cost_of_deposits'] = 0.0
        
        # Yield on Loans = (Interest on Loans / Loans) * 100
        if bs.loans_advances > 0:
            ratios['yield_on_loans'] = float((pl.interest_on_loans / bs.loans_advances) * Decimal('100.0'))
        else:
            ratios['yield_on_loans'] = 0.0
        
        # Yield on Investments = (Return on Investment / Investments) * 100
        if bs.investments > 0:
            ratios['yield_on_investments'] = float((pl.return_on_investment / bs.investments) * Decimal('100.0'))
        else:
            ratios['yield_on_investments'] = 0.0
        
        # Credit Deposit Ratio = (Loans / Deposits) * 100
        if bs.deposits > 0:
            ratios['credit_deposit_ratio'] = float((bs.loans_advances / bs.deposits) * Decimal('100.0'))
        else:
            ratios['credit_deposit_ratio'] = 0.0
        
        # Avg Cost of WF = (Total Interest Expenses / WF) * 100
        if wf > 0:
            ratios['avg_cost_of_wf'] = float((pl.total_interest_expense / wf) * Decimal('100.0'))
        else:
            ratios['avg_cost_of_wf'] = 0.0
        
        # Avg Yield on WF = (Total Interest Income / WF) * 100
        if wf > 0:
            ratios['avg_yield_on_wf'] = float((pl.total_interest_income / wf) * Decimal('100.0'))
        else:
            ratios['avg_yield_on_wf'] = 0.0
        
        return ratios
    
    def calculate_margin_ratios(self):
        """Calculate margin ratios"""
        bs = self.period.balance_sheet
        pl = self.period.profit_loss
        base_vars = self.calculate_base_variables()
        wf = base_vars['working_fund']
        yield_cost = self.calculate_yield_cost_ratios()
        
        ratios = {}
        
        # Gross Financial Margin = Avg Yield on WF - Avg Cost of WF
        ratios['gross_fin_margin'] = yield_cost['avg_yield_on_wf'] - yield_cost['avg_cost_of_wf']
        
        # Operating Cost to WF = (Establishment / WF) * 100
        if wf > 0:
            ratios['operating_cost_to_wf'] = float((pl.establishment_contingencies / wf) * Decimal('100.0'))
        else:
            ratios['operating_cost_to_wf'] = 0.0
        
        # Net Financial Margin = Gross Fin Margin + (Misc Income / WF * 100) - Op Cost %
        misc_income_pct = float((pl.miscellaneous_income / wf) * Decimal('100.0')) if wf > 0 else 0.0
        ratios['net_fin_margin'] = ratios['gross_fin_margin'] + misc_income_pct - ratios['operating_cost_to_wf']
        
        # Risk Cost to WF = (Provisions / WF) * 100
        if wf > 0:
            ratios['risk_cost_to_wf'] = float((pl.provisions / wf) * Decimal('100.0'))
        else:
            ratios['risk_cost_to_wf'] = 0.0
        
        # Net Margin = Net Financial Margin - Risk Cost %
        ratios['net_margin'] = ratios['net_fin_margin'] - ratios['risk_cost_to_wf']
        
        return ratios
    
    def get_traffic_light_status(self, ratio_name: str, calculated_value: float, ideal_value=None):
        """
        Determine traffic light status for a ratio
        
        Args:
            ratio_name: Name of the ratio
            calculated_value: Calculated ratio value
            ideal_value: Ideal benchmark value (if None, uses defaults from config)
        
        Returns:
            'green', 'yellow', or 'red'
        """
        # Get ideal value from config if not provided
        if ideal_value is None:
            ideal_value = self._get_ideal_value(ratio_name)
        
        if ideal_value is None:
            return 'yellow'  # No benchmark available
        
        # Ratio-specific logic
        if ratio_name == 'net_margin':
            if calculated_value >= IDEAL_NET_MARGIN:
                return 'green'
            elif calculated_value >= IDEAL_NET_MARGIN * 0.5:
                return 'yellow'
            else:
                return 'red'
        
        elif ratio_name == 'risk_cost_to_wf':
            if calculated_value <= IDEAL_RISK_COST_TO_WF_MAX:
                return 'green'
            elif calculated_value <= IDEAL_RISK_COST_TO_WF_MAX * 2:
                return 'yellow'
            else:
                return 'red'
        
        elif ratio_name == 'stock_turnover':
            if calculated_value >= IDEAL_STOCK_TURNOVER:
                return 'green'
            elif calculated_value >= IDEAL_STOCK_TURNOVER * 0.7:
                return 'yellow'
            else:
                return 'red'
        
        elif ratio_name == 'gross_profit_ratio':
            if IDEAL_GROSS_PROFIT_RATIO_MIN <= calculated_value <= IDEAL_GROSS_PROFIT_RATIO_MAX:
                return 'green'
            elif calculated_value >= IDEAL_GROSS_PROFIT_RATIO_MIN * 0.7:
                return 'yellow'
            else:
                return 'red'
        
        elif ratio_name == 'loans_to_wf':
            if IDEAL_LOANS_TO_WF_MIN <= calculated_value <= IDEAL_LOANS_TO_WF_MAX:
                return 'green'
            elif calculated_value >= IDEAL_LOANS_TO_WF_MIN * 0.8:
                return 'yellow'
            else:
                return 'red'
        
        elif ratio_name == 'investments_to_wf':
            if IDEAL_INVESTMENTS_TO_WF_MIN <= calculated_value <= IDEAL_INVESTMENTS_TO_WF_MAX:
                return 'green'
            elif calculated_value >= IDEAL_INVESTMENTS_TO_WF_MIN * 0.7:
                return 'yellow'
            else:
                return 'red'
        
        elif ratio_name == 'credit_deposit_ratio':
            if calculated_value >= IDEAL_CREDIT_DEPOSIT_RATIO_MIN:
                return 'green'
            elif calculated_value >= IDEAL_CREDIT_DEPOSIT_RATIO_MIN * 0.8:
                return 'yellow'
            else:
                return 'red'
        
        elif ratio_name == 'gross_fin_margin':
            if calculated_value >= IDEAL_GROSS_FINANCIAL_MARGIN:
                return 'green'
            elif calculated_value >= IDEAL_GROSS_FINANCIAL_MARGIN * 0.7:
                return 'yellow'
            else:
                return 'red'
        
        elif ratio_name == 'operating_cost_to_wf':
            if IDEAL_OPERATING_COST_TO_WF_MIN <= calculated_value <= IDEAL_OPERATING_COST_TO_WF_MAX:
                return 'green'
            elif calculated_value <= IDEAL_OPERATING_COST_TO_WF_MAX * 1.2:
                return 'yellow'
            else:
                return 'red'
        
        elif ratio_name == 'own_fund_to_wf':
            if calculated_value >= IDEAL_OWN_FUND_TO_WF:
                return 'green'
            elif calculated_value >= IDEAL_OWN_FUND_TO_WF * 0.7:
                return 'yellow'
            else:
                return 'red'
        
        # Default: compare with ideal value
        if calculated_value >= ideal_value:
            return 'green'
        elif calculated_value >= ideal_value * 0.7:
            return 'yellow'
        else:
            return 'red'
    
    def _get_ideal_value(self, ratio_name: str):
        """Get ideal value for a ratio from config"""
        ideal_map = {
            'stock_turnover': IDEAL_STOCK_TURNOVER,
            'gross_profit_ratio': IDEAL_GROSS_PROFIT_RATIO_MIN,
            'own_fund_to_wf': IDEAL_OWN_FUND_TO_WF,
            'loans_to_wf': IDEAL_LOANS_TO_WF_MIN,
            'investments_to_wf': IDEAL_INVESTMENTS_TO_WF_MIN,
            'gross_fin_margin': IDEAL_GROSS_FINANCIAL_MARGIN,
            'net_fin_margin': IDEAL_NET_FINANCIAL_MARGIN,
            'net_margin': IDEAL_NET_MARGIN,
            'operating_cost_to_wf': IDEAL_OPERATING_COST_TO_WF_MAX,
            'risk_cost_to_wf': IDEAL_RISK_COST_TO_WF_MAX,
            'credit_deposit_ratio': IDEAL_CREDIT_DEPOSIT_RATIO_MIN,
        }
        return ideal_map.get(ratio_name)
    
    def generate_interpretation(self):
        """Generate automated text interpretation based on calculated ratios"""
        all_ratios = self.calculate_all_ratios()
        interpretations = []
        
        # Credit Deposit Ratio interpretation
        if all_ratios['credit_deposit_ratio'] > 70:
            interpretations.append("Efficiency in deploying resources is high.")
        else:
            interpretations.append("Under-utilization of mobilized deposits.")
        
        # Cost effectiveness check
        if all_ratios['cost_of_deposits'] > 0 and all_ratios['yield_on_loans'] > 0:
            if all_ratios['cost_of_deposits'] < (all_ratios['yield_on_loans'] - 4):
                interpretations.append("Cost-effective deposit management.")
            else:
                interpretations.append("Deposit costs are relatively high compared to loan yields.")
        
        # Net Margin interpretation
        if all_ratios['net_margin'] >= 1.0:
            interpretations.append("Healthy profitability.")
        elif all_ratios['net_margin'] >= 0.5:
            interpretations.append("Moderate profitability - room for improvement.")
        else:
            interpretations.append("Low profitability - requires immediate attention.")
        
        # Risk Cost interpretation
        if all_ratios['risk_cost_to_wf'] > 0.25:
            interpretations.append("High risk exposure - review provisions.")
        elif all_ratios['risk_cost_to_wf'] > 0.15:
            interpretations.append("Moderate risk exposure.")
        else:
            interpretations.append("Low risk exposure.")
        
        # Stock Turnover interpretation
        if all_ratios['stock_turnover'] >= 15:
            interpretations.append("Good inventory management.")
        elif all_ratios['stock_turnover'] >= 10:
            interpretations.append("Adequate inventory turnover.")
        else:
            interpretations.append("Low inventory turnover - review stock management.")
        
        # Fund Structure interpretation
        if all_ratios['loans_to_wf'] < 70:
            interpretations.append("Loans deployment below optimal level.")
        elif all_ratios['loans_to_wf'] > 75:
            interpretations.append("High loan deployment - ensure adequate liquidity.")
        
        return " ".join(interpretations)
    
    def calculate_all_ratios(self):
        """Calculate all ratios and return comprehensive dictionary"""
        base_vars = self.calculate_base_variables()
        trading = self.calculate_trading_ratios()
        fund_structure = self.calculate_fund_structure_ratios()
        yield_cost = self.calculate_yield_cost_ratios()
        margins = self.calculate_margin_ratios()
        
        # Combine all ratios
        all_ratios = {
            **base_vars,
            **trading,
            **fund_structure,
            **yield_cost,
            **margins
        }
        
        # Convert Decimal values to float for JSON serialization
        for key, value in all_ratios.items():
            if isinstance(value, Decimal):
                all_ratios[key] = float(value)
        
        return all_ratios
    
    def get_traffic_light_statuses(self):
        """Get traffic light status for all ratios"""
        all_ratios = self.calculate_all_ratios()
        statuses = {}
        
        for ratio_name, value in all_ratios.items():
            if isinstance(value, (int, float)) and ratio_name not in ['working_fund', 'own_funds', 'average_stock', 'cogs']:
                statuses[ratio_name] = self.get_traffic_light_status(ratio_name, value)
        
        return statuses
