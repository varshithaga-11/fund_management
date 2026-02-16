import React, { useMemo } from "react";
import { TrendingUp, TrendingDown } from "lucide-react";

interface Period {
    id: number;
    label: string;
    start_date: string;
    end_date: string;
}

interface RatioResult {
    period: number;
    [key: string]: any;
}

interface TrendComparisonCardsProps {
    ratioData: RatioResult[];
    periods: Period[];
    selectedRatio: string;
}

const TrendComparisonCards: React.FC<TrendComparisonCardsProps> = ({
    ratioData,
    periods,
    selectedRatio,
}) => {
    const comparisonData = useMemo(() => {
        if (!ratioData || !periods || ratioData.length === 0) {
            return [];
        }

        // Create map of period id to period data
        const periodMap = new Map();
        periods.forEach((period) => {
            periodMap.set(period.id, period);
        });

        // Sort ratio data by period start_date
        const sortedRatios = [...ratioData]
            .filter((data) => data[selectedRatio] !== undefined)
            .sort((a, b) => {
                const aDate = new Date(periodMap.get(a.period)?.start_date || "");
                const bDate = new Date(periodMap.get(b.period)?.start_date || "");
                return aDate.getTime() - bDate.getTime();
            });

        // Build comparison cards with year-over-year change
        return sortedRatios.map((current, index) => {
            const currentPeriod = periodMap.get(current.period);
            const currentValue = parseFloat(current[selectedRatio]) || 0;
            const previousRatio = index > 0 ? sortedRatios[index - 1] : null;
            const previousPeriod = previousRatio
                ? periodMap.get(previousRatio.period)
                : null;
            const previousValue = previousRatio
                ? parseFloat(previousRatio[selectedRatio]) || 0
                : null;

            let changePercent = null;
            let changeDirection = null;

            if (previousValue !== null && previousValue !== 0) {
                changePercent = ((currentValue - previousValue) / previousValue) * 100;
                changeDirection =
                    changePercent > 0 ? "up" : changePercent < 0 ? "down" : "stable";
            }

            return {
                periodLabel: currentPeriod?.label || "Unknown",
                value: currentValue.toFixed(2),
                previousPeriodLabel: previousPeriod?.label || null,
                previousValue: previousValue?.toFixed(2) || null,
                changePercent,
                changeDirection,
            };
        });
    }, [ratioData, periods, selectedRatio]);

    if (comparisonData.length === 0) {
        return (
            <div className="text-center p-8 text-gray-500 dark:text-gray-400">
                No data available for comparison
            </div>
        );
    }

    return (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {comparisonData.map((card, index) => (
                <div
                    key={index}
                    className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6 border border-gray-200 dark:border-gray-700 hover:shadow-lg transition-shadow"
                >
                    {/* Period Label */}
                    <div className="mb-2">
                        <p className="text-sm text-gray-500 dark:text-gray-400">
                            Year
                        </p>
                        <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                            {card.periodLabel}
                        </h3>
                    </div>

                    {/* Value */}
                    <div className="mb-4">
                        <p className="text-3xl font-bold text-blue-600 dark:text-blue-400">
                            {card.value}
                        </p>
                    </div>

                    {/* Change Comparison */}
                    {card.changePercent !== null && (
                        <div className="pt-4 border-t border-gray-200 dark:border-gray-700">
                            <div className="flex items-center justify-between mb-2">
                                <p className="text-xs text-gray-500 dark:text-gray-400">
                                    vs {card.previousPeriodLabel}
                                </p>
                                <div
                                    className={`flex items-center gap-1 px-2 py-1 rounded-full text-xs font-semibold ${card.changeDirection === "up"
                                            ? "bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400"
                                            : card.changeDirection === "down"
                                                ? "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400"
                                                : "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400"
                                        }`}
                                >
                                    {card.changeDirection === "up" ? (
                                        <TrendingUp size={14} />
                                    ) : card.changeDirection === "down" ? (
                                        <TrendingDown size={14} />
                                    ) : null}
                                    <span>
                                        {card.changePercent > 0 ? "+" : ""}
                                        {card.changePercent.toFixed(1)}%
                                    </span>
                                </div>
                            </div>
                            <p className="text-xs text-gray-500 dark:text-gray-400">
                                Previous: {card.previousValue}
                            </p>
                        </div>
                    )}

                    {/* Status Label */}
                    {card.changePercent !== null && (
                        <div className="mt-3 text-xs font-medium text-gray-600 dark:text-gray-400">
                            {card.changeDirection === "up" && (
                                <span className="text-green-600 dark:text-green-400">
                                    ↑ Improved
                                </span>
                            )}
                            {card.changeDirection === "down" && (
                                <span className="text-red-600 dark:text-red-400">
                                    ↓ Declined
                                </span>
                            )}
                            {card.changeDirection === "stable" && (
                                <span className="text-gray-600 dark:text-gray-400">
                                    → No Change
                                </span>
                            )}
                        </div>
                    )}
                </div>
            ))}
        </div>
    );
};

export default TrendComparisonCards;
