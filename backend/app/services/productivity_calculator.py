"""
Productivity Calculator Service
Calculates per-employee metrics and efficiency indicators
"""
from decimal import Decimal
from django.core.exceptions import ValidationError
from app.models import FinancialPeriod


class ProductivityCalculator:
    """Calculates productivity metrics for co-operative societies"""
    
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
        if not hasattr(self.period, 'profit_loss'):
            raise ValidationError("ProfitAndLoss not found for this period")
        if not hasattr(self.period, 'balance_sheet'):
            raise ValidationError("BalanceSheet not found for this period")
        if not hasattr(self.period, 'operational_metrics'):
            raise ValidationError("OperationalMetrics not found for this period")
    
    def calculate_per_employee_business(self):
        """
        Calculate per employee business (in Lakhs)
        Formula: (Average Deposit + Average Loan) / Staff Count / 100000
        
        Note: Using current period values as average (can be enhanced with historical data)
        """
        bs = self.period.balance_sheet
        ops = self.period.operational_metrics
        
        if ops.staff_count > 0:
            avg_deposit = bs.deposits  # Using current period value
            avg_loan = bs.loans_advances  # Using current period value
            return float((avg_deposit + avg_loan) / Decimal(str(ops.staff_count)) / Decimal('100000.0'))
        return 0.0
    
    def calculate_per_employee_contribution(self):
        """
        Calculate per employee contribution (in Lakhs)
        Formula: (Total Income - Interest Expenses) / Staff Count / 100000
        """
        pl = self.period.profit_loss
        ops = self.period.operational_metrics
        
        if ops.staff_count > 0:
            total_income = (
                pl.interest_on_loans +
                pl.interest_on_bank_ac +
                pl.return_on_investment +
                pl.miscellaneous_income
            )
            contribution = total_income - pl.total_interest_expense
            return float(contribution / Decimal(str(ops.staff_count)) / Decimal('100000.0'))
        return 0.0
    
    def calculate_per_employee_operating_cost(self):
        """
        Calculate per employee operating cost (in Lakhs)
        Formula: Establishment & Contingencies / Staff Count / 100000
        """
        pl = self.period.profit_loss
        ops = self.period.operational_metrics
        
        if ops.staff_count > 0:
            return float(pl.establishment_contingencies / Decimal(str(ops.staff_count)) / Decimal('100000.0'))
        return 0.0
    
    def is_efficient(self):
        """
        Determine if the organization is efficient
        Returns True if Per Employee Contribution > Per Employee Operating Cost
        """
        contribution = self.calculate_per_employee_contribution()
        operating_cost = self.calculate_per_employee_operating_cost()
        return contribution > operating_cost
    
    def calculate_all_productivity_metrics(self):
        """Calculate all productivity metrics"""
        return {
            'per_employee_business': self.calculate_per_employee_business(),
            'per_employee_contribution': self.calculate_per_employee_contribution(),
            'per_employee_operating_cost': self.calculate_per_employee_operating_cost(),
            'is_efficient': self.is_efficient(),
            'staff_count': self.period.operational_metrics.staff_count
        }
