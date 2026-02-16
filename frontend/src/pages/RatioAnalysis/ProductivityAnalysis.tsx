import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import {
  getFinancialPeriod,
  FinancialPeriodData,
} from "../FinancialStatements/api";
import { BeatLoader } from "react-spinners";
import { toast } from "react-toastify";
import { ArrowLeft } from "lucide-react";

const ProductivityAnalysis: React.FC = () => {
  const { periodId } = useParams<{ periodId: string }>();
  const navigate = useNavigate();
  const [period, setPeriod] = useState<FinancialPeriodData | null>(null);
  const [loading, setLoading] = useState(true);
  const [metrics, setMetrics] = useState({
    perEmployeeBusiness: 0,
    perEmployeeContribution: 0,
    perEmployeeOperatingCost: 0,
    isEfficient: false,
  });

  useEffect(() => {
    if (periodId) {
      loadData();
    }
  }, [periodId]);

  const loadData = async () => {
    if (!periodId) return;
    setLoading(true);
    try {
      const data = await getFinancialPeriod(parseInt(periodId));
      setPeriod(data);
      calculateMetrics(data);
    } catch (error) {
      console.error("Error loading period:", error);
      toast.error("Failed to load period data");
    } finally {
      setLoading(false);
    }
  };

  const calculateMetrics = (periodData: FinancialPeriodData) => {
    if (
      !periodData.balance_sheet ||
      !periodData.profit_loss ||
      !periodData.operational_metrics
    ) {
      return;
    }

    const bs = periodData.balance_sheet;
    const pl = periodData.profit_loss;
    const ops = periodData.operational_metrics;

    const staffCount = Number(ops.staff_count) || 0;

    if (staffCount > 0) {
      const deposits = Number(bs.deposits) || 0;
      const loansAdvances = Number(bs.loans_advances) || 0;
      const perEmployeeBusiness = (deposits + loansAdvances) / staffCount;

      const interestOnLoans = Number(pl.interest_on_loans) || 0;
      const interestOnBankAc = Number(pl.interest_on_bank_ac) || 0;
      const returnOnInvestment = Number(pl.return_on_investment) || 0;
      const miscIncome = Number(pl.miscellaneous_income) || 0;
      const interestOnDeposits = Number(pl.interest_on_deposits) || 0;
      const interestOnBorrowings = Number(pl.interest_on_borrowings) || 0;

      const totalIncome =
        interestOnLoans + interestOnBankAc + returnOnInvestment + miscIncome;
      const totalInterestExpense = interestOnDeposits + interestOnBorrowings;
      const perEmployeeContribution =
        (totalIncome - totalInterestExpense) / staffCount;

      const establishmentContingencies = Number(pl.establishment_contingencies) || 0;
      const perEmployeeOperatingCost = establishmentContingencies / staffCount;

      const isEfficient = perEmployeeContribution > perEmployeeOperatingCost;

      setMetrics({
        perEmployeeBusiness,
        perEmployeeContribution,
        perEmployeeOperatingCost,
        isEfficient,
      });
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <BeatLoader color="#3b82f6" />
      </div>
    );
  }

  if (!period) {
    return (
      <div className="p-6">
        <p className="text-red-600 dark:text-red-400">Period not found</p>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header with Back Button */}
      <div className="flex items-center justify-between bg-white dark:bg-gray-800 p-4 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate(`/ratio-analysis/${periodId}`)}
            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
            title="Back to Dashboard"
          >
            <ArrowLeft className="w-5 h-5 text-gray-700 dark:text-gray-300" />
          </button>
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
              Productivity Analysis
            </h1>
            {period && (
              <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                {period.label}
              </p>
            )}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Per Employee Business */}
        <div className="p-6 bg-white dark:bg-gray-800 rounded-lg shadow-md border border-gray-200 dark:border-gray-700">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
            Per Employee Business
          </h3>
          <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
            (Average Deposit + Average Loan) / Staff Count
          </p>
          <p className="text-3xl font-bold text-blue-600 dark:text-blue-400">
            ₹{Number(metrics.perEmployeeBusiness).toLocaleString("en-IN", {
              minimumFractionDigits: 2,
              maximumFractionDigits: 2,
            })}
          </p>
        </div>

        {/* Per Employee Contribution */}
        <div className="p-6 bg-white dark:bg-gray-800 rounded-lg shadow-md border border-gray-200 dark:border-gray-700">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
            Per Employee Contribution
          </h3>
          <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
            (Total Income - Interest Expenses) / Staff Count
          </p>
          <p className="text-3xl font-bold text-green-600 dark:text-green-400">
            ₹{Number(metrics.perEmployeeContribution).toLocaleString("en-IN", {
              minimumFractionDigits: 2,
              maximumFractionDigits: 2,
            })}
          </p>
        </div>

        {/* Per Employee Operating Cost */}
        <div className="p-6 bg-white dark:bg-gray-800 rounded-lg shadow-md border border-gray-200 dark:border-gray-700">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
            Per Employee Operating Cost
          </h3>
          <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
            Establishment & Contingencies / Staff Count
          </p>
          <p className="text-3xl font-bold text-orange-600 dark:text-orange-400">
            ₹{Number(metrics.perEmployeeOperatingCost).toLocaleString("en-IN", {
              minimumFractionDigits: 2,
              maximumFractionDigits: 2,
            })}
          </p>
        </div>

        {/* Efficiency Status */}
        <div
          className={`p-6 rounded-lg shadow-md border-2 ${
            metrics.isEfficient
              ? "bg-green-50 border-green-500 dark:bg-green-900/20 dark:border-green-500"
              : "bg-red-50 border-red-500 dark:bg-red-900/20 dark:border-red-500"
          }`}
        >
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
            Efficiency Status
          </h3>
          <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
            Contribution vs Operating Cost
          </p>
          <div className="flex items-center">
            <div
              className={`w-4 h-4 rounded-full mr-2 ${
                metrics.isEfficient ? "bg-green-500" : "bg-red-500"
              }`}
            />
            <p
              className={`text-2xl font-bold ${
                metrics.isEfficient
                  ? "text-green-600 dark:text-green-400"
                  : "text-red-600 dark:text-red-400"
              }`}
            >
              {metrics.isEfficient ? "Efficient" : "Inefficient"}
            </p>
          </div>
          <p className="text-sm text-gray-600 dark:text-gray-400 mt-2">
            {metrics.isEfficient
              ? "Employee contribution exceeds operating costs"
              : "Operating costs exceed employee contribution"}
          </p>
        </div>
      </div>

      {/* Staff Count */}
      {period.operational_metrics && (
        <div className="p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
          <p className="text-sm text-gray-600 dark:text-gray-400">
            Total Staff Count:{" "}
            <span className="font-semibold text-gray-900 dark:text-white">
              {period.operational_metrics.staff_count}
            </span>
          </p>
        </div>
      )}
    </div>
  );
};

export default ProductivityAnalysis;
