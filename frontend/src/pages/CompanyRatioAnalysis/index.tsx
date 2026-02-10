import React, { useState, useEffect } from "react";
import { BeatLoader } from "react-spinners";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import PageBreadcrumb from "../../components/common/PageBreadCrumb";
import PageMeta from "../../components/common/PageMeta";
import { getCompanies, getCompanyPeriods, CompanyData, FinancialPeriodData } from "./api";
import { getRatioResults, RatioResultData } from "../FinancialStatements/api";
import RatioCard from "../../components/RatioCard";
import { ArrowLeft } from "lucide-react";

const CompanyRatioAnalysis: React.FC = () => {
  const [companies, setCompanies] = useState<CompanyData[]>([]);
  const [selectedCompany, setSelectedCompany] = useState<CompanyData | null>(null);
  const [periods, setPeriods] = useState<FinancialPeriodData[]>([]);
  const [selectedPeriod, setSelectedPeriod] = useState<FinancialPeriodData | null>(null);
  const [ratios, setRatios] = useState<RatioResultData | null>(null);

  const [loading, setLoading] = useState(true);
  const [loadingPeriods, setLoadingPeriods] = useState(false);
  const [loadingRatios, setLoadingRatios] = useState(false);

  // Load companies on component mount
  useEffect(() => {
    loadCompanies();
  }, []);

  const loadCompanies = async () => {
    try {
      setLoading(true);
      const data = await getCompanies();
      setCompanies(data);
    } catch (error) {
      console.error("Error loading companies:", error);
      toast.error("Failed to load companies");
    } finally {
      setLoading(false);
    }
  };

  const handleSelectCompany = async (company: CompanyData) => {
    try {
      setSelectedCompany(company);
      setSelectedPeriod(null);
      setRatios(null);
      setLoadingPeriods(true);

      console.log(`Fetching periods for company: ${company.id} (${company.name})`);
      const periodsData = await getCompanyPeriods(company.id);
      console.log("Periods fetched:", periodsData);
      
      setPeriods(periodsData);

      if (periodsData.length === 0) {
        toast.info("No financial periods found for this company");
      }
    } catch (error: any) {
      console.error("Error loading periods:", error);
      console.error("Error details:", error?.response?.data || error?.message);
      toast.error("Failed to load periods: " + (error?.response?.data?.message || error?.message || "Unknown error"));
    } finally {
      setLoadingPeriods(false);
    }
  };

  const handleSelectPeriod = async (period: FinancialPeriodData) => {
    try {
      setSelectedPeriod(period);
      setLoadingRatios(true);

      const ratioData = await getRatioResults(period.id);
      setRatios(ratioData);
    } catch (error) {
      console.error("Error loading ratio data:", error);
      toast.error("Failed to load ratio data");
    } finally {
      setLoadingRatios(false);
    }
  };

  const handleBackToCompanies = () => {
    setSelectedCompany(null);
    setSelectedPeriod(null);
    setRatios(null);
    setPeriods([]);
  };

  const handleBackToPeriods = () => {
    setSelectedPeriod(null);
    setRatios(null);
  };

  return (
    <>
      <PageMeta 
        title="Company Ratio Analysis" 
        description="Analyze financial ratios for companies by period"
      />
      <PageBreadcrumb pageTitle="Company Ratio Analysis" />

      <div className="p-6">
        <ToastContainer position="top-right" autoClose={3000} />

        {/* Companies Selection Screen */}
        {!selectedCompany && (
          <div>
            <h1 className="text-2xl font-bold mb-6 text-gray-900 dark:text-white">
              Select Company
            </h1>

            {loading ? (
              <div className="flex items-center justify-center h-64">
                <BeatLoader color="#3b82f6" />
              </div>
            ) : companies.length === 0 ? (
              <div className="p-6 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg">
                <p className="text-yellow-800 dark:text-yellow-200">
                  No companies found. Please add a company first.
                </p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {companies.map((company) => (
                  <div
                    key={company.id}
                    onClick={() => handleSelectCompany(company)}
                    className="p-4 bg-white dark:bg-gray-800 rounded-lg shadow cursor-pointer hover:shadow-lg hover:scale-105 transition-all"
                  >
                    <h3 className="font-semibold text-lg text-gray-900 dark:text-white mb-2">
                      {company.name}
                    </h3>
                    <p className="text-sm text-gray-600 dark:text-gray-400 mb-2">
                      Reg No: {company.registration_no}
                    </p>
                    <p className="text-xs text-gray-500 dark:text-gray-500">
                      {new Date(company.created_at).toLocaleDateString()}
                    </p>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Periods Selection Screen */}
        {selectedCompany && !selectedPeriod && (
          <div>
            <div className="flex items-center gap-3 mb-6">
              <button
                onClick={handleBackToCompanies}
                className="flex items-center gap-2 px-4 py-2 text-blue-600 dark:text-blue-400 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
              >
                <ArrowLeft className="w-5 h-5" />
                Back to Companies
              </button>
            </div>

            <h1 className="text-2xl font-bold mb-2 text-gray-900 dark:text-white">
              {selectedCompany.name}
            </h1>
            <p className="text-sm text-gray-600 dark:text-gray-400 mb-6">
              Select a period to view ratio analysis
            </p>

            {loadingPeriods ? (
              <div className="flex items-center justify-center h-64">
                <BeatLoader color="#3b82f6" />
              </div>
            ) : periods.length === 0 ? (
              <div className="p-6 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg">
                <p className="text-yellow-800 dark:text-yellow-200">
                  No financial periods found for this company.
                </p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {periods.map((period) => (
                  <div
                    key={period.id}
                    onClick={() => handleSelectPeriod(period)}
                    className="p-4 bg-white dark:bg-gray-800 rounded-lg shadow cursor-pointer hover:shadow-lg hover:scale-105 transition-all"
                  >
                    <div className="flex justify-between items-start mb-2">
                      <h3 className="font-semibold text-lg text-gray-900 dark:text-white">
                        {period.label}
                      </h3>
                      <span
                        className={`text-xs px-2 py-1 rounded ${
                          period.period_type === "YEARLY"
                            ? "bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200"
                            : period.period_type === "QUARTERLY"
                            ? "bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200"
                            : "bg-purple-100 dark:bg-purple-900 text-purple-800 dark:text-purple-200"
                        }`}
                      >
                        {period.period_type}
                      </span>
                    </div>
                    <p className="text-sm text-gray-600 dark:text-gray-400 mb-2">
                      {new Date(period.start_date).toLocaleDateString()} -{" "}
                      {new Date(period.end_date).toLocaleDateString()}
                    </p>
                    <p
                      className={`text-xs font-medium ${
                        period.is_finalized
                          ? "text-green-600 dark:text-green-400"
                          : "text-gray-500 dark:text-gray-500"
                      }`}
                    >
                      {period.is_finalized ? "✓ Finalized" : "Draft"}
                    </p>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Ratio Analysis Screen */}
        {selectedCompany && selectedPeriod && (
          <div>
            <div className="flex items-center gap-3 mb-6">
              <button
                onClick={handleBackToPeriods}
                className="flex items-center gap-2 px-4 py-2 text-blue-600 dark:text-blue-400 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
              >
                <ArrowLeft className="w-5 h-5" />
                Back to Periods
              </button>
            </div>

            <div className="mb-6">
              <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                {selectedCompany.name}
              </h1>
              <p className="text-gray-600 dark:text-gray-400">
                {selectedPeriod.label} ({selectedPeriod.period_type})
              </p>
            </div>

            {loadingRatios ? (
              <div className="flex items-center justify-center h-64">
                <BeatLoader color="#3b82f6" />
              </div>
            ) : !ratios ? (
              <div className="p-6 bg-red-50 dark:bg-red-900/20 rounded-lg">
                <p className="text-red-600 dark:text-red-400">
                  No ratio data found. Please calculate ratios first.
                </p>
              </div>
            ) : (
              <RatioAnalysisDisplay ratios={ratios} />
            )}
          </div>
        )}
      </div>
    </>
  );
};

// Sub-component to display ratios organized by category
const RatioAnalysisDisplay: React.FC<{ ratios: RatioResultData }> = ({
  ratios,
}) => {
  const tradingRatios = [
    {
      name: "Stock Turnover",
      value: ratios.stock_turnover,
      unit: "times",
      idealValue: 15.0,
      status: ratios.traffic_light_status?.stock_turnover,
    },
    {
      name: "Gross Profit Ratio",
      value: ratios.gross_profit_ratio || 0,
      unit: "%",
      idealValue: 10.0,
      status: ratios.traffic_light_status?.gross_profit_ratio,
    },
    {
      name: "Net Profit Ratio",
      value: ratios.net_profit_ratio || 0,
      unit: "%",
      status: ratios.traffic_light_status?.net_profit_ratio,
    },
  ];

  const fundStructureRatios = [
    {
      name: "Own Fund to Working Fund",
      value: ratios.own_fund_to_wf || 0,
      unit: "%",
      idealValue: 8.0,
      status: ratios.traffic_light_status?.own_fund_to_wf,
    },
    {
      name: "Deposits to Working Fund",
      value: ratios.deposits_to_wf || 0,
      unit: "%",
      status: ratios.traffic_light_status?.deposits_to_wf,
    },
    {
      name: "Borrowings to Working Fund",
      value: ratios.borrowings_to_wf || 0,
      unit: "%",
      status: ratios.traffic_light_status?.borrowings_to_wf,
    },
    {
      name: "Loans to Working Fund",
      value: ratios.loans_to_wf || 0,
      unit: "%",
      idealValue: 70.0,
      status: ratios.traffic_light_status?.loans_to_wf,
    },
    {
      name: "Investments to Working Fund",
      value: ratios.investments_to_wf || 0,
      unit: "%",
      idealValue: 25.0,
      status: ratios.traffic_light_status?.investments_to_wf,
    },
  ];

  const yieldCostRatios = [
    {
      name: "Cost of Deposits",
      value: ratios.cost_of_deposits,
      unit: "%",
      status: ratios.traffic_light_status?.cost_of_deposits,
    },
    {
      name: "Yield on Loans",
      value: ratios.yield_on_loans,
      unit: "%",
      status: ratios.traffic_light_status?.yield_on_loans,
    },
    {
      name: "Yield on Investments",
      value: ratios.yield_on_investments || 0,
      unit: "%",
      status: ratios.traffic_light_status?.yield_on_investments,
    },
    {
      name: "Credit Deposit Ratio",
      value: ratios.credit_deposit_ratio,
      unit: "%",
      idealValue: 70.0,
      status: ratios.traffic_light_status?.credit_deposit_ratio,
    },
    {
      name: "Avg Cost of Working Fund",
      value: ratios.avg_cost_of_wf || 0,
      unit: "%",
      idealValue: 3.5,
      status: ratios.traffic_light_status?.avg_cost_of_wf,
    },
    {
      name: "Avg Yield on Working Fund",
      value: ratios.avg_yield_on_wf || 0,
      unit: "%",
      idealValue: 3.5,
      status: ratios.traffic_light_status?.avg_yield_on_wf,
    },
  ];

  const marginRatios = [
    {
      name: "Gross Financial Margin",
      value: ratios.gross_fin_margin,
      unit: "%",
      idealValue: 3.5,
      status: ratios.traffic_light_status?.gross_fin_margin,
    },
    {
      name: "Operating Cost to Working Fund",
      value: ratios.operating_cost_to_wf || 0,
      unit: "%",
      idealValue: 2.5,
      status: ratios.traffic_light_status?.operating_cost_to_wf,
    },
    {
      name: "Net Financial Margin",
      value: ratios.net_fin_margin,
      unit: "%",
      idealValue: 1.5,
      status: ratios.traffic_light_status?.net_fin_margin,
    },
    {
      name: "Risk Cost to Working Fund",
      value: ratios.risk_cost_to_wf || 0,
      unit: "%",
      idealValue: 0.25,
      status: ratios.traffic_light_status?.risk_cost_to_wf,
    },
    {
      name: "Net Margin",
      value: ratios.net_margin,
      unit: "%",
      idealValue: 1.0,
      status: ratios.traffic_light_status?.net_margin,
    },
  ];

  return (
    <div className="space-y-8">
      {/* Trading Ratios */}
      <div>
        <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-white">
          Trading Ratios
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {tradingRatios.map((ratio, idx) => (
            <RatioCard key={idx} {...ratio} />
          ))}
        </div>
      </div>

      {/* Fund Structure Ratios */}
      <div>
        <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-white">
          Fund Structure
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {fundStructureRatios.map((ratio, idx) => (
            <RatioCard key={idx} {...ratio} />
          ))}
        </div>
      </div>

      {/* Yield & Cost Ratios */}
      <div>
        <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-white">
          Yield & Cost Analysis
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {yieldCostRatios.map((ratio, idx) => (
            <RatioCard key={idx} {...ratio} />
          ))}
        </div>
      </div>

      {/* Margin Ratios */}
      <div>
        <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-white">
          Margin Analysis
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {marginRatios.map((ratio, idx) => (
            <RatioCard key={idx} {...ratio} />
          ))}
        </div>
      </div>
    </div>
  );
};

export default CompanyRatioAnalysis;
