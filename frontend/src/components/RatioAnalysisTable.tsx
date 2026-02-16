import React from "react";
// Table component for displaying ratio analysis results
import { RatioResultData } from "../pages/FinancialStatements/api";

interface RatioAnalysisTableProps {
    ratios: RatioResultData;
    period?: string;
}

const RatioAnalysisTable: React.FC<RatioAnalysisTableProps> = ({ ratios, period }) => {
    const categories = [
        {
            title: "Trading Ratios",
            items: [
                { label: "Stock Turnover", value: ratios.stock_turnover, unit: "times" },
                { label: "Gross Profit Ratio", value: ratios.gross_profit_ratio, unit: "%" },
                { label: "Net Profit Ratio", value: ratios.net_profit_ratio, unit: "%" },
            ],
        },
        {
            title: "Capital Efficiency",
            items: [
                { label: "Capital Turnover Ratio", value: ratios.capital_turnover_ratio, unit: "times" },
            ],
        },
        {
            title: "Fund Structure Ratios",
            items: [
                { label: "Net Own Funds", value: ratios.net_own_funds, unit: "" },
                { label: "Own Fund to Working Fund", value: ratios.own_fund_to_wf, unit: "%" },
                { label: "Deposits to Working Fund", value: ratios.deposits_to_wf, unit: "%" },
                { label: "Borrowings to Working Fund", value: ratios.borrowings_to_wf, unit: "%" },
                { label: "Loans to Working Fund", value: ratios.loans_to_wf, unit: "%" },
                { label: "Investments to Working Fund", value: ratios.investments_to_wf, unit: "%" },
                { label: "Earning Assets to Working Fund", value: ratios.earning_assets_to_wf, unit: "%" },
                { label: "Interest Tagged Funds to Working Fund", value: ratios.interest_tagged_funds_to_wf, unit: "%" },
            ],
        },
        {
            title: "Yield & Cost Ratios",
            items: [
                { label: "Cost of Deposits", value: ratios.cost_of_deposits, unit: "%" },
                { label: "Yield on Loans", value: ratios.yield_on_loans, unit: "%" },
                { label: "Yield on Investments", value: ratios.yield_on_investments, unit: "%" },
                { label: "Credit Deposit Ratio", value: ratios.credit_deposit_ratio, unit: "%" },
                { label: "Avg Cost of Working Fund", value: ratios.avg_cost_of_wf, unit: "%" },
                { label: "Avg Yield on Working Fund", value: ratios.avg_yield_on_wf, unit: "%" },
                { label: "Miscellaneous Income to WF", value: ratios.misc_income_to_wf, unit: "%" },
                { label: "Interest Expenses to Interest Income", value: ratios.interest_exp_to_interest_income, unit: "%" },
            ],
        },
        {
            title: "Margin Ratios",
            items: [
                { label: "Gross Financial Margin", value: ratios.gross_fin_margin, unit: "%" },
                { label: "Operating Cost to Working Fund", value: ratios.operating_cost_to_wf, unit: "%" },
                { label: "Net Financial Margin", value: ratios.net_fin_margin, unit: "%" },
                { label: "Risk Cost to Working Fund", value: ratios.risk_cost_to_wf, unit: "%" },
                { label: "Net Margin", value: ratios.net_margin, unit: "%" },
            ],
        },
        {
            title: "Productivity Ratios",
            items: [
                { label: "Per Employee Deposit", value: ratios.per_employee_deposit, unit: " Lakhs" },
                { label: "Per Employee Loan", value: ratios.per_employee_loan, unit: " Lakhs" },
                { label: "Per Employee Contribution", value: ratios.per_employee_contribution, unit: " Lakhs" },
                { label: "Per Employee Operating Cost", value: ratios.per_employee_operating_cost, unit: " Lakhs" },
            ],
        },
    ];

    return (
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow overflow-hidden">
            <div className="p-4 border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                    Ratio Analysis Table {period && `- ${period}`}
                </h3>
            </div>
            <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                    <thead className="bg-gray-50 dark:bg-gray-700">
                        <tr>
                            <th
                                scope="col"
                                className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider"
                            >
                                Ratio Category / Name
                            </th>
                            <th
                                scope="col"
                                className="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider"
                            >
                                Value
                            </th>
                        </tr>
                    </thead>
                    <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                        {categories.map((category) => (
                            <React.Fragment key={category.title}>
                                <tr className="bg-gray-50 dark:bg-gray-900/50">
                                    <td
                                        colSpan={2}
                                        className="px-6 py-2 text-sm font-semibold text-gray-900 dark:text-white"
                                    >
                                        {category.title}
                                    </td>
                                </tr>
                                {category.items.map((item) => (
                                    <tr key={item.label} className="hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700 dark:text-gray-300 pl-8">
                                            {item.label}
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white text-right font-medium">
                                            {item.value !== null && item.value !== undefined
                                                ? typeof item.value === 'number'
                                                    ? item.value.toLocaleString("en-IN", {
                                                        minimumFractionDigits: 2,
                                                        maximumFractionDigits: 2,
                                                    })
                                                    : item.value
                                                : "-"}{" "}
                                            {item.unit}
                                        </td>
                                    </tr>
                                ))}
                            </React.Fragment>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default RatioAnalysisTable;
