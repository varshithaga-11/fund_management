"""
Ideal benchmark values for financial ratios in Co-operative Societies.
These values are based on regulatory standards and best practices.
Used as defaults when no custom benchmarks are stored in the database.
"""

# Trading Ratios
IDEAL_STOCK_TURNOVER = 15.0  # times per year
IDEAL_GROSS_PROFIT_RATIO_MIN = 10.0  # percentage
IDEAL_GROSS_PROFIT_RATIO_MAX = 15.0  # percentage
IDEAL_NET_PROFIT_RATIO = None  # ~50% of Gross Profit Ratio (contextual)

# Fund Structure Ratios (as % of Working Fund)
IDEAL_OWN_FUND_TO_WF = 8.0  # percentage
IDEAL_DEPOSITS_TO_WF = None  # Contextual (N/A)
IDEAL_BORROWINGS_TO_WF = None  # Contextual (N/A)
IDEAL_LOANS_TO_WF_MIN = 70.0  # percentage
IDEAL_LOANS_TO_WF_MAX = 75.0  # percentage
IDEAL_INVESTMENTS_TO_WF_MIN = 25.0  # percentage
IDEAL_INVESTMENTS_TO_WF_MAX = 30.0  # percentage

# Yield & Cost Ratios
IDEAL_COST_OF_DEPOSITS = None  # Should be 4% less than Yield on Loans
IDEAL_YIELD_ON_LOANS = None  # Should be 4% more than Cost of Deposits
IDEAL_YIELD_ON_INVESTMENTS = None  # Should be >= Cost of Deposits
IDEAL_AVG_COST_OF_WF = 3.5  # percentage (should be < Avg Yield on WF)
IDEAL_AVG_YIELD_ON_WF = 3.5  # percentage (should be > Avg Cost of WF)

# Margin Ratios
IDEAL_GROSS_FINANCIAL_MARGIN = 3.5  # percentage
IDEAL_OPERATING_COST_TO_WF_MIN = 2.0  # percentage
IDEAL_OPERATING_COST_TO_WF_MAX = 2.5  # percentage
IDEAL_NET_FINANCIAL_MARGIN = 1.50  # percentage
IDEAL_RISK_COST_TO_WF_MAX = 0.25  # percentage (should be < 0.25%)
IDEAL_NET_MARGIN = 1.0  # percentage

# Credit Deposit Ratio
IDEAL_CREDIT_DEPOSIT_RATIO_MIN = 70.0  # percentage (efficiency threshold)

# Productivity Metrics (contextual, no fixed ideal)
# Per Employee Business, Contribution, Operating Cost are contextual


# Default benchmark dict for API and DB merge. None means "no fixed benchmark".
# Frontend can display and edit these; backend uses DB values when present.
DEFAULT_RATIO_BENCHMARKS = {
    # Trading
    "stock_turnover": 15.0,
    "gross_profit_ratio_min": 10.0,
    "gross_profit_ratio_max": 15.0,
    # Fund Structure
    "own_fund_to_wf": 8.0,
    "loans_to_wf_min": 70.0,
    "loans_to_wf_max": 75.0,
    "investments_to_wf_min": 25.0,
    "investments_to_wf_max": 30.0,
    # Yield & Cost
    "avg_cost_of_wf": 3.5,
    "avg_yield_on_wf": 3.5,
    # Margins
    "gross_financial_margin": 3.5,
    "operating_cost_to_wf_min": 2.0,
    "operating_cost_to_wf_max": 2.5,
    "net_financial_margin": 1.50,
    "risk_cost_to_wf_max": 0.25,
    "net_margin": 1.0,
    # Credit Deposit
    "credit_deposit_ratio_min": 70.0,
}
