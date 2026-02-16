import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { ArrowLeft, TrendingUp, ChevronDown } from "lucide-react";
import TrendAnalysisChart from "../../components/TrendAnalysisChart";
import TrendComparisonCards from "../../components/TrendComparisonCards";
import { RatioResultData, getFinancialPeriods, getRatioResults } from "../FinancialStatements/api";

interface FinancialPeriod {
    id: number;
    label: string;
    start_date: string;
    end_date: string;
}

const TrendAnalysisPage: React.FC = () => {
    const navigate = useNavigate();
    const [periods, setPeriods] = useState<FinancialPeriod[]>([]);
    const [selectedPeriods, setSelectedPeriods] = useState<number[]>([]);
    const [ratiosData, setRatiosData] = useState<RatioResultData[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");
    const [selectedRatio, setSelectedRatio] = useState<string>("gross_profit_ratio");
    const [showRatioDropdown, setShowRatioDropdown] = useState(false);

    // Available ratios for comparison
    const availableRatios = [
        { key: "gross_profit_ratio", label: "Gross Profit Ratio" },
        { key: "net_profit_ratio", label: "Net Profit Ratio" },
        { key: "stock_turnover", label: "Stock Turnover" },
        { key: "own_fund_to_wf", label: "Own Fund to WF" },
        { key: "deposits_to_wf", label: "Deposits to WF" },
        { key: "loans_to_wf", label: "Loans to WF" },
        { key: "investments_to_wf", label: "Investments to WF" },
        { key: "cost_of_deposits", label: "Cost of Deposits" },
        { key: "yield_on_loans", label: "Yield on Loans" },
        { key: "credit_deposit_ratio", label: "Credit Deposit Ratio" },
        { key: "avg_yield_on_wf", label: "Avg Yield on WF" },
        { key: "avg_cost_of_wf", label: "Avg Cost of WF" },
        { key: "net_margin", label: "Net Margin" },
        { key: "capital_turnover_ratio", label: "Capital Turnover Ratio" },
        { key: "per_employee_deposit", label: "Per Employee Deposit" },
        { key: "per_employee_loan", label: "Per Employee Loan" },
        { key: "per_employee_contribution", label: "Per Employee Contribution" },
    ];

    // Fetch all periods and initial data
    useEffect(() => {
        const initData = async () => {
            try {
                const data = await getFinancialPeriods();
                // Sort by start_date ascending
                const sortedData = data.sort((a: any, b: any) =>
                    new Date(a.start_date).getTime() - new Date(b.start_date).getTime()
                );

                setPeriods(sortedData);

                const allIds = sortedData.map((p: any) => p.id);
                setSelectedPeriods(allIds);

                // Auto-fetch ratios for all periods
                if (allIds.length > 0) {
                    setLoading(true);
                    try {
                        const ratiosPromises = allIds.map((periodId: number) =>
                            getRatioResults(periodId)
                        );
                        const allRatios = (await Promise.all(ratiosPromises)).filter((r): r is RatioResultData => r !== null);
                        // Sort ratios to match period order (just in case)
                        const sortedRatios = allRatios.sort((a, b) => {
                            const periodA = sortedData.find((p: any) => p.id === a.period);
                            const periodB = sortedData.find((p: any) => p.id === b.period);
                            if (!periodA || !periodB) return 0;
                            return new Date(periodA.start_date).getTime() - new Date(periodB.start_date).getTime();
                        });

                        setRatiosData(sortedRatios);
                    } catch (err) {
                        setError("Failed to load ratio data");
                        console.error(err);
                    } finally {
                        setLoading(false);
                    }
                }

            } catch (err) {
                setError("Failed to load periods");
                console.error(err);
            }
        };

        initData();
    }, []);

    return (
        <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4">
            <div className="max-w-7xl mx-auto">
                {/* Header */}
                <div className="mb-8">
                    <button
                        onClick={() => navigate(-1)}
                        className="flex items-center gap-2 text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 mb-4"
                    >
                        <ArrowLeft size={20} />
                        <span>Back</span>
                    </button>

                    <div className="flex items-center gap-3 mb-2">
                        <TrendingUp size={32} className="text-blue-600 dark:text-blue-400" />
                        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                            Trend Analysis
                        </h1>
                    </div>
                </div>

                {/* Error Message */}
                {error && (
                    <div className="mb-4 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
                        <p className="text-red-600 dark:text-red-400 text-sm">{error}</p>
                    </div>
                )}

                {/* Loading State */}
                {loading && (
                    <div className="flex items-center justify-center p-12">
                        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
                    </div>
                )}

                {/* Trend Chart */}
                {!loading && ratiosData.length > 0 && selectedPeriods.length > 0 && (
                    <TrendAnalysisChart
                        ratioData={ratiosData}
                        periods={periods.filter(p => selectedPeriods.includes(p.id))}
                    />
                )}

                {/* Year-over-Year Comparison Section */}
                {!loading && ratiosData.length > 0 && selectedPeriods.length > 0 && (
                    <div className="mt-12 bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
                        <div className="mb-6">
                            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
                                Year-over-Year Comparison
                            </h2>

                            {/* Ratio Selection */}
                            <div className="relative w-full md:w-72">
                                <button
                                    onClick={() => setShowRatioDropdown(!showRatioDropdown)}
                                    className="w-full px-4 py-2 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg text-left text-gray-900 dark:text-white font-medium flex items-center justify-between hover:bg-gray-50 dark:hover:bg-gray-600 transition"
                                >
                                    {availableRatios.find(r => r.key === selectedRatio)?.label || "Select Ratio"}
                                    <ChevronDown
                                        size={18}
                                        className={`transition-transform ${showRatioDropdown ? "rotate-180" : ""}`}
                                    />
                                </button>

                                {showRatioDropdown && (
                                    <div className="absolute top-full left-0 right-0 mt-2 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg shadow-lg z-10 max-h-64 overflow-y-auto">
                                        {availableRatios.map((ratio) => (
                                            <button
                                                key={ratio.key}
                                                onClick={() => {
                                                    setSelectedRatio(ratio.key);
                                                    setShowRatioDropdown(false);
                                                }}
                                                className={`w-full text-left px-4 py-2 hover:bg-blue-50 dark:hover:bg-gray-600 transition ${selectedRatio === ratio.key
                                                        ? "bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 font-semibold"
                                                        : "text-gray-700 dark:text-gray-300"
                                                    }`}
                                            >
                                                {ratio.label}
                                            </button>
                                        ))}
                                    </div>
                                )}
                            </div>
                        </div>

                        {/* Comparison Cards */}
                        <TrendComparisonCards
                            ratioData={ratiosData}
                            periods={periods.filter(p => selectedPeriods.includes(p.id))}
                            selectedRatio={selectedRatio}
                        />
                    </div>
                )}

                {/* Empty State / Info Section */}
                {!loading && selectedPeriods.length === 0 && (
                    <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-6 text-center">
                        <h3 className="font-semibold text-gray-900 dark:text-white mb-2">
                            No Periods Available
                        </h3>
                        <p className="text-sm text-gray-600 dark:text-gray-400">
                            Upload financial data to see trend analysis.
                        </p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default TrendAnalysisPage;
