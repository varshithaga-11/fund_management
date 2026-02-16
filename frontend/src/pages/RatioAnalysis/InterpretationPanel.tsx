import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { getRatioResults, RatioResultData, getFinancialPeriod, FinancialPeriodData } from "../FinancialStatements/api";
import { BeatLoader } from "react-spinners";
import { toast } from "react-toastify";
import { ArrowLeft } from "lucide-react";

const InterpretationPanel: React.FC = () => {
  const { periodId } = useParams<{ periodId: string }>();
  const navigate = useNavigate();
  const [ratios, setRatios] = useState<RatioResultData | null>(null);
  const [period, setPeriod] = useState<FinancialPeriodData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (periodId) {
      loadData();
    }
  }, [periodId]);

  const loadData = async () => {
    if (!periodId) return;
    setLoading(true);
    try {
      const [ratioData, periodData] = await Promise.all([
        getRatioResults(parseInt(periodId)),
        getFinancialPeriod(parseInt(periodId)),
      ]);
      setRatios(ratioData);
      setPeriod(periodData);
    } catch (error) {
      console.error("Error loading ratio data:", error);
      toast.error("Failed to load ratio data");
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <BeatLoader color="#3b82f6" />
      </div>
    );
  }

  if (!ratios) {
    return (
      <div className="p-6">
        <p className="text-red-600 dark:text-red-400">
          No ratio data found. Please calculate ratios first.
        </p>
      </div>
    );
  }

  const getKeyInsights = () => {
    const insights: string[] = [];

    // Credit Deposit Ratio
    if (ratios.credit_deposit_ratio > 70) {
      insights.push("✓ High efficiency in deploying resources");
    } else {
      insights.push("⚠ Under-utilization of mobilized deposits");
    }

    // Cost effectiveness
    if (
      ratios.cost_of_deposits > 0 &&
      ratios.yield_on_loans > 0 &&
      ratios.cost_of_deposits < ratios.yield_on_loans - 4
    ) {
      insights.push("✓ Cost-effective deposit management");
    } else {
      insights.push("⚠ Deposit costs are relatively high compared to loan yields");
    }

    // Net Margin
    if (ratios.net_margin >= 1.0) {
      insights.push("✓ Healthy profitability");
    } else if (ratios.net_margin >= 0.5) {
      insights.push("⚠ Moderate profitability - room for improvement");
    } else {
      insights.push("✗ Low profitability - requires immediate attention");
    }

    // Risk Cost
    if (ratios.risk_cost_to_wf && ratios.risk_cost_to_wf > 0.25) {
      insights.push("✗ High risk exposure - review provisions");
    } else if (ratios.risk_cost_to_wf && ratios.risk_cost_to_wf > 0.15) {
      insights.push("⚠ Moderate risk exposure");
    } else {
      insights.push("✓ Low risk exposure");
    }

    // Stock Turnover
    if (ratios.stock_turnover >= 15) {
      insights.push("✓ Good inventory management");
    } else if (ratios.stock_turnover >= 10) {
      insights.push("⚠ Adequate inventory turnover");
    } else {
      insights.push("✗ Low inventory turnover - review stock management");
    }

    // Fund Structure
    if (ratios.loans_to_wf && ratios.loans_to_wf < 70) {
      insights.push("⚠ Loans deployment below optimal level");
    } else if (ratios.loans_to_wf && ratios.loans_to_wf > 75) {
      insights.push("⚠ High loan deployment - ensure adequate liquidity");
    }

    return insights;
  };

  const getRecommendations = () => {
    const recommendations: string[] = [];

    if (ratios.net_margin < 1.0) {
      recommendations.push(
        "Focus on improving net margin by reducing operating costs or increasing income"
      );
    }

    if (ratios.risk_cost_to_wf && ratios.risk_cost_to_wf > 0.25) {
      recommendations.push(
        "Review and optimize provisions to reduce risk cost"
      );
    }

    if (ratios.credit_deposit_ratio < 70) {
      recommendations.push(
        "Increase loan deployment to improve credit deposit ratio"
      );
    }

    if (ratios.stock_turnover < 15) {
      recommendations.push(
        "Improve inventory management to increase stock turnover"
      );
    }

    if (
      ratios.operating_cost_to_wf &&
      ratios.operating_cost_to_wf > 2.5
    ) {
      recommendations.push(
        "Review operating expenses to reduce operating cost to working fund ratio"
      );
    }

    return recommendations;
  };

  const insights = getKeyInsights();
  const recommendations = getRecommendations();

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
              Interpretation Analysis
            </h1>
            {period && (
              <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                {period.label}
              </p>
            )}
          </div>
        </div>
      </div>

      {/* Interpretation Text */}
      {ratios.interpretation && (
        <div className="p-6 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-3">
            Summary Interpretation
          </h2>
          <p className="text-gray-700 dark:text-gray-300 leading-relaxed">
            {ratios.interpretation}
          </p>
        </div>
      )}

      {/* Key Insights */}
      <div className="p-6 bg-white dark:bg-gray-800 rounded-lg shadow-md border border-gray-200 dark:border-gray-700">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          Key Insights
        </h2>
        <ul className="space-y-2">
          {insights.map((insight, index) => (
            <li
              key={index}
              className="flex items-start text-gray-700 dark:text-gray-300"
            >
              <span className="mr-2">{insight}</span>
            </li>
          ))}
        </ul>
      </div>

      {/* Recommendations */}
      {recommendations.length > 0 && (
        <div className="p-6 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg border border-yellow-200 dark:border-yellow-800">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            Recommendations
          </h2>
          <ul className="space-y-2">
            {recommendations.map((rec, index) => (
              <li
                key={index}
                className="flex items-start text-gray-700 dark:text-gray-300"
              >
                <span className="mr-2">•</span>
                <span>{rec}</span>
              </li>
            ))}
          </ul>
        </div>
      )}

      {/* Risk Warnings */}
      <div className="p-6 bg-red-50 dark:bg-red-900/20 rounded-lg border border-red-200 dark:border-red-800">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          Risk Warnings
        </h2>
        <ul className="space-y-2">
          {ratios.risk_cost_to_wf && ratios.risk_cost_to_wf > 0.25 && (
            <li className="text-red-700 dark:text-red-300">
              ⚠ High risk cost ({Number(ratios.risk_cost_to_wf).toFixed(2)}%) exceeds
              ideal threshold (0.25%)
            </li>
          )}
          {ratios.net_margin < 0.5 && (
            <li className="text-red-700 dark:text-red-300">
              ⚠ Net margin ({Number(ratios.net_margin).toFixed(2)}%) is critically low
            </li>
          )}
          {ratios.credit_deposit_ratio < 50 && (
            <li className="text-red-700 dark:text-red-300">
              ⚠ Very low credit deposit ratio ({Number(ratios.credit_deposit_ratio).toFixed(2)}%)
              indicates poor resource utilization
            </li>
          )}
          {insights.length === 0 && (
            <li className="text-gray-600 dark:text-gray-400">
              No critical risk warnings at this time
            </li>
          )}
        </ul>
      </div>
    </div>
  );
};

export default InterpretationPanel;
