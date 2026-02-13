import React, { useState, useMemo } from "react";
import Chart from "react-apexcharts";
import { ChevronDown } from "lucide-react";

interface TrendAnalysisChartProps {
  companyName: string;
  ratioData: any[];
  periods: any[];
}

const RATIO_CATEGORIES = {
  "Trading Ratios": [
    "stock_turnover",
    "gross_profit_ratio",
    "net_profit_ratio",
  ],
  "Fund Structure": [
    "own_fund_to_wf",
    "deposits_to_wf",
    "borrowings_to_wf",
    "loans_to_wf",
    "investments_to_wf",
  ],
  "Yield & Cost": [
    "cost_of_deposits",
    "yield_on_loans",
    "yield_on_investments",
    "credit_deposit_ratio",
    "avg_cost_of_wf",
    "avg_yield_on_wf",
  ],
  "Margin Analysis": [
    "gross_fin_margin",
    "operating_cost_to_wf",
    "net_fin_margin",
    "risk_cost_to_wf",
    "net_margin",
  ],
};

const formatRatioName = (name: string): string => {
  return name
    .split("_")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
};

const TrendAnalysisChart: React.FC<TrendAnalysisChartProps> = ({
  companyName,
  ratioData,
  periods,
}) => {
  const [selectedCategory, setSelectedCategory] = useState<string>(
    "Trading Ratios"
  );
  const [selectedRatios, setSelectedRatios] = useState<string[]>(
    RATIO_CATEGORIES["Trading Ratios"] || []
  );
  const [chartType, setChartType] = useState<"line" | "bar">("line");
  const [expandedDropdown, setExpandedDropdown] = useState(false);
  const [selectedPeriods, setSelectedPeriods] = useState<number[]>(
    periods.map((p: any) => p.id)
  );

  // Sort periods by date for correct chronological order
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

    const series = selectedRatios.map((ratioName) => ({
      name: formatRatioName(ratioName),
      data: sortedData.map((data: any) => {
        const value = data[ratioName];
        if (value === null || value === undefined) return 0;
        const numValue = typeof value === 'number' ? value : parseFloat(value);
        return !isNaN(numValue) ? parseFloat(numValue.toFixed(2)) : 0;
      }),
    }));

    return { categories, series };
  }, [sortedData, selectedRatios, periods]);

  if (!chartData || chartData.series.length === 0) {
    return (
      <div className="p-8 bg-gray-50 dark:bg-gray-800 rounded-lg text-center">
        <p className="text-gray-600 dark:text-gray-400">
          Insufficient data to display trends. Please ensure multiple periods are available.
        </p>
      </div>
    );
  }

  const chartOptions: ApexCharts.ApexOptions = {
    chart: {
      type: chartType,
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
      width: chartType === "line" ? 2 : 0,
    },
    xaxis: {
      categories: chartData.categories,
      labels: {
        style: {
          colors: "#6B7280",
          fontSize: "12px",
        },
      },
    },
    yaxis: {
      labels: {
        style: {
          colors: "#6B7280",
          fontSize: "12px",
        },
      },
    },
    tooltip: {
      theme: document.documentElement.classList.contains("dark")
        ? "dark"
        : "light",
      y: {
        formatter: (value) => value?.toFixed(2) || "0.00",
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
    },
  };

  return (
    <div className="space-y-6">
      {/* Controls */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          Ratio Trend Analysis - {companyName}
        </h3>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Category Selector */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Category
            </label>
            <select
              value={selectedCategory}
              onChange={(e) => {
                setSelectedCategory(e.target.value);
                setSelectedRatios(
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
            <div className="flex gap-2">
              <button
                onClick={() => setChartType("line")}
                className={`flex-1 px-4 py-2 rounded-lg font-medium transition ${
                  chartType === "line"
                    ? "bg-blue-500 text-white"
                    : "bg-gray-200 dark:bg-gray-700 text-gray-900 dark:text-white hover:bg-gray-300 dark:hover:bg-gray-600"
                }`}
              >
                Line
              </button>
              <button
                onClick={() => setChartType("bar")}
                className={`flex-1 px-4 py-2 rounded-lg font-medium transition ${
                  chartType === "bar"
                    ? "bg-blue-500 text-white"
                    : "bg-gray-200 dark:bg-gray-700 text-gray-900 dark:text-white hover:bg-gray-300 dark:hover:bg-gray-600"
                }`}
              >
                Bar
              </button>
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
                  className={`w-4 h-4 transition-transform ${
                    expandedDropdown ? "rotate-180" : ""
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
                              setSelectedRatios([...selectedRatios, ratioName]);
                            } else {
                              setSelectedRatios(
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
        {selectedRatios.length > 0 && selectedPeriods.length > 0 ? (
          <Chart
            options={chartOptions}
            series={chartData.series}
            type={chartType}
            height={400}
          />
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

      {/* Statistics Summary */}
      {selectedRatios.length > 0 && selectedPeriods.length > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {selectedRatios.map((ratioName) => {
            const values = sortedData
              .map((data: any) => {
                const val = data[ratioName];
                if (val === null || val === undefined) return null;
                const numVal = typeof val === 'number' ? val : parseFloat(val);
                return isNaN(numVal) ? null : numVal;
              })
              .filter((v) => v !== null);

            if (values.length === 0) return null;

            const latest = values[values.length - 1];
            const initial = values[0];
            const change = latest - initial;
            const percentChange = initial !== 0 ? (change / initial) * 100 : 0;
            const avg = values.reduce((a, b) => a + b, 0) / values.length;
            const max = Math.max(...values);
            const min = Math.min(...values);

            return (
              <div
                key={ratioName}
                className="bg-white dark:bg-gray-800 rounded-lg shadow p-4"
              >
                <h4 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
                  {formatRatioName(ratioName)}
                </h4>
                <div className="space-y-2 text-xs">
                  <div className="flex justify-between">
                    <span className="text-gray-600 dark:text-gray-400">Latest:</span>
                    <span className="font-semibold text-gray-900 dark:text-white">
                      {latest.toFixed(2)}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600 dark:text-gray-400">Change:</span>
                    <span
                      className={`font-semibold ${
                        change >= 0 ? "text-green-600" : "text-red-600"
                      }`}
                    >
                      {change >= 0 ? "+" : ""}{change.toFixed(2)} ({percentChange.toFixed(1)}%)
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600 dark:text-gray-400">Avg:</span>
                    <span className="font-semibold text-gray-900 dark:text-white">
                      {avg.toFixed(2)}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600 dark:text-gray-400">Min-Max:</span>
                    <span className="font-semibold text-gray-900 dark:text-white">
                      {min.toFixed(2)} - {max.toFixed(2)}
                    </span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};

export default TrendAnalysisChart;
