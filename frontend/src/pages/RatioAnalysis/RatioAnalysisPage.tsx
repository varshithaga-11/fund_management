import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import {
    FileText,
    TrendingUp,
    Calendar,
    ArrowRight,
    Search,
    X
} from "lucide-react";
import { FinancialPeriodData, getFinancialPeriods } from "../FinancialStatements/api";
import { BeatLoader } from "react-spinners";

const RatioAnalysisPage: React.FC = () => {
    const navigate = useNavigate();
    const [periods, setPeriods] = useState<FinancialPeriodData[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState<string>("");

    useEffect(() => {
        const fetchPeriods = async () => {
            try {
                const data = await getFinancialPeriods();
                setPeriods(data);
            } catch (error) {
                console.error("Error fetching periods:", error);
            } finally {
                setLoading(false);
            }
        };

        fetchPeriods();
    }, []);

    // Month names mapping
    const monthNames = [
        "january", "february", "march", "april", "may", "june",
        "july", "august", "september", "october", "november", "december"
    ];

    // Filter periods based on search query
    const filteredPeriods = periods.filter((period) => {
        if (!searchQuery.trim()) return true;
        
        const startDate = new Date(period.start_date);
        const periodMonth = monthNames[startDate.getMonth()];
        const periodYear = String(startDate.getFullYear());
        const query = searchQuery.toLowerCase();

        return periodMonth.includes(query) || periodYear.includes(query) || period.label.toLowerCase().includes(query);
    });

    const handleClearSearch = () => {
        setSearchQuery("");
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center h-screen">
                <BeatLoader color="#3b82f6" />
            </div>
        );
    }

    return (
        <div className="p-6 space-y-6 bg-gray-50 dark:bg-gray-900 min-h-screen">
            <div className="flex justify-between items-center mb-8">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                        Ratio Analysis
                    </h1>
                    <p className="text-gray-600 dark:text-gray-400 mt-1">
                        Select a financial period to analyze ratios or view trends
                    </p>
                </div>
                <button
                    onClick={() => navigate('/ratio-analysis/trends')}
                    className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors shadow-sm"
                >
                    <TrendingUp className="w-4 h-4" />
                    <span>View Trends</span>
                </button>
            </div>

            {/* Search Bar */}
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-4 border border-gray-200 dark:border-gray-700">
                <div className="flex items-center gap-3">
                    <Search className="w-5 h-5 text-gray-400 flex-shrink-0" />
                    <div className="flex-1 flex items-center gap-2">
                        <input
                            type="text"
                            placeholder="Search by month name or year..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                        {searchQuery && (
                            <button
                                onClick={handleClearSearch}
                                className="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors flex items-center gap-1 text-sm flex-shrink-0"
                            >
                                <X className="w-3 h-3" />
                            </button>
                        )}
                    </div>
                </div>
                {searchQuery && (
                    <div className="mt-2 text-sm text-gray-600 dark:text-gray-400">
                        Found <span className="font-semibold text-gray-900 dark:text-white">{filteredPeriods.length}</span> period{filteredPeriods.length !== 1 ? 's' : ''}
                    </div>
                )}
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {/* Period Cards */}
                {filteredPeriods.map((period) => (
                    <div
                        key={period.id}
                        onClick={() => navigate(`/ratio-analysis/${period.id}`)}
                        className="cursor-pointer group bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm hover:shadow-md border border-gray-200 dark:border-gray-700 transition-all duration-300 transform hover:-translate-y-1"
                    >
                        <div className="flex justify-between items-start mb-4">
                            <div className="w-12 h-12 bg-blue-50 dark:bg-blue-900/20 rounded-lg flex items-center justify-center">
                                <FileText className="text-blue-600 dark:text-blue-400 w-6 h-6" />
                            </div>
                            <span className={`px-3 py-1 text-xs font-medium rounded-full ${period.is_finalized
                                    ? 'text-green-600 bg-green-50 dark:bg-green-900/20'
                                    : 'text-yellow-600 bg-yellow-50 dark:bg-yellow-900/20'
                                }`}>
                                {period.is_finalized ? 'Finalized' : 'Draft'}
                            </span>
                        </div>

                        <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-2 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
                            {period.label}
                        </h3>

                        <div className="space-y-2 mb-4">
                            <div className="flex items-center text-sm text-gray-500 dark:text-gray-400">
                                <Calendar className="w-4 h-4 mr-2" />
                                <span>
                                    {new Date(period.start_date).toLocaleDateString()} - {new Date(period.end_date).toLocaleDateString()}
                                </span>
                            </div>
                        </div>

                        <div className="pt-4 border-t border-gray-100 dark:border-gray-700 flex justify-between items-center text-sm">
                            <span className="text-gray-500 dark:text-gray-400">
                                View Analysis
                            </span>
                            <ArrowRight className="w-4 h-4 text-gray-400 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors" />
                        </div>
                    </div>
                ))}
            </div>

            {filteredPeriods.length === 0 && (
                <div className="text-center py-12">
                    <div className="bg-gray-100 dark:bg-gray-800 rounded-full w-16 h-16 flex items-center justify-center mx-auto mb-4">
                        <FileText className="text-gray-400 w-8 h-8" />
                    </div>
                    <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
                        {periods.length === 0 ? "No Periods Found" : "No Results Found"}
                    </h3>
                    <p className="text-gray-500 dark:text-gray-400">
                        {periods.length === 0
                            ? "Please upload financial statements to start analyzing ratios."
                            : "Try adjusting your search filters to find the period you're looking for."
                        }
                    </p>
                </div>
            )}
        </div>
    );
};

export default RatioAnalysisPage;
