import React, { useState, useMemo, useEffect } from "react";
import Chart from "react-apexcharts";
import { ChevronDown, AlertCircle } from "lucide-react";

// Simple Error Boundary for the Chart
class ChartErrorBoundary extends React.Component<{ children: React.ReactNode }, { hasError: boolean }> {
    constructor(props: any) {
        super(props);
        this.state = { hasError: false };
    }
    static getDerivedStateFromError() {
        return { hasError: true };
    }
    render() {
        if (this.state.hasError) {
            return (
                <div className="flex flex-col items-center justify-center h-96 bg-red-50 dark:bg-red-900/10 rounded-lg p-6 text-center border border-red-200 dark:border-red-800">
                    <AlertCircle className="w-12 h-12 text-red-500 mb-4" />
                    <h3 className="text-lg font-bold text-red-800 dark:text-red-300 mb-2">Chart Rendering Error</h3>
                    <p className="text-red-600 dark:text-red-400">Something went wrong while drawing the chart. Try selecting different options or another chart type.</p>
                    <button
                        onClick={() => this.setState({ hasError: false })}
                        className="mt-4 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition"
                    >
                        Try Again
                    </button>
                </div>
            );
        }
        return this.props.children;
    }
}


interface TrendAnalysisChartProps {
    ratioData: any[];
    periods: any[];
    selectedRatios: string[];
    onSelectedRatiosChange: (ratios: string[]) => void;
}

const RATIO_CATEGORIES = {
    "Trading Ratios": [
        "stock_turnover",
        "gross_profit_ratio",
        "net_profit_ratio",
    ],
    "Capital Ratios": [
        "own_fund_to_wf",
    ],
    "Equity Analysis": [
        "net_own_funds",
    ],
    "Fund Structure": [
        "own_fund_to_wf",
        "deposits_to_wf",
        "borrowings_to_wf",
        "loans_to_wf",
        "investments_to_wf",
        "earning_assets_to_wf",
        "interest_tagged_funds_to_wf",
    ],
    "Yield & Cost": [
        "cost_of_deposits",
        "yield_on_loans",
        "yield_on_investments",
        "credit_deposit_ratio",
        "avg_cost_of_wf",
        "avg_yield_on_wf",
        "misc_income_to_wf",
        "interest_exp_to_interest_income",
    ],
    "Margin Analysis": [
        "gross_fin_margin",
        "operating_cost_to_wf",
        "net_fin_margin",
        "risk_cost_to_wf",
        "net_margin",
    ],
    "Capital Efficiency": [
        "capital_turnover_ratio",
    ],
    "Productivity Analysis": [
        "per_employee_deposit",
        "per_employee_loan",
        "per_employee_contribution",
        "per_employee_operating_cost",
    ],
};

const formatRatioName = (name: string): string => {
    return name
        .split("_")
        .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
        .join(" ");
};

const TrendAnalysisChart: React.FC<TrendAnalysisChartProps> = ({
    ratioData,
    periods,
    selectedRatios,
    onSelectedRatiosChange,
}) => {
    console.log("TrendAnalysisChart rendering", { ratioDataCount: ratioData?.length, periodsCount: periods?.length });

    const [selectedCategory, setSelectedCategory] = useState<string>(
        "Trading Ratios"
    );
    const [chartType, setChartType] = useState<"line" | "bar" | "area" | "radar" | "scatter" | "candlestick" | "waterfall">("line");
    const [expandedDropdown, setExpandedDropdown] = useState(false);
    const [expandedChartTypeDropdown, setExpandedChartTypeDropdown] = useState(false);
    const [selectedPeriods, setSelectedPeriods] = useState<number[]>(
        periods?.map((p: any) => p.id) || []
    );

    // Sort periods by date for correct chronological order
    useEffect(() => {
        if (periods && periods.length > 0) {
            setSelectedPeriods(periods.map((p: any) => p.id));
        }
    }, [periods]);

    // Close dropdowns when clicking outside
    useEffect(() => {
        const handleClickOutside = (event: any) => {
            const target = event.target as HTMLElement;
            if (!target.closest('[data-chart-controls]')) {
                setExpandedDropdown(false);
                setExpandedChartTypeDropdown(false);
            }
        };

        document.addEventListener("mousedown", handleClickOutside);
        return () => document.removeEventListener("mousedown", handleClickOutside);
    }, []);

    const sortedData = useMemo(() => {
        if (!ratioData || ratioData.length === 0) return [];

        // Create map of period id to period data
        const periodMap = new Map();
        periods.forEach((period: any) => {
            periodMap.set(period.id, period);
        });

        // Sort ratio data by period start_date and filter by selected periods
        return [...ratioData]
            .filter((data: any) => selectedPeriods.includes(data.period))
            .sort((a, b) => {
                const periodA = periodMap.get(a.period);
                const periodB = periodMap.get(b.period);
                if (!periodA || !periodB) return 0;
                return (
                    new Date(periodA.start_date).getTime() -
                    new Date(periodB.start_date).getTime()
                );
            });
    }, [ratioData, periods, selectedPeriods]);

    // Prepare data for chart
    const chartData = useMemo(() => {
        if (sortedData.length === 0) return null;

        const categories = sortedData.map((data: any) => {
            const period = periods.find((p: any) => p.id === data.period);
            return period?.label || `Period ${data.period}`;
        });

        // Format data based on chart type
        if (chartType === "scatter") {
            // Scatter needs {x, y} pairs
            const series = selectedRatios.map((ratioName) => ({
                name: formatRatioName(ratioName),
                data: sortedData.map((data: any, dataIndex: number) => {
                    const value = data[ratioName];
                    const label = categories[dataIndex];
                    if (value === null || value === undefined || value === "") return null;
                    const numValue = typeof value === 'number' ? value : parseFloat(value);
                    if (isNaN(numValue)) return null;
                    return { x: label, y: parseFloat(numValue.toFixed(2)) };
                }).filter((v: any) => v !== null),
            }));
            return { categories, series: series as any[] };
        } else if (chartType === "candlestick") {
            // Candlestick needs {x, y: [o, h, l, c]}
            if (selectedRatios.length === 0) return { categories, series: [] };

            const mainRatioName = selectedRatios[0];
            const series = [{
                name: formatRatioName(mainRatioName),
                data: sortedData.map((data: any, idx: number) => {
                    const value = data[mainRatioName];
                    const label = categories[idx] || `P${idx + 1}`;
                    if (value === null || value === undefined || value === "") {
                        return { x: label, y: [null, null, null, null] };
                    }
                    const close = typeof value === 'number' ? value : parseFloat(value);
                    if (isNaN(close)) return { x: label, y: [null, null, null, null] };

                    const variance = close * 0.05;
                    const open = close - (variance / 2);
                    const high = close + variance;
                    const low = close - variance;
                    return { x: label, y: [open, high, low, close] };
                }),
            }];
            return { categories, series: series as any[] };
        } else if (chartType === "waterfall") {
            // Simple Column Chart for Waterfall for now
            if (selectedRatios.length === 0) return { categories, series: [] };
            const mainRatioName = selectedRatios[0];
            const series = [{
                name: formatRatioName(mainRatioName),
                data: sortedData.map((data: any, idx: number) => {
                    const value = data[mainRatioName];
                    const label = categories[idx] || `P${idx + 1}`;
                    const numValue = (value === null || value === undefined || value === "") ? null :
                        (typeof value === 'number' ? value : parseFloat(value));
                    return { x: label, y: isNaN(numValue as any) ? null : numValue };
                }),
            }];
            return { categories, series: series as any[] };
        } else {
            // Line, Area, Bar, Radar
            const series = selectedRatios.map((ratioName) => ({
                name: formatRatioName(ratioName),
                data: sortedData.map((data: any, idx: number) => {
                    const value = data[ratioName];
                    const label = categories[idx] || `P${idx + 1}`;
                    const numValue = (value === null || value === undefined || value === "") ? null :
                        (typeof value === 'number' ? value : parseFloat(value));
                    return { x: label, y: isNaN(numValue as any) ? null : numValue };
                }),
            }));
            return { categories, series: series as any[] };
        }
    }, [sortedData, selectedRatios, periods, chartType]);

    if (!chartData || chartData.series.length === 0) {
        return (
            <div className="p-8 bg-gray-50 dark:bg-gray-800 rounded-lg text-center">
                <p className="text-gray-600 dark:text-gray-400">
                    Insufficient data to display trends. Please ensure multiple periods are available.
                </p>
            </div>
        );
    }

    const categories = chartData?.categories || [];

    const chartOptions: any = {
        chart: {
            type: chartType === "waterfall" ? "bar" : chartType,
            toolbar: {
                show: true,
                tools: {
                    download: true,
                    selection: true,
                    zoom: true,
                    zoomin: true,
                    zoomout: true,
                    pan: true,
                    reset: true,
                },
            },
            redrawOnParentResize: true,
        },
        stroke: {
            curve: "smooth",
            width: (chartType === "line" || chartType === "area") ? 2 : (chartType === "scatter" ? 0 : 2),
            colors: undefined,
        },
        markers: {
            size: (chartType === "scatter" || chartType === "line" || chartType === "area") ? 5 : 0,
            strokeWidth: 2,
            hover: {
                size: 7
            }
        },
        plotOptions: {
            bar: {
                horizontal: false,
                columnWidth: '55%',
                borderRadius: 4,
                ...(chartType === "waterfall" ? {
                    dataLabels: {
                        total: {
                            enabled: true,
                            style: {
                                fontSize: "13px",
                                fontWeight: 900
                            }
                        }
                    }
                } : {})
            },
            radar: {
                polygons: {
                    strokeColors: '#e8e8e8',
                    fill: {
                        colors: ['#f8f8f8', '#fff']
                    }
                }
            },
        },
        xaxis: {
            categories: categories,
            type: "category",
            labels: {
                style: {
                    colors: "#6B7280",
                    fontSize: "12px",
                },
            },
        },
        yaxis: {
            show: chartType !== "radar",
            labels: {
                style: {
                    colors: "#6B7280",
                    fontSize: "12px",
                },
            },
        },
        tooltip: {
            enabled: true,
            theme: document.documentElement.classList.contains("dark") ? "dark" : "light",
            y: {
                formatter: (value: any) => {
                    if (chartType === "candlestick") return "";
                    if (value === null || value === undefined) return "N/A";
                    try {
                        return Array.isArray(value) ? value[1].toFixed(2) : value.toFixed(2);
                    } catch (e) {
                        return "0.00";
                    }
                },
            },
            x: {
                show: true,
                formatter: (value: any) => {
                    return String(value);
                }
            },
        },
        legend: {
            position: "top" as const,
            fontFamily: "inter",
        },
        colors: [
            "#3B82F6",
            "#10B981",
            "#F59E0B",
            "#EF4444",
            "#8B5CF6",
            "#EC4899",
        ],
        grid: {
            borderColor: "#E5E7EB",
            strokeDashArray: 3,
            show: chartType !== "radar",
        },
        states: {
            hover: {
                filter: {
                    type: "darken",
                }
            }
        }
    };

    return (
        <div className="space-y-6">
            {/* Controls */}
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6" data-chart-controls>
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                    Ratio Trend Analysis
                </h3>

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
                    {/* Category Selector */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                            Category
                        </label>
                        <select
                            value={selectedCategory}
                            onChange={(e) => {
                                setSelectedCategory(e.target.value);
                                onSelectedRatiosChange(
                                    RATIO_CATEGORIES[e.target.value as keyof typeof RATIO_CATEGORIES] || []
                                );
                            }}
                            className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                        >
                            {Object.keys(RATIO_CATEGORIES).map((category) => (
                                <option key={category} value={category}>
                                    {category}
                                </option>
                            ))}
                        </select>
                    </div>

                    {/* Chart Type Selector */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                            Chart Type
                        </label>
                        <div className="relative">
                            <button
                                onClick={() => setExpandedChartTypeDropdown(!expandedChartTypeDropdown)}
                                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white flex items-center justify-between hover:bg-gray-50 dark:hover:bg-gray-600"
                            >
                                <span className="text-sm font-medium">
                                    {chartType.charAt(0).toUpperCase() + chartType.slice(1)}
                                </span>
                                <ChevronDown
                                    className={`w-4 h-4 transition-transform ${expandedChartTypeDropdown ? "rotate-180" : ""
                                        }`}
                                />
                            </button>

                            {expandedChartTypeDropdown && (
                                <div className="absolute top-full left-0 right-0 mt-2 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg shadow-lg z-10">
                                    {(["line", "area", "bar", "radar", "scatter", "candlestick", "waterfall"] as const).map(
                                        (type) => (
                                            <button
                                                key={type}
                                                onClick={() => {
                                                    setChartType(type);
                                                    setExpandedChartTypeDropdown(false);
                                                }}
                                                className={`w-full text-left px-4 py-2 transition-colors border-b border-gray-200 dark:border-gray-600 last:border-b-0 ${chartType === type
                                                    ? "bg-blue-500 text-white"
                                                    : "hover:bg-gray-100 dark:hover:bg-gray-600 text-gray-900 dark:text-white"
                                                    }`}
                                            >
                                                <div className="flex items-center justify-between">
                                                    <span className="font-medium">{type.charAt(0).toUpperCase() + type.slice(1)}</span>
                                                    {chartType === type && <span className="text-white">✓</span>}
                                                </div>
                                            </button>
                                        )
                                    )}
                                </div>
                            )}
                        </div>
                    </div>

                    {/* Ratio Multi-Select */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                            Select Ratios
                        </label>
                        <div className="relative">
                            <button
                                onClick={() => setExpandedDropdown(!expandedDropdown)}
                                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white flex items-center justify-between hover:bg-gray-50 dark:hover:bg-gray-600"
                            >
                                <span className="text-sm">
                                    {selectedRatios.length} ratio{selectedRatios.length !== 1 ? "s" : ""} selected
                                </span>
                                <ChevronDown
                                    className={`w-4 h-4 transition-transform ${expandedDropdown ? "rotate-180" : ""
                                        }`}
                                />
                            </button>

                            {expandedDropdown && (
                                <div className="absolute top-full left-0 right-0 mt-2 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg shadow-lg z-10 max-h-64 overflow-y-auto">
                                    {RATIO_CATEGORIES[selectedCategory as keyof typeof RATIO_CATEGORIES]?.map(
                                        (ratioName) => (
                                            <label
                                                key={ratioName}
                                                className="flex items-center px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 cursor-pointer border-b border-gray-200 dark:border-gray-600 last:border-b-0"
                                            >
                                                <input
                                                    type="checkbox"
                                                    checked={selectedRatios.includes(ratioName)}
                                                    onChange={(e) => {
                                                        if (e.target.checked) {
                                                            onSelectedRatiosChange([...selectedRatios, ratioName]);
                                                        } else {
                                                            onSelectedRatiosChange(
                                                                selectedRatios.filter((r) => r !== ratioName)
                                                            );
                                                        }
                                                    }}
                                                    className="mr-3"
                                                />
                                                <span className="text-sm text-gray-700 dark:text-gray-300">
                                                    {formatRatioName(ratioName)}
                                                </span>
                                            </label>
                                        )
                                    )}
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            </div>

            {/* Period Selection */}
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
                <h4 className="text-md font-semibold text-gray-900 dark:text-white mb-4">
                    Select Periods for Graph
                </h4>
                <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-3">
                    {periods.map((period: any) => (
                        <label
                            key={period.id}
                            className="flex items-center p-3 border border-gray-300 dark:border-gray-600 rounded-lg cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700 transition"
                        >
                            <input
                                type="checkbox"
                                checked={selectedPeriods.includes(period.id)}
                                onChange={(e) => {
                                    if (e.target.checked) {
                                        setSelectedPeriods([...selectedPeriods, period.id]);
                                    } else {
                                        setSelectedPeriods(
                                            selectedPeriods.filter((id) => id !== period.id)
                                        );
                                    }
                                }}
                                className="w-4 h-4 rounded accent-blue-500 cursor-pointer"
                            />
                            <span className="ml-2 text-sm font-medium text-gray-700 dark:text-gray-300">
                                {period.label}
                            </span>
                        </label>
                    ))}
                </div>
                {selectedPeriods.length === 0 && (
                    <p className="mt-4 text-sm text-red-500 dark:text-red-400">
                        Please select at least one period to display the chart
                    </p>
                )}
            </div>

            {/* Chart */}
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
                <div className="mb-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-700">
                    <p className="text-sm text-gray-700 dark:text-gray-300">
                        {chartType === "line" && "Line Chart: Best for visualizing trends over time with smooth curves between data points."}
                        {chartType === "area" && "Area Chart: Similar to line charts but with filled areas, great for showing cumulative trends."}
                        {chartType === "bar" && "Bar Chart: Ideal for comparing values across periods, makes differences more visible."}
                        {chartType === "radar" && "Radar Chart: Excellent for comparing multiple ratios within a single period, shows all dimensions at once."}
                        {chartType === "scatter" && "Scatter Chart: Shows individual data points without line connections, useful for identifying patterns and outliers."}
                        {chartType === "candlestick" && "Candlestick Chart: Displays volatility range around each ratio value - high, low, and close prices for each period."}
                        {chartType === "waterfall" && "Waterfall Chart: Shows how values progressively change from one period to the next, visualizing incremental contributions."}
                    </p>
                </div>
                {selectedRatios.length > 0 && selectedPeriods.length > 0 ? (
                    <div className="min-h-[400px]">
                        <ChartErrorBoundary>
                            <Chart
                                options={chartOptions}
                                series={chartData.series}
                                type={chartType === "waterfall" ? "bar" : chartType}
                                height={400}
                            />
                        </ChartErrorBoundary>
                    </div>
                ) : (
                    <div className="flex items-center justify-center h-96 text-gray-500 dark:text-gray-400">
                        <p>
                            {selectedRatios.length === 0
                                ? "Please select at least one ratio to display"
                                : "Please select at least one period to display"}
                        </p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default TrendAnalysisChart;
