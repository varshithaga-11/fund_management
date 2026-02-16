import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { ArrowLeft, TrendingUp } from "lucide-react";
import TrendAnalysisChart from "../../components/TrendAnalysisChart";
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

    // Fetch all periods
    useEffect(() => {
        const fetchPeriods = async () => {
            try {
                const data = await getFinancialPeriods();
                setPeriods(data);
            } catch (err) {
                setError("Failed to load periods");
                console.error(err);
            }
        };

        fetchPeriods();
    }, []);

    // Fetch ratio data for selected periods
    const handleViewTrends = async () => {
        if (selectedPeriods.length < 2) {
            setError("Please select at least 2 periods to view trends");
            return;
        }

        setLoading(true);
        setError("");

        try {
            const ratiosPromises = selectedPeriods.map((periodId) =>
                getRatioResults(periodId)
            );

            const allRatios = (await Promise.all(ratiosPromises)).filter((r): r is RatioResultData => r !== null);
            setRatiosData(allRatios);
        } catch (err) {
            setError("Failed to load ratio data");
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const togglePeriodSelection = (periodId: number) => {
        setSelectedPeriods((prev) =>
            prev.includes(periodId)
                ? prev.filter((id) => id !== periodId)
                : [...prev, periodId]
        );
    };

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
                    <p className="text-gray-600 dark:text-gray-400">
                        Select multiple periods to analyze ratio trends over time
                    </p>
                </div>

                {/* Period Selection */}
                <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6 mb-8">
                    <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                        Select Periods
                    </h2>

                    {error && (
                        <div className="mb-4 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
                            <p className="text-red-600 dark:text-red-400 text-sm">{error}</p>
                        </div>
                    )}

                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
                        {periods.map((period) => (
                            <button
                                key={period.id}
                                onClick={() => togglePeriodSelection(period.id)}
                                className={`p-4 rounded-lg border-2 transition-all ${selectedPeriods.includes(period.id)
                                    ? "border-blue-600 bg-blue-50 dark:bg-blue-900/20"
                                    : "border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600"
                                    }`}
                            >
                                <div className="flex items-start gap-3">
                                    <div
                                        className={`w-5 h-5 rounded border-2 flex items-center justify-center mt-0.5 ${selectedPeriods.includes(period.id)
                                            ? "border-blue-600 bg-blue-600"
                                            : "border-gray-300 dark:border-gray-600"
                                            }`}
                                    >
                                        {selectedPeriods.includes(period.id) && (
                                            <span className="text-white text-xs">✓</span>
                                        )}
                                    </div>
                                    <div className="text-left">
                                        <h3 className="font-semibold text-gray-900 dark:text-white">
                                            {period.label}
                                        </h3>
                                        <p className="text-sm text-gray-600 dark:text-gray-400">
                                            {new Date(period.start_date).toLocaleDateString()} -{" "}
                                            {new Date(period.end_date).toLocaleDateString()}
                                        </p>
                                    </div>
                                </div>
                            </button>
                        ))}
                    </div>

                    <div className="flex items-center justify-between">
                        <div className="text-sm text-gray-600 dark:text-gray-400">
                            {selectedPeriods.length > 0 ? (
                                <span>
                                    <strong className="text-gray-900 dark:text-white">
                                        {selectedPeriods.length}
                                    </strong>
                                    {selectedPeriods.length === 1 ? " period" : " periods"} selected
                                </span>
                            ) : (
                                <span>Select periods to begin trend analysis</span>
                            )}
                        </div>

                        <button
                            onClick={handleViewTrends}
                            disabled={selectedPeriods.length < 2 || loading}
                            className="px-6 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white rounded-lg font-medium transition-colors"
                        >
                            {loading ? "Loading..." : "View Trends"}
                        </button>
                    </div>
                </div>

                {/* Trend Chart */}
                {ratiosData.length > 0 && selectedPeriods.length > 0 && (
                    <TrendAnalysisChart
                        ratioData={ratiosData}
                        periods={periods.filter(p => selectedPeriods.includes(p.id))}
                    />
                )}

                {/* Info Section */}
                {selectedPeriods.length === 0 && (
                    <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-6">
                        <h3 className="font-semibold text-gray-900 dark:text-white mb-2">
                            How to use Trend Analysis
                        </h3>
                        <ul className="space-y-2 text-sm text-gray-700 dark:text-gray-300">
                            <li>1. Select at least 2 periods to compare</li>
                            <li>2. Click "View Trends" to see how ratios have changed</li>
                            <li>3. Use the chart tools to zoom, pan, and download the visualization</li>
                            <li>4. Monitor ratio trends to identify patterns and anomalies</li>
                        </ul>
                    </div>
                )}
            </div>
        </div>
    );
};

export default TrendAnalysisPage;
