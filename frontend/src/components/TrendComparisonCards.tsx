import React, { useMemo } from "react";

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
    selectedRatios: string[];
}

const formatRatioName = (name: string): string => {
    return name
        .split("_")
        .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
        .join(" ");
};

const TrendComparisonCards: React.FC<TrendComparisonCardsProps> = ({
    ratioData,
    periods,
    selectedRatios,
}) => {
    const comparisonData = useMemo(() => {
        if (!ratioData || !periods || ratioData.length === 0 || selectedRatios.length === 0) {
            return [];
        }

        const periodMap = new Map();
        periods.forEach((period) => {
            periodMap.set(period.id, period);
        });

        return selectedRatios.map(ratioKey => {
            const sortedPeriodData = [...ratioData]
                .filter((data) => data[ratioKey] !== undefined && data[ratioKey] !== null && data[ratioKey] !== "")
                .sort((a, b) => {
                    const aDate = new Date(periodMap.get(a.period)?.start_date || "");
                    const bDate = new Date(periodMap.get(b.period)?.start_date || "");
                    return aDate.getTime() - bDate.getTime();
                })
                .map((current, index, array) => {
                    const currentPeriod = periodMap.get(current.period);
                    const currentValue = parseFloat(current[ratioKey]) || 0;
                    const previousRatio = index > 0 ? array[index - 1] : null;
                    const previousValue = previousRatio
                        ? parseFloat(previousRatio[ratioKey]) || 0
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
                        value: currentValue.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }),
                        changePercent: changePercent !== null ? Math.abs(changePercent).toFixed(1) : null,
                        changeDirection: changeDirection,
                    };
                }); // Oldest to newest

            return {
                ratioLabel: formatRatioName(ratioKey),
                periodsData: sortedPeriodData
            };
        }).filter(item => item !== null);
    }, [ratioData, periods, selectedRatios]);

    if (comparisonData.length === 0) {
        return (
            <div className="text-center p-8 text-gray-500 dark:text-gray-400">
                No data available for comparison
            </div>
        );
    }

    return (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-3 gap-6">
            {comparisonData.map((card, index) => (
                <div
                    key={index}
                    className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-5 border border-gray-100 dark:border-gray-700 hover:border-blue-200 dark:hover:border-blue-900 transition-colors"
                >
                    <h3 className="text-sm font-extrabold text-blue-900 dark:text-blue-100 mb-6 border-b border-gray-50 dark:border-gray-700 pb-2 uppercase tracking-wide">
                        {card.ratioLabel}
                    </h3>

                    <div className="space-y-4">
                        {card.periodsData.map((data, pIndex) => (
                            <div key={pIndex} className="flex justify-between items-center group">
                                <span className="text-[12px] font-bold text-gray-500 dark:text-gray-400 group-hover:text-gray-700 dark:group-hover:text-gray-200 transition-colors">
                                    {data.periodLabel}
                                </span>
                                <div className="flex items-center gap-3">
                                    <span className="text-[14px] font-extrabold text-gray-900 dark:text-white">
                                        {data.value}
                                    </span>
                                    {data.changePercent !== null && (
                                        <span className={`text-[11px] font-bold flex items-center gap-1 ${data.changeDirection === 'up'
                                                ? 'text-green-600 dark:text-green-400'
                                                : data.changeDirection === 'down'
                                                    ? 'text-red-600 dark:text-red-400'
                                                    : 'text-gray-400 dark:text-gray-500'
                                            }`}>
                                            ({data.changePercent}% {data.changeDirection === 'up' ? 'Up' : data.changeDirection === 'down' ? 'Dip' : 'Stable'})
                                        </span>
                                    )}
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            ))}
        </div>
    );
};

export default TrendComparisonCards;
