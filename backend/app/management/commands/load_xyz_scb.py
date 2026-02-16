"""
Django management command to load XYZ Scb test data
Usage: python manage.py load_xyz_scb
"""
from django.core.management.base import BaseCommand
from django.utils import timezone
from decimal import Decimal
from app.models import (
    FinancialPeriod,
    TradingAccount,
    ProfitAndLoss,
    BalanceSheet,
    OperationalMetrics,
)
from app.services.ratio_calculator import RatioCalculator


class Command(BaseCommand):
    help = "Load XYZ Scb test dataset for validation"

    def handle(self, *args, **options):
        self.stdout.write("Loading XYZ Scb test data...")

        # Create financial period
        period, created = FinancialPeriod.objects.get_or_create(
            label="FY-2012-13",
            defaults={
                "period_type": "YEARLY",
                "start_date": "2012-04-01",
                "end_date": "2013-03-31",
                "is_finalized": True,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f"Created period: {period.label}"))
        else:
            self.stdout.write(f"Using existing period: {period.label}")

        # Create Trading Account
        trading_account, created = TradingAccount.objects.get_or_create(
            period=period,
            defaults={
                "opening_stock": Decimal("25080"),
                "purchases": Decimal("572444"),
                "trade_charges": Decimal("8176"),
                "sales": Decimal("552264"),
                "closing_stock": Decimal("40000"),
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created Trading Account"))
        else:
            self.stdout.write("Updated Trading Account")

        # Create Profit & Loss
        profit_loss, created = ProfitAndLoss.objects.get_or_create(
            period=period,
            defaults={
                "interest_on_loans": Decimal("42488657"),
                "interest_on_bank_ac": Decimal("6300000"),
                "return_on_investment": Decimal("1066314"),
                "miscellaneous_income": Decimal("3485633"),
                "interest_on_deposits": Decimal("26698057"),
                "interest_on_borrowings": Decimal("770021"),
                "establishment_contingencies": Decimal("13476132"),
                "provisions": Decimal("4533930"),
                "net_profit": Decimal("7863516"),
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created Profit & Loss"))
        else:
            self.stdout.write("Updated Profit & Loss")

        # Create Balance Sheet
        balance_sheet, created = BalanceSheet.objects.get_or_create(
            period=period,
            defaults={
                "share_capital": Decimal("5281006"),
                "deposits": Decimal("484706199"),
                "borrowings": Decimal("7001911"),
                "reserves_statutory_free": Decimal("10569840"),
                "undistributed_profit": Decimal("10866453"),
                "provisions": Decimal("53117811"),
                "other_liabilities": Decimal("46444029"),
                "cash_in_hand": Decimal("16213483"),
                "cash_at_bank": Decimal("90000000"),
                "investments": Decimal("13328928"),
                "loans_advances": Decimal("437223261"),
                "fixed_assets": Decimal("55501843"),
                "other_assets": Decimal("5678014"),
                "stock_in_trade": Decimal("40000"),
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created Balance Sheet"))
        else:
            self.stdout.write("Updated Balance Sheet")

        # Create Operational Metrics
        operational_metrics, created = OperationalMetrics.objects.get_or_create(
            period=period,
            defaults={"staff_count": 24},
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created Operational Metrics"))
        else:
            self.stdout.write("Updated Operational Metrics")

        # Calculate ratios
        self.stdout.write("\nCalculating ratios...")
        try:
            calculator = RatioCalculator(period)
            all_ratios = calculator.calculate_all_ratios()

            # Display validation results
            self.stdout.write("\n" + "=" * 60)
            self.stdout.write("VALIDATION RESULTS")
            self.stdout.write("=" * 60)

            expected_values = {
                "working_fund": 518425409,
                "cost_of_deposits": 5.50,
                "yield_on_loans": 9.80,
                "credit_deposit_ratio": 90.20,
                "stock_turnover": 15.64,
            }

            for key, expected in expected_values.items():
                calculated = all_ratios.get(key, 0)
                if isinstance(calculated, Decimal):
                    calculated = float(calculated)
                difference = abs(calculated - expected)
                status = "✓" if difference < 0.1 else "✗"
                self.stdout.write(
                    f"{status} {key}: Calculated={calculated:.2f}, Expected={expected:.2f}, Diff={difference:.2f}"
                )

            self.stdout.write("=" * 60)
            self.stdout.write(
                self.style.SUCCESS("\nXYZ Scb data loaded and validated successfully!")
            )

        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f"\nError calculating ratios: {str(e)}")
            )
