import React, { useEffect, useState } from "react";
import ReactApexChart from "react-apexcharts";
import { Link } from "react-router-dom";
import {
  LucideBuilding2,
  LucideFileText,
  LucideTrendingUp,
  LucideUsers,
  LucideCalendar
} from "lucide-react";
import { CompanyData, getCompanyList } from "../Companies/api";
import {
  FinancialPeriodData,
  getFinancialPeriods,
} from "../FinancialStatements/api";

const MasterDashboard = () => {
  const [companies, setCompanies] = useState<CompanyData[]>([]);
  const [periods, setPeriods] = useState<FinancialPeriodData[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [companiesData, periodsData] = await Promise.all([
        getCompanyList(),
        getFinancialPeriods(),
      ]);
      setCompanies(companiesData);
      setPeriods(periodsData);
    } catch (error) {
      console.error("Error loading dashboard data:", error);
    } finally {
      setLoading(false);
    }
  };

  // --- Calculations ---

  const totalCompanies = companies.length;
  const totalPeriods = periods.length;

  // Calculate total finalized periods
  const finalizedPeriods = periods.filter((p) => p.is_finalized).length;

  // Get recent periods (last 5)
  const recentPeriods = [...periods]
    .sort(
      (a, b) =>
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    )
    .slice(0, 5);

  // Prepare chart data: Period Types Distribution
  const periodTypeCounts = periods.reduce((acc, curr) => {
    acc[curr.period_type] = (acc[curr.period_type] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  const pieChartOptions: ApexCharts.ApexOptions = {
    chart: { type: "donut", fontFamily: "inherit" },
    labels: Object.keys(periodTypeCounts).map((key) =>
      key.replace("_", " ").toLowerCase().replace(/\b\w/g, (c) => c.toUpperCase())
    ),
    colors: ["#3C50E0", "#80CAEE", "#0FADCF", "#6577F3"],
    legend: { position: "bottom" },
    dataLabels: { enabled: false },
    plotOptions: {
      pie: {
        donut: {
          size: "65%",
          labels: {
            show: true,
            total: {
              show: true,
              label: "Periods",
              fontSize: "16px",
              fontWeight: 600,
            },
          },
        },
      },
    },
  };

  const pieChartSeries = Object.values(periodTypeCounts);

  // Prepare chart data: Recent Net Profit Trends (Last 10 periods with profit data)
  // detailedPeriods are periods that actually have profit_loss data
  const periodsWithProfit = periods
    .filter((p) => p.profit_loss?.net_profit !== undefined)
    .sort(
      (a, b) =>
        new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
    )
    .slice(-10); // Take last 10

  const barChartSeries = [
    {
      name: "Net Profit",
      data: periodsWithProfit.map((p) => p.profit_loss?.net_profit || 0),
    },
    {
      name: "Revenue",
      data: periodsWithProfit.map((p) => p.trading_account?.sales || 0),
    },
  ];

  const barChartOptions: ApexCharts.ApexOptions = {
    chart: {
      type: "bar",
      height: 350,
      toolbar: { show: false },
      fontFamily: "inherit",
    },
    colors: ["#3C50E0", "#80CAEE"],
    plotOptions: {
      bar: {
        horizontal: false,
        columnWidth: "55%",
        borderRadius: 2,
      },
    },
    dataLabels: { enabled: false },
    stroke: { show: true, width: 2, colors: ["transparent"] },
    xaxis: {
      categories: periodsWithProfit.map((p) => {
        const companyName =
          companies.find((c) => c.id === p.company)?.name || "Unknown";
        return `${companyName} (${p.label})`;
      }),
      labels: {
        rotate: -45,
        trim: true,
        maxHeight: 60,
      }
    },
    yaxis: { title: { text: "Amount (₹)" } },
    fill: { opacity: 1 },
    tooltip: {
      y: {
        formatter: function (val) {
          return "₹ " + val.toLocaleString("en-IN");
        },
      },
    },
  };

  // Helper to get company name
  const getCompanyName = (id: number) => {
    return companies.find((c) => c.id === id)?.name || "Unknown Company";
  };

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <div className="h-16 w-16 animate-spin rounded-full border-4 border-solid border-primary border-t-transparent"></div>
      </div>
    );
  }

  return (
    <>
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 md:gap-6 xl:grid-cols-4 2xl:gap-7.5">
        {/* Card 1: Total Companies */}
        <div className="rounded-sm border border-stroke bg-white px-7.5 py-6 shadow-default dark:border-strokedark dark:bg-boxdark">
          <div className="flex h-11.5 w-11.5 items-center justify-center rounded-full bg-meta-2 dark:bg-meta-4">
            <LucideBuilding2 className="text-primary dark:text-white" />
          </div>
          <div className="mt-4 flex items-end justify-between">
            <div>
              <h4 className="text-title-md font-bold text-black dark:text-white">
                {totalCompanies}
              </h4>
              <span className="text-sm font-medium">Total Companies</span>
            </div>
          </div>
        </div>

        {/* Card 2: Total Financial Periods */}
        <div className="rounded-sm border border-stroke bg-white px-7.5 py-6 shadow-default dark:border-strokedark dark:bg-boxdark">
          <div className="flex h-11.5 w-11.5 items-center justify-center rounded-full bg-meta-2 dark:bg-meta-4">
            <LucideFileText className="text-primary dark:text-white" />
          </div>
          <div className="mt-4 flex items-end justify-between">
            <div>
              <h4 className="text-title-md font-bold text-black dark:text-white">
                {totalPeriods}
              </h4>
              <span className="text-sm font-medium">Financial Periods</span>
            </div>
            <span className="text-xs text-primary bg-primary/10 px-2 py-1 rounded">
              {finalizedPeriods} Finalized
            </span>
          </div>
        </div>

        {/* Card 3: Recent Activity (Placeholder logic) */}
        <div className="rounded-sm border border-stroke bg-white px-7.5 py-6 shadow-default dark:border-strokedark dark:bg-boxdark">
          <div className="flex h-11.5 w-11.5 items-center justify-center rounded-full bg-meta-2 dark:bg-meta-4">
            <LucideCalendar className="text-primary dark:text-white" />
          </div>
          <div className="mt-4 flex items-end justify-between">
            <div>
              <h4 className="text-title-md font-bold text-black dark:text-white">
                {recentPeriods.length > 0 ? new Date(recentPeriods[0].created_at).toLocaleDateString() : "N/A"}
              </h4>
              <span className="text-sm font-medium">Last Update</span>
            </div>
          </div>
        </div>

        {/* Card 4: Users (Placeholder) */}
        <div className="rounded-sm border border-stroke bg-white px-7.5 py-6 shadow-default dark:border-strokedark dark:bg-boxdark">
          <div className="flex h-11.5 w-11.5 items-center justify-center rounded-full bg-meta-2 dark:bg-meta-4">
            <LucideTrendingUp className="text-primary dark:text-white" />
          </div>
          <div className="mt-4 flex items-end justify-between">
            <div>
              <h4 className="text-title-md font-bold text-black dark:text-white">
                Overview
              </h4>
              <span className="text-sm font-medium">System Status</span>
            </div>
            <span className="text-xs text-success bg-success/10 px-2 py-1 rounded">
              Active
            </span>
          </div>
        </div>
      </div>

      {/* Charts Section */}
      <div className="mt-4 grid grid-cols-1 gap-4 md:mt-6 md:grid-cols-2 md:gap-6 2xl:mt-7.5 2xl:gap-7.5">
        {/* Bar Chart: Revenue vs Profit */}
        <div className="col-span-12 rounded-sm border border-stroke bg-white px-5 pt-7.5 pb-5 shadow-default dark:border-strokedark dark:bg-boxdark sm:px-7.5 xl:col-span-8">
          <div className="flex flex-wrap items-start justify-between gap-3 sm:flex-nowrap">
            <div className="flex w-full flex-wrap gap-3 sm:gap-5">
              <div className="flex min-w-47.5">
                <span className="mt-1 mr-2 flex h-4 w-full max-w-4 items-center justify-center rounded-full border border-primary">
                  <span className="block h-2.5 w-full max-w-2.5 rounded-full bg-primary"></span>
                </span>
                <div className="w-full">
                  <p className="font-semibold text-primary">Net Profit</p>
                  <p className="text-sm font-medium">Recent Periods</p>
                </div>
              </div>
              <div className="flex min-w-47.5">
                <span className="mt-1 mr-2 flex h-4 w-full max-w-4 items-center justify-center rounded-full border border-secondary">
                  <span className="block h-2.5 w-full max-w-2.5 rounded-full bg-[#80CAEE]"></span>
                </span>
                <div className="w-full">
                  <p className="font-semibold text-secondary">Revenue</p>
                  <p className="text-sm font-medium">Recent Periods</p>
                </div>
              </div>
            </div>
          </div>
          <div>
            <div id="chartOne" className="-ml-5">
              <ReactApexChart
                options={barChartOptions}
                series={barChartSeries}
                type="bar"
                height={350}
              />
            </div>
          </div>
        </div>

        {/* Pie Chart: Period Types */}
        <div className="col-span-12 rounded-sm border border-stroke bg-white px-5 pt-7.5 pb-5 shadow-default dark:border-strokedark dark:bg-boxdark sm:px-7.5 xl:col-span-4">
          <div className="mb-3 justify-between gap-4 sm:flex">
            <div>
              <h5 className="text-xl font-semibold text-black dark:text-white">
                Period Types
              </h5>
            </div>
          </div>
          <div className="mb-2">
            <div id="chartThree" className="mx-auto flex justify-center">
              <ReactApexChart
                options={pieChartOptions}
                series={pieChartSeries}
                type="donut"
              />
            </div>
          </div>
        </div>
      </div>

      {/* Recent Activity Table */}
      <div className="mt-4 rounded-sm border border-stroke bg-white px-5 pt-6 pb-2.5 shadow-default dark:border-strokedark dark:bg-boxdark sm:px-7.5 xl:pb-1">
        <h4 className="mb-6 text-xl font-semibold text-black dark:text-white">
          Recent Financial Periods
        </h4>

        <div className="flex flex-col">
          <div className="grid grid-cols-3 rounded-sm bg-gray-2 dark:bg-meta-4 sm:grid-cols-5">
            <div className="p-2.5 xl:p-5">
              <h5 className="text-sm font-medium uppercase xsm:text-base">
                Company
              </h5>
            </div>
            <div className="p-2.5 text-center xl:p-5">
              <h5 className="text-sm font-medium uppercase xsm:text-base">
                Label
              </h5>
            </div>
            <div className="p-2.5 text-center xl:p-5">
              <h5 className="text-sm font-medium uppercase xsm:text-base">
                Type
              </h5>
            </div>
            <div className="hidden p-2.5 text-center sm:block xl:p-5">
              <h5 className="text-sm font-medium uppercase xsm:text-base">
                Status
              </h5>
            </div>
            <div className="hidden p-2.5 text-center sm:block xl:p-5">
              <h5 className="text-sm font-medium uppercase xsm:text-base">
                Net Profit
              </h5>
            </div>
          </div>

          {recentPeriods.map((period, key) => (
            <div
              className={`grid grid-cols-3 sm:grid-cols-5 ${key === recentPeriods.length - 1
                ? ""
                : "border-b border-stroke dark:border-strokedark"
                }`}
              key={key}
            >
              <div className="flex items-center gap-3 p-2.5 xl:p-5">
                <p className="hidden text-black dark:text-white sm:block">
                  {getCompanyName(period.company)}
                </p>
              </div>

              <div className="flex items-center justify-center p-2.5 xl:p-5">
                <p className="text-black dark:text-white">{period.label}</p>
              </div>

              <div className="flex items-center justify-center p-2.5 xl:p-5">
                <span className="inline-block rounded bg-gray-100 px-2.5 py-0.5 text-sm font-medium text-gray-800 dark:bg-gray-700 dark:text-gray-300">
                  {period.period_type}
                </span>
              </div>

              <div className="hidden items-center justify-center p-2.5 sm:flex xl:p-5">
                <p className={`text-meta-3`}>
                  {period.is_finalized ? "Finalized" : "Draft"}
                </p>
              </div>

              <div className="hidden items-center justify-center p-2.5 sm:flex xl:p-5">
                <p className="text-meta-5">
                  {period.profit_loss?.net_profit
                    ? `₹${period.profit_loss.net_profit.toLocaleString("en-IN")}`
                    : "-"}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </>
  );
};

export default MasterDashboard;
