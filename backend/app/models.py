from django.db import models
from django.contrib.auth.models import AbstractUser
from django.conf import settings


# Create your models here.



class UserRegister(AbstractUser):
    ROLE_CHOICES = (
        ('admin', 'Admin'),
        ('master', 'Master'),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL,on_delete=models.SET_NULL,null=True)
    phone_number = models.CharField(max_length=15, blank=True, null=True, unique=True)  # Added phone number field
    
    def __str__(self):
        return self.username
    

class Company(models.Model):
    name = models.CharField(max_length=255)
    registration_no = models.CharField(max_length=100, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class FinancialPeriod(models.Model):
    PERIOD_TYPE_CHOICES = [
        ("MONTHLY", "Monthly"),
        ("QUARTERLY", "Quarterly"),
        ("HALF_YEARLY", "Half Yearly"),
        ("YEARLY", "Yearly"),
    ]

    company = models.ForeignKey(
        Company,
        on_delete=models.CASCADE,
        related_name="periods"
    )
    period_type = models.CharField(max_length=20, choices=PERIOD_TYPE_CHOICES)
    start_date = models.DateField()
    end_date = models.DateField()
    label = models.CharField(max_length=50)  # e.g. FY-2023-24, Mar-2024
    is_finalized = models.BooleanField(default=False)
    
    # Store the uploaded Excel file
    excel_file = models.FileField(upload_to='company_financials/%Y/%m/', null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("company", "label")

    def __str__(self):
        return f"{self.company.name} - {self.label}"



class TradingAccount(models.Model):
    period = models.OneToOneField(
        FinancialPeriod,
        on_delete=models.CASCADE,
        related_name="trading_account"
    )

    opening_stock = models.DecimalField(max_digits=15, decimal_places=2)
    purchases = models.DecimalField(max_digits=15, decimal_places=2)
    trade_charges = models.DecimalField(max_digits=15, decimal_places=2)
    sales = models.DecimalField(max_digits=15, decimal_places=2)
    closing_stock = models.DecimalField(max_digits=15, decimal_places=2)

    @property
    def gross_profit(self):
        return (
            self.sales
            + self.closing_stock
            - (self.opening_stock + self.purchases + self.trade_charges)
        )


class ProfitAndLoss(models.Model):
    period = models.OneToOneField(
        FinancialPeriod,
        on_delete=models.CASCADE,
        related_name="profit_loss"
    )

    # Income
    interest_on_loans = models.DecimalField(max_digits=15, decimal_places=2)
    interest_on_bank_ac = models.DecimalField(max_digits=15, decimal_places=2)
    return_on_investment = models.DecimalField(max_digits=15, decimal_places=2)
    miscellaneous_income = models.DecimalField(max_digits=15, decimal_places=2)

    # Expenses
    interest_on_deposits = models.DecimalField(max_digits=15, decimal_places=2)
    interest_on_borrowings = models.DecimalField(max_digits=15, decimal_places=2)
    establishment_contingencies = models.DecimalField(max_digits=15, decimal_places=2)
    provisions = models.DecimalField(max_digits=15, decimal_places=2)

    net_profit = models.DecimalField(max_digits=15, decimal_places=2)

    @property
    def total_interest_income(self):
        return (
            self.interest_on_loans
            + self.interest_on_bank_ac
            + self.return_on_investment
        )

    @property
    def total_interest_expense(self):
        return self.interest_on_deposits + self.interest_on_borrowings



class BalanceSheet(models.Model):
    period = models.OneToOneField(
        FinancialPeriod,
        on_delete=models.CASCADE,
        related_name="balance_sheet"
    )

    # Liabilities (Sources)
    share_capital = models.DecimalField(max_digits=15, decimal_places=2)
    deposits = models.DecimalField(max_digits=15, decimal_places=2)
    borrowings = models.DecimalField(max_digits=15, decimal_places=2)
    reserves_statutory_free = models.DecimalField(max_digits=15, decimal_places=2)
    undistributed_profit = models.DecimalField(max_digits=15, decimal_places=2)

    # Excluded from Working Fund
    provisions = models.DecimalField(max_digits=15, decimal_places=2)
    other_liabilities = models.DecimalField(max_digits=15, decimal_places=2)

    # Assets (Applications)
    cash_in_hand = models.DecimalField(max_digits=15, decimal_places=2)
    cash_at_bank = models.DecimalField(max_digits=15, decimal_places=2)
    investments = models.DecimalField(max_digits=15, decimal_places=2)
    loans_advances = models.DecimalField(max_digits=15, decimal_places=2)
    fixed_assets = models.DecimalField(max_digits=15, decimal_places=2)
    other_assets = models.DecimalField(max_digits=15, decimal_places=2)
    stock_in_trade = models.DecimalField(max_digits=15, decimal_places=2)

    @property
    def working_fund(self):
        # PDF-defined Working Fund (IMPORTANT)
        return (
            self.share_capital
            + self.deposits
            + self.borrowings
            + self.reserves_statutory_free
            + self.undistributed_profit
        )

    @property
    def own_funds(self):
        return (
            self.share_capital
            + self.reserves_statutory_free
            + self.undistributed_profit
        )


class OperationalMetrics(models.Model):
    period = models.OneToOneField(
        FinancialPeriod,
        on_delete=models.CASCADE,
        related_name="operational_metrics"
    )

    staff_count = models.PositiveIntegerField()



class RatioResult(models.Model):
    period = models.OneToOneField(
        FinancialPeriod,
        on_delete=models.CASCADE,
        related_name="ratios"
    )

    working_fund = models.DecimalField(max_digits=15, decimal_places=2)

    # Trading Ratios
    stock_turnover = models.DecimalField(max_digits=6, decimal_places=2)
    gross_profit_ratio = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    net_profit_ratio = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)

    # Fund Structure Ratios
    own_fund_to_wf = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    deposits_to_wf = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    borrowings_to_wf = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    loans_to_wf = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    investments_to_wf = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)

    # Yield & Cost Ratios
    cost_of_deposits = models.DecimalField(max_digits=6, decimal_places=2)
    yield_on_loans = models.DecimalField(max_digits=6, decimal_places=2)
    yield_on_investments = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    credit_deposit_ratio = models.DecimalField(max_digits=6, decimal_places=2)
    avg_cost_of_wf = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    avg_yield_on_wf = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)

    # Margin Ratios
    gross_fin_margin = models.DecimalField(max_digits=6, decimal_places=2)
    operating_cost_to_wf = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    net_fin_margin = models.DecimalField(max_digits=6, decimal_places=2)
    risk_cost_to_wf = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    net_margin = models.DecimalField(max_digits=6, decimal_places=2)

    # Store all ratios in JSON for flexibility
    all_ratios = models.JSONField(default=dict, blank=True)
    traffic_light_status = models.JSONField(default=dict, blank=True)

    calculated_at = models.DateTimeField(auto_now_add=True)


class AppConfig(models.Model):
    """Store app-wide config (e.g. ratio benchmarks). key='ratio_benchmarks' -> JSON dict."""
    key = models.CharField(max_length=100, unique=True)
    value = models.JSONField(default=dict)

    def __str__(self):
        return self.key


class StatementColumnConfig(models.Model):
    STATEMENT_CHOICES = [
        ("TRADING", "Trading Account"),
        ("PL", "Profit & Loss"),
        ("BALANCE_SHEET", "Balance Sheet"),
        ("OPERATIONAL", "Operational"),
    ]

    company = models.ForeignKey(
        Company,
        on_delete=models.CASCADE,
        null=True,
        blank=True
    )

    statement_type = models.CharField(
        max_length=20,
        choices=STATEMENT_CHOICES
    )

    canonical_field = models.CharField(
        max_length=100,
        help_text="Internal field name (e.g. interest_on_deposits)"
    )

    display_name = models.CharField(
        max_length=255,
        help_text="Shown in UI / PDF (e.g. Deposit Interest)"
    )

    # Alternative names/synonyms for matching in uploads or UI search
    aliases = models.JSONField(default=list, blank=True)

    is_required = models.BooleanField(default=True)

    class Meta:
        unique_together = ("company", "statement_type", "canonical_field")
        ordering = ["canonical_field"]

    @classmethod
    def _normalize_for_match(cls, value):
        """Normalize so 'opening inventory' and 'opening_inventory' match."""
        if not value or not isinstance(value, str):
            return ""
        return value.strip().lower().replace(" ", "_")

    @classmethod
    def _config_matches_column(cls, config, normalized):
        """Return config.canonical_field if this config matches the normalized column name, else None."""
        if config.canonical_field and cls._normalize_for_match(config.canonical_field) == normalized:
            return config.canonical_field
        if config.display_name and cls._normalize_for_match(config.display_name) == normalized:
            return config.canonical_field
        for a in (config.aliases or []):
            if isinstance(a, str) and cls._normalize_for_match(a) == normalized:
                return config.canonical_field
        return None

    @classmethod
    def resolve_canonical_field(cls, company, statement_type, column_name):
        """
        Resolve an uploaded column/item name to the canonical field name.
        For each column: check company-specific configs first; if no match, check global configs.
        This allows some fields to come from company-specific and others from global.
        Matches after normalizing: strip, lower, spaces -> underscores.
        Returns canonical_field if match found, else None.
        """
        if not column_name or not isinstance(column_name, str):
            return None
        normalized = cls._normalize_for_match(column_name)
        if not normalized:
            return None
        # 1) Company-specific configs first (if company is set)
        if company:
            for config in cls.objects.filter(company=company, statement_type=statement_type):
                canonical = cls._config_matches_column(config, normalized)
                if canonical:
                    return canonical
        # 2) Fallback: global configs (company is null)
        for config in cls.objects.filter(company__isnull=True, statement_type=statement_type):
            canonical = cls._config_matches_column(config, normalized)
            if canonical:
                return canonical
        return None






# def get_statement_columns(company, statement_type):
#     # 1. Company-specific
#     cols = StatementColumnConfig.objects.filter(
#         company=company,
#         statement_type=statement_type
#     )

#     # 2. Fallback to global
#     if not cols.exists():
#         cols = StatementColumnConfig.objects.filter(
#             company__isnull=True,
#             statement_type=statement_type
#         )

#     return cols



# Company
#  └── FinancialPeriod
#       ├── TradingAccount
#       ├── ProfitAndLoss
#       ├── BalanceSheet
#       ├── OperationalMetrics
#       └── RatioResult



# FY-2023-24 → YEARLY

# Apr-2024 → MONTHLY

# Q1-FY-2024-25 → QUARTERLY

# H1-FY-2024-25 → HALF_YEARLY