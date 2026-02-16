import { useEffect, useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import { createApiUrl, getAuthHeaders } from "../../access/access.ts";
import ReactApexChart from "react-apexcharts";
import {

    LucideFileText,
    LucideTrendingUp,
    LucideCheckCircle,
    LucideActivity,
    LucideDownload,
    LucidePrinter,
    LucideRefreshCw,
    LucideArrowUpRight,
    LucideArrowDownRight,
    LucidePercent,
    LucideTrophy,
    LucidePlus
} from "lucide-react";

import { FinancialPeriodData } from "../FinancialStatements/api";
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

const MasterDashboard = () => {
    const navigate = useNavigate();
    const [periods, setPeriods] = useState<FinancialPeriodData[]>([]);
    const [dashboardData, setDashboardData] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [refreshing, setRefreshing] = useState(false);
    const [showExportMenu, setShowExportMenu] = useState(false);
    const exportMenuRef = useRef<HTMLDivElement>(null);

    // Close export menu when clicking outside
    useEffect(() => {
        function handleClickOutside(event: MouseEvent) {
            if (exportMenuRef.current && !exportMenuRef.current.contains(event.target as Node)) {
                setShowExportMenu(false);
            }
        }
        document.addEventListener("mousedown", handleClickOutside);
        return () => document.removeEventListener("mousedown", handleClickOutside);
    }, []);

    const [filterType, setFilterType] = useState<string>("");
    const [filterLoading, setFilterLoading] = useState(false);

    // Fetch aggregated dashboard data and periods
    const fetchFilteredData = async (periodType?: string) => {
        try {
            setFilterLoading(true);

            // Build params for dashboard API
            const params: any = {};

            // period parameter: 'all' or specific period type
            if (periodType) {
                params.period = periodType;
            } else {
                params.period = 'all';
            }

            // Fetch aggregated dashboard data from the new endpoint
            const url = createApiUrl("api/dashboard/");
            const response = await axios.get(url, {
                headers: await getAuthHeaders(),
                params,
            });

            const dashData = response.data.data;
            setDashboardData(dashData);

            // Process periods from dashboard data
            const extractedPeriods: FinancialPeriodData[] = [];
            if (dashData?.periods) {
                // Assuming backend returns periods list directly now
                // We need to map it to FinancialPeriodData structure if needed, or use as is if it matches
                // The extraction logic depends on exact backend response.
                // Based on previous backend edit: "periods" is a list.
                extractedPeriods.push(...dashData.periods.map((p: any) => ({
                    ...p,
                    trading_account: p.trading_account || { sales: 0 }, // Ensure minimal structure
                    profit_loss: p.profit_loss || { net_profit: 0 }
                })));
            }

            setPeriods(extractedPeriods);
        } catch (error) {
            console.error("Error loading filtered data:", error);
            setDashboardData(null);
        } finally {
            setFilterLoading(false);
        }
    };

    useEffect(() => {
        fetchData();
    }, []);

    // Fetch periods whenever filters change (including "all" which means no specific filter)
    useEffect(() => {
        // Always fetch when filters change - even if both are empty (meaning "all")
        fetchFilteredData(filterType);
    }, [filterType]);

    const fetchData = async () => {
        try {
            setLoading(true);
            // Only fetch periods initially
            setPeriods([]); // Start with no periods
        } catch (error) {
            console.error("Error loading dashboard data:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleRefresh = async () => {
        setRefreshing(true);
        await fetchData();
        setRefreshing(false);
    };

    // --- Calculations with Filtering ---

    // Apply filters - API already filters, but we use this for reference
    const filteredPeriods = periods; // Already filtered from API

    // Total companies removed
    // const totalCompanies = dashboardData?.company_data?.length || 0;
    // Note: Calculations use filteredPeriods not periods for the dashboard stats
    // Wait, my Step 299 code used filteredPeriods for revenue, profit etc.
    // But Activity Timeline uses ALL periods (slice 0,5).
    // Let's stick to Step 299 logic.

    const totalPeriods = filteredPeriods.length;
    const finalizedPeriods = filteredPeriods.filter((p) => p.is_finalized).length;

    // Calculate total revenue across filters
    const totalRevenue = dashboardData?.total_revenue || 0;

    // Calculate total profit across filters (sum from extracted periods)
    const totalProfit = filteredPeriods.reduce((sum, p) => {
        const profit = p.profit_loss?.net_profit;
        const profitNum = typeof profit === 'string' ? parseFloat(profit) : profit;
        return sum + (typeof profitNum === 'number' && !isNaN(profitNum) ? profitNum : 0);
    }, 0);

    // Calculate average profit margin (use backend pre-calculated value)
    const avgProfitMargin = dashboardData?.avg_profit_margin || 0;

    // Calculate growth rate (use backend pre-calculated value)
    const growthRate = dashboardData?.growth_rate || 0;

    // For backward compatibility with chart calculations
    const periodsWithProfit = filteredPeriods.filter((p) => {
        const profit = p.profit_loss?.net_profit;
        const profitNum = typeof profit === 'string' ? parseFloat(profit) : profit;
        return typeof profitNum === 'number' && !isNaN(profitNum);
    });

    // Helper function to format currency
    const formatCurrency = (value: number) => {
        if (isNaN(value) || !isFinite(value)) return '0.00';
        return (value / 1000000).toFixed(2);
    };

    // Helper function to format percentage
    const formatPercentage = (value: number) => {
        if (isNaN(value) || !isFinite(value)) return '0.0';
        // Avoid -0.0 display
        const rounded = Math.abs(value) < 0.05 ? 0 : value;
        return rounded.toFixed(1);
    };



    // Top Performers Logic (Removed or updated to Top Periods)
    const topPeriods = [...filteredPeriods]
        .sort((a, b) => {
            const profitA = typeof a.profit_loss?.net_profit === 'number' ? a.profit_loss.net_profit : parseFloat(a.profit_loss?.net_profit || "0");
            const profitB = typeof b.profit_loss?.net_profit === 'number' ? b.profit_loss.net_profit : parseFloat(b.profit_loss?.net_profit || "0");
            return profitB - profitA;
        })
        .slice(0, 5);

    // --- Export Functions ---

    const getExportData = () => {
        return filteredPeriods.map(p => ({
            Label: p.label,
            Type: p.period_type,
            StartDate: p.start_date,
            EndDate: p.end_date,
            Status: p.is_finalized ? "Finalized" : "Draft",
            Revenue: typeof p.trading_account?.sales === 'string' ? parseFloat(p.trading_account.sales) : (p.trading_account?.sales || 0),
            NetProfit: typeof p.profit_loss?.net_profit === 'string' ? parseFloat(p.profit_loss.net_profit) : (p.profit_loss?.net_profit || 0)
        }));
    };

    const handleExportCSV = () => {
        const data = getExportData();
        if (data.length === 0) return;

        const headers = Object.keys(data[0]);
        const rows = data.map(row => Object.values(row).map(v => JSON.stringify(v)).join(","));
        const csvContent = [headers.join(","), ...rows].join("\n");

        const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
        const link = document.createElement("a");
        link.href = URL.createObjectURL(blob);
        link.download = `financial_data_${new Date().toISOString().split('T')[0]}.csv`;
        link.click();
        setShowExportMenu(false);
    };

    const handleExportExcel = () => {
        const data = getExportData();
        if (data.length === 0) return;

        const ws = XLSX.utils.json_to_sheet(data);
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, "Financial Data");
        XLSX.writeFile(wb, `financial_data_${new Date().toISOString().split('T')[0]}.xlsx`);
        setShowExportMenu(false);
    };

    const handleExportPDF = () => {
        const data = getExportData();
        if (data.length === 0) return;

        const doc = new jsPDF();
        doc.text("Financial Dashboard Report", 14, 15);
        doc.text(`Generated: ${new Date().toLocaleDateString()}`, 14, 22);

        const tableData = data.map(row => [
            row.Label,
            row.Type,
            row.StartDate,
            row.Status,
            row.Revenue.toFixed(2),
            row.NetProfit.toFixed(2)
        ]);

        autoTable(doc, {
            head: [['Label', 'Type', 'Start', 'Status', 'Revenue', 'Net Profit']],
            body: tableData,
            startY: 30,
        });

        doc.save(`financial_report_${new Date().toISOString().split('T')[0]}.pdf`);
        setShowExportMenu(false);
    };

    const handleExportWord = () => {
        const data = getExportData();
        if (data.length === 0) return;

        const tableRows = data.map(row => `
      <tr>
        <td>${row.Label}</td>
        <td>${row.Type}</td>
        <td>${row.StartDate}</td>
        <td>${row.Status}</td>
        <td>${row.Revenue.toFixed(2)}</td>
        <td>${row.NetProfit.toFixed(2)}</td>
      </tr>
    `).join('');

        const content = `
      <html xmlns:o='urn:schemas-microsoft-com:office:office' xmlns:w='urn:schemas-microsoft-com:office:word' xmlns='http://www.w3.org/TR/REC-html40'>
      <head><meta charset='utf-8'><title>Export HTML To Doc</title></head>
      <body>
        <h2>Financial Dashboard Report</h2>
        <p>Generated: ${new Date().toLocaleDateString()}</p>
        <table border="1" style="border-collapse:collapse;width:100%">
          <thead>
            <tr style="background-color:#f2f2f2">
              <th>Label</th><th>Type</th><th>Start Date</th><th>Status</th><th>Revenue</th><th>Net Profit</th>
            </tr>
          </thead>
          <tbody>
            ${tableRows}
          </tbody>
        </table>
      </body>
      </html>
    `;

        const blob = new Blob([content], { type: 'application/msword' });
        const link = document.createElement("a");
        link.href = URL.createObjectURL(blob);
        link.download = `financial_report_${new Date().toISOString().split('T')[0]}.doc`;
        link.click();
        setShowExportMenu(false);
    };

    const handlePrint = () => {
        window.print();
    };

    // --- Chart Data Preparation ---

    // Period Types Distribution
    const periodTypeCounts = filteredPeriods.reduce((acc, curr) => {
        acc[curr.period_type] = (acc[curr.period_type] || 0) + 1;
        return acc;
    }, {} as Record<string, number>);

    const pieChartOptions: ApexCharts.ApexOptions = {
        chart: { type: "donut", fontFamily: "inherit", background: 'transparent' },
        theme: { mode: 'light' },
        labels: Object.keys(periodTypeCounts).map((key) =>
            key.replace("_", " ").toLowerCase().replace(/\b\w/g, (c) => c.toUpperCase())
        ),
        colors: ["#3C50E0", "#80CAEE", "#0FADCF", "#6577F3"],
        legend: {
            position: "bottom",
            fontSize: "14px",
            labels: {
                colors: 'var(--color-gray-500)',
                useSeriesColors: false
            }
        },
        dataLabels: { enabled: false },
        plotOptions: {
            pie: {
                donut: {
                    size: "70%",
                    labels: {
                        show: true,
                        total: {
                            show: true,
                            label: "Periods",
                            fontSize: "16px",
                            fontWeight: 600,
                            color: "#3C50E0",
                            formatter: function () {
                                return filteredPeriods.length.toString();
                            }
                        },
                    },
                },
            },
        },
        tooltip: {
            theme: 'dark',
            y: {
                formatter: function (val) {
                    return val + " periods";
                },
            },
        },
    };

    const pieChartSeries = Object.values(periodTypeCounts);

    // Revenue vs Profit Chart
    const last10Periods = [...periodsWithProfit]
        .sort(
            (a, b) =>
                new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
        )
        .slice(-10);

    const barChartSeries = [
        {
            name: "Net Profit",
            data: last10Periods.map((p) => {
                const profit = p.profit_loss?.net_profit;
                const profitNum = typeof profit === 'string' ? parseFloat(profit) : profit;
                return profitNum || 0;
            }),
        },
        {
            name: "Revenue",
            data: last10Periods.map((p) => {
                const sales = p.trading_account?.sales;
                const salesNum = typeof sales === 'string' ? parseFloat(sales) : sales;
                return salesNum || 0;
            }),
        },
    ];

    const barChartOptions: ApexCharts.ApexOptions = {
        chart: {
            type: "bar",
            height: 350,
            toolbar: { show: false },
            fontFamily: "inherit",
            background: 'transparent'
        },
        theme: { mode: 'light' },
        colors: ["#3C50E0", "#80CAEE"],
        plotOptions: {
            bar: {
                horizontal: false,
                columnWidth: "60%",
                borderRadius: 4,
            },
        },
        dataLabels: { enabled: false },
        stroke: { show: true, width: 2, colors: ["transparent"] },
        xaxis: {
            categories: last10Periods.map((p) => {
                return `${p.label}`;
            }),
            labels: {
                rotate: -45,
                trim: true,
                maxHeight: 80,
                style: { fontSize: "11px", colors: '#9CA3AF' }
            }
        },
        yaxis: {
            title: { text: "Amount (₹)", style: { fontSize: "14px", fontWeight: 500, color: '#9CA3AF' } },
            labels: {
                style: { colors: '#9CA3AF' },
                formatter: function (val) {
                    return "₹" + (val / 1000).toFixed(0) + "K";
                }
            }
        },
        fill: { opacity: 1 },
        tooltip: {
            theme: 'dark',
            y: {
                formatter: function (val) {
                    return "₹ " + val.toLocaleString("en-IN");
                },
            },
        },
        grid: {
            borderColor: '#374151',
            strokeDashArray: 4,
        },
    };

    if (loading) {
        return (
            <div className="flex h-screen items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-800 dark:to-gray-900">
                <div className="text-center">
                    <div className="h-16 w-16 animate-spin rounded-full border-4 border-solid border-primary border-t-transparent mx-auto"></div>
                    <p className="mt-4 text-lg font-medium text-gray-600 dark:text-gray-300">Loading Dashboard...</p>
                </div>
            </div>
        );
    }

    // --- RENDER ---
    return (
        <div className="animate-fadeIn pb-8">
            {/* Header Section */}
            <div className="mb-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                <div>
                    <h2 className="text-2xl font-bold text-black dark:text-white">
                        Financial Dashboard
                    </h2>
                    <p className="text-sm text-gray-600 dark:text-gray-400">
                        Overview of your fund management system
                    </p>
                </div>
                <div className="flex flex-wrap gap-3">
                    {/* Export Dropdown */}
                    <div className="relative" ref={exportMenuRef}>
                        <button
                            onClick={() => setShowExportMenu(!showExportMenu)}
                            className="inline-flex items-center gap-2 rounded-lg bg-white dark:bg-gray-800 border border-stroke dark:border-gray-700 px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 shadow-sm hover:bg-gray-50 dark:hover:bg-gray-700 transition-all duration-200"
                        >
                            <LucideDownload className="h-4 w-4" />
                            Export
                            <svg className={`h-4 w-4 transition-transform duration-200 ${showExportMenu ? 'rotate-180' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7" />
                            </svg>
                        </button>

                        {showExportMenu && (
                            <div className="absolute right-0 mt-2 w-48 rounded-lg border border-stroke bg-white shadow-default dark:border-gray-700 dark:bg-gray-800 z-50 animate-fadeIn">
                                <ul className="flex flex-col py-1">
                                    <li>
                                        <button onClick={handleExportCSV} className="flex w-full items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-700 text-left">
                                            <span className="font-medium">CSV</span><span className="text-xs text-gray-500 ml-auto">.csv</span>
                                        </button>
                                    </li>
                                    <li>
                                        <button onClick={handleExportExcel} className="flex w-full items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-700 text-left">
                                            <span className="font-medium">Excel</span><span className="text-xs text-gray-500 ml-auto">.xlsx</span>
                                        </button>
                                    </li>
                                    <li>
                                        <button onClick={handleExportPDF} className="flex w-full items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-700 text-left">
                                            <span className="font-medium">PDF</span><span className="text-xs text-gray-500 ml-auto">.pdf</span>
                                        </button>
                                    </li>
                                    <li>
                                        <button onClick={handleExportWord} className="flex w-full items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-700 text-left">
                                            <span className="font-medium">Word</span><span className="text-xs text-gray-500 ml-auto">.doc</span>
                                        </button>
                                    </li>
                                </ul>
                            </div>
                        )}
                    </div>

                    <button
                        onClick={handlePrint}
                        className="inline-flex items-center gap-2 rounded-lg bg-white dark:bg-gray-800 border border-stroke dark:border-gray-700 px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 shadow-sm hover:bg-gray-50 dark:hover:bg-gray-700 transition-all duration-200"
                        title="Print Dashboard"
                    >
                        <LucidePrinter className="h-4 w-4" />
                        Print
                    </button>

                    <button
                        onClick={handleRefresh}
                        disabled={refreshing}
                        className="inline-flex items-center gap-2 rounded-lg bg-white dark:bg-gray-800 border border-stroke dark:border-gray-700 px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 shadow-sm hover:bg-gray-50 dark:hover:bg-gray-700 transition-all duration-200 disabled:opacity-50"
                        title="Refresh Data"
                    >
                        <LucideRefreshCw className={`h-4 w-4 ${refreshing ? 'animate-spin' : ''}`} />
                        Refresh
                    </button>
                </div>
            </div>

            {/* Filter Bar */}
            <div className="mb-6 rounded-xl border border-stroke bg-white p-4 shadow-md dark:border-gray-700 dark:bg-gray-800">
                <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                    <div className="flex items-center gap-2">
                        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand-50 text-brand-500">
                            <LucideActivity className="h-4 w-4" />
                        </div>
                        <span className="font-semibold text-black dark:text-white">Filters</span>
                    </div>

                    <div className="flex flex-col gap-3 sm:flex-row">
                        <select
                            value={filterType}
                            onChange={(e) => setFilterType(e.target.value)}
                            disabled={filterLoading}
                            className="rounded-lg border border-stroke bg-gray-50 px-3 py-2 text-sm outline-none focus:border-brand-500 focus:ring-1 focus:ring-brand-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            <option value="">All Periods</option>
                            <option value="MONTHLY">Monthly</option>
                            <option value="QUARTERLY">Quarterly</option>
                            <option value="HALF_YEARLY">Half Yearly</option>
                            <option value="YEARLY">Yearly</option>
                        </select>
                        {filterLoading && (
                            <div className="flex items-center gap-2 px-3 py-2">
                                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-brand-500"></div>
                                <span className="text-sm text-brand-600 dark:text-brand-400">Loading...</span>
                            </div>
                        )}
                    </div>
                </div>

                {(filterType) && (
                    <div className="mt-3 flex flex-wrap gap-2 border-t border-stroke pt-3 dark:border-gray-700">
                        <span className="text-xs text-gray-500 py-1">Active:</span>
                        {filterType && (
                            <span className="flex items-center gap-1 rounded bg-brand-50 px-2 py-1 text-xs font-medium text-brand-500">
                                Type: {filterType}
                                <button onClick={() => setFilterType("")} className="ml-1 hover:text-brand-700">×</button>
                            </span>
                        )}
                        <button onClick={() => { setFilterType(""); }} className="text-xs text-gray-500 hover:text-black hover:underline px-2" disabled={filterLoading}>Clear all</button>
                    </div>
                )}
            </div>

            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 md:gap-6 xl:grid-cols-4 2xl:gap-7.5">
                {/* Card 1: Total Companies (Removed, maybe replace with something else or delete) */}


                {/* Card 2: Total Revenue */}
                <div className="group relative overflow-hidden rounded-xl border border-stroke bg-white px-7.5 py-6 shadow-lg hover:shadow-xl transition-all duration-300 dark:border-gray-700 dark:bg-gray-800">
                    <div className="absolute top-0 right-0 h-32 w-32 rounded-full bg-gradient-to-br from-green-400/10 to-green-600/10 -mr-16 -mt-16 group-hover:scale-110 transition-transform duration-300"></div>
                    <div className="relative">
                        <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-green-500 to-green-600 shadow-md">
                            <LucideTrendingUp className="text-white h-6 w-6" />
                        </div>
                        <div className="mt-4">
                            <h4 className="text-3xl font-bold text-black dark:text-white">₹{formatCurrency(totalRevenue)}M</h4>
                            <span className="text-sm font-medium text-gray-600 dark:text-gray-400">Total Revenue</span>
                        </div>
                    </div>
                </div>

                {/* Card 3: Profit Margin */}
                <div className="group relative overflow-hidden rounded-xl border border-stroke bg-white px-7.5 py-6 shadow-lg hover:shadow-xl transition-all duration-300 dark:border-gray-700 dark:bg-gray-800">
                    <div className="absolute top-0 right-0 h-32 w-32 rounded-full bg-gradient-to-br from-purple-400/10 to-purple-600/10 -mr-16 -mt-16 group-hover:scale-110 transition-transform duration-300"></div>
                    <div className="relative">
                        <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-purple-500 to-purple-600 shadow-md">
                            <LucidePercent className="text-white h-6 w-6" />
                        </div>
                        <div className="mt-4 flex items-end justify-between">
                            <div>
                                <h4 className="text-3xl font-bold text-black dark:text-white">{formatPercentage(avgProfitMargin)}%</h4>
                                <span className="text-sm font-medium text-gray-600 dark:text-gray-400">Avg Profit Margin</span>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Card 4: Growth Rate */}
                <div className="group relative overflow-hidden rounded-xl border border-stroke bg-white px-7.5 py-6 shadow-lg hover:shadow-xl transition-all duration-300 dark:border-gray-700 dark:bg-gray-800">
                    <div className="absolute top-0 right-0 h-32 w-32 rounded-full bg-gradient-to-br from-orange-400/10 to-orange-600/10 -mr-16 -mt-16 group-hover:scale-110 transition-transform duration-300"></div>
                    <div className="relative">
                        <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-orange-500 to-orange-600 shadow-md">
                            <LucideTrendingUp className="text-white h-6 w-6" />
                        </div>
                        <div className="mt-4 flex items-end justify-between">
                            <div>
                                <h4 className="text-3xl font-bold text-black dark:text-white flex items-center gap-2">
                                    {growthRate > 0 ? '+' : ''}{formatPercentage(growthRate)}%
                                    {growthRate >= 0 ? (<LucideArrowUpRight className="h-5 w-5 text-success" />) : (<LucideArrowDownRight className="h-5 w-5 text-danger" />)}
                                </h4>
                                <span className="text-sm font-medium text-gray-600 dark:text-gray-400">Growth Rate</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Secondary Stats Row */}
            <div className="mt-6 grid grid-cols-1 gap-4 md:grid-cols-3 md:gap-6">
                <div className="rounded-xl border border-stroke bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-800 dark:to-gray-900 px-6 py-5 shadow-md dark:border-gray-700">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-sm font-medium text-gray-600 dark:text-gray-400">Financial Periods</p>
                            <h3 className="text-2xl font-bold text-black dark:text-white mt-1">{totalPeriods}</h3>
                        </div>
                        <div className="flex h-14 w-14 items-center justify-center rounded-full bg-white dark:bg-gray-800 shadow-sm">
                            <LucideFileText className="text-primary h-7 w-7" />
                        </div>
                    </div>
                    <div className="mt-3 flex items-center gap-2">
                        <span className="inline-flex items-center gap-1 rounded-full bg-brand-50 px-2.5 py-1 text-xs font-medium text-brand-500">
                            <LucideActivity className="h-3 w-3" />
                            {finalizedPeriods} Finalized
                        </span>
                    </div>
                </div>

                <div className="rounded-xl border border-stroke bg-gradient-to-br from-green-50 to-emerald-50 dark:from-gray-800 dark:to-gray-900 px-6 py-5 shadow-md dark:border-gray-700">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-sm font-medium text-gray-600 dark:text-gray-400">Total Net Profit</p>
                            <h3 className="text-2xl font-bold text-black dark:text-white mt-1">₹{formatCurrency(totalProfit)}M</h3>
                        </div>
                        <div className="flex h-14 w-14 items-center justify-center rounded-full bg-white dark:bg-gray-800 shadow-sm">
                            <LucideTrendingUp className="text-success h-7 w-7" />
                        </div>
                    </div>
                </div>
            </div>

            {/* Charts Section */}
            <div className="mt-6 grid grid-cols-1 gap-4 md:gap-6 xl:grid-cols-12 2xl:gap-7.5">
                <div className="xl:col-span-8 rounded-xl border border-stroke bg-white px-5 pt-7.5 pb-5 shadow-lg dark:border-gray-700 dark:bg-gray-800 sm:px-7.5">
                    <h4 className="text-xl font-bold text-black dark:text-white mb-4">Revenue & Profit Analysis</h4>
                    <ReactApexChart options={barChartOptions} series={barChartSeries} type="bar" height={350} />
                </div>
                <div className="xl:col-span-4 rounded-xl border border-stroke bg-white px-5 pt-7.5 pb-5 shadow-lg dark:border-gray-700 dark:bg-gray-800 sm:px-7.5">
                    <h4 className="text-xl font-bold text-black dark:text-white mb-4">Period Distribution</h4>
                    <ReactApexChart options={pieChartOptions} series={pieChartSeries} type="donut" height={300} />
                </div>
            </div>

            {/* Top Performers & Recent Activity Section */}
            <div className="mt-6 grid grid-cols-1 gap-4 md:gap-6 xl:grid-cols-2">
                <div className="rounded-xl border border-stroke bg-white px-5 pt-6 pb-5 shadow-lg dark:border-gray-700 dark:bg-gray-800 sm:px-7.5">
                    <div className="mb-5 flex items-center gap-2">
                        <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-gradient-to-br from-yellow-400 to-orange-500">
                            <LucideTrophy className="text-white h-5 w-5" />
                        </div>
                        <h4 className="text-lg font-bold text-black dark:text-white">Top Periods</h4>
                    </div>
                    <div className="flex flex-col gap-3">
                        {topPeriods.map((period, index) => (
                            <div
                                key={period.id}
                                onClick={() => navigate(`/financial-statements/${period.id}`)}
                                className="flex items-center justify-between rounded-lg border border-stroke dark:border-gray-700 bg-gray-50 dark:bg-gray-700 p-4 hover:shadow-md transition-all duration-200 cursor-pointer"
                            >
                                <div className="flex items-center gap-3">
                                    <div className={`flex h-8 w-8 items-center justify-center rounded-full font-bold text-white ${index === 0 ? 'bg-gradient-to-br from-yellow-400 to-yellow-600' : index === 1 ? 'bg-gradient-to-br from-gray-300 to-gray-500' : 'bg-gradient-to-br from-blue-400 to-blue-600'}`}>
                                        {index + 1}
                                    </div>
                                    <div>
                                        <p className="font-semibold text-black dark:text-white">{period.label}</p>
                                        <p className="text-xs text-gray-600 dark:text-gray-400">{period.period_type}</p>
                                    </div>
                                </div>
                                <div className="text-right">
                                    <p className="font-bold text-success">₹{formatCurrency(typeof period.profit_loss?.net_profit === 'number' ? period.profit_loss.net_profit : parseFloat(period.profit_loss?.net_profit || "0"))}M</p>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Activity Timeline */}
                <div className="rounded-xl border border-stroke bg-white px-5 pt-6 pb-5 shadow-lg dark:border-gray-700 dark:bg-gray-800 sm:px-7.5">
                    <div className="mb-6 flex items-center justify-between">
                        <div className="flex items-center gap-2">
                            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-gradient-to-br from-indigo-400 to-indigo-600 shadow-md">
                                <LucideActivity className="text-white h-5 w-5" />
                            </div>
                            <h4 className="text-lg font-bold text-black dark:text-white">Recent Activity</h4>
                        </div>
                    </div>

                    <div className="relative pl-4 space-y-2">
                        {/* Continuous Vertical Line */}
                        <div className="absolute left-6 top-2 bottom-6 w-0.5 border-l-2 border-dashed border-gray-200 dark:border-gray-700 transition-colors duration-300"></div>

                        {[...periods].sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()).slice(0, 5).map((period) => {
                            const timeAgo = (() => {
                                const diff = new Date().getTime() - new Date(period.created_at).getTime();
                                const minutes = Math.floor(diff / 60000);
                                const hours = Math.floor(minutes / 60);
                                const days = Math.floor(hours / 24);
                                if (minutes < 60) return `${minutes}m ago`;
                                if (hours < 24) return `${hours}h ago`;
                                return `${days}d ago`;
                            })();

                            return (
                                <div
                                    key={period.id}
                                    onClick={() => navigate(`/financial-statements/${period.id}`)}
                                    className="group relative flex gap-4 rounded-lg p-3 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-all duration-200 cursor-pointer"
                                >
                                    {/* Timeline Dot */}
                                    <div className={`relative z-10 flex h-9 w-9 shrink-0 items-center justify-center rounded-full border-4 border-white dark:border-gray-800 shadow-sm ${period.is_finalized
                                        ? 'bg-gradient-to-br from-green-400 to-green-600'
                                        : 'bg-gradient-to-br from-blue-400 to-blue-600'
                                        }`}>
                                        {period.is_finalized ? (
                                            <LucideCheckCircle className="text-white h-4 w-4" />
                                        ) : (
                                            <LucidePlus className="text-white h-4 w-4" />
                                        )}
                                    </div>

                                    {/* Content */}
                                    <div className="flex flex-1 flex-col gap-1">
                                        <div className="flex justify-between items-start">
                                            <h5 className={`text-sm font-bold ${period.is_finalized ? 'text-green-600 dark:text-green-400' : 'text-blue-600 dark:text-blue-400'
                                                }`}>
                                                {period.is_finalized ? 'Period Finalized' : 'New Draft Created'}
                                            </h5>
                                            <span className="text-xs font-medium text-gray-400 dark:text-gray-500 bg-gray-100 dark:bg-gray-700 px-2 py-0.5 rounded-full">
                                                {timeAgo}
                                            </span>
                                        </div>
                                        <p className="text-sm font-semibold text-black dark:text-white leading-tight">
                                            {period.label}
                                        </p>
                                        <p className="text-xs text-gray-500 dark:text-gray-400 flex items-center gap-1">
                                            <LucideFileText className="h-3 w-3" />
                                            <span className="uppercase">{period.period_type.replace('_', ' ')}</span>
                                        </p>
                                    </div>
                                </div>
                            );
                        })}

                        {periods.length === 0 && (
                            <div className="py-8 text-center text-gray-500 dark:text-gray-400">
                                No recent activity found.
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default MasterDashboard;
