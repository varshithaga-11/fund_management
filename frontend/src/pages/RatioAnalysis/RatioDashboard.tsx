import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import {
  getFinancialPeriod,
  getRatioResults,
  RatioResultData,
  FinancialPeriodData,
} from "../FinancialStatements/api";
import RatioCard from "../../components/RatioCard";
import RatioAnalysisTable from "../../components/RatioAnalysisTable";
import { BeatLoader } from "react-spinners";
import { toast, ToastContainer } from "react-toastify";
import { LayoutGrid, Table, ArrowLeft, BarChart3, MessageSquare, Download, FileText, ChevronDown } from "lucide-react";
import "react-toastify/dist/ReactToastify.css";
import PeriodDataEditForm from "../CompanyRatioAnalysis/PeriodDataEditForm";
import { createApiUrl } from "../../access/access";
import * as XLSX from "xlsx";
import { jsPDF } from "jspdf";
import type { jsPDF as jsPDFType } from "jspdf";
import "jspdf-autotable";

const RatioDashboard: React.FC = () => {
  const { periodId } = useParams<{ periodId: string }>();
  const navigate = useNavigate();
  const [ratios, setRatios] = useState<RatioResultData | null>(null);
  const [period, setPeriod] = useState<FinancialPeriodData | null>(null);
  const [loading, setLoading] = useState(true);
  const [viewMode, setViewMode] = useState<"cards" | "table">("cards");
  const [validPeriodId, setValidPeriodId] = useState<number | null>(null);
  const [showExportMenu, setShowExportMenu] = useState(false);

  // Validate and parse periodId on initial load
  useEffect(() => {
    if (!periodId) {
      // No periodId provided - silently redirect to periods list
      navigate('/ratio-analysis', { replace: true });
      return;
    }

    const parsed = parseInt(periodId, 10);
    if (isNaN(parsed) || parsed <= 0) {
      // Only log error for invalid (non-numeric) periodIds, not undefined
      console.warn("Invalid periodId from URL:", periodId);
      setLoading(false);
      setValidPeriodId(null);
      return;
    }

    setValidPeriodId(parsed);
    loadData(parsed);
  }, [periodId, navigate]);

  // Close export menu when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as HTMLElement;
      if (!target.closest(".export-menu-container")) {
        setShowExportMenu(false);
      }
    };

    if (showExportMenu) {
      document.addEventListener("mousedown", handleClickOutside);
      return () => document.removeEventListener("mousedown", handleClickOutside);
    }
  }, [showExportMenu]);

  const loadData = async (id: number) => {
    setLoading(true);
    try {
      const [ratioData, periodData] = await Promise.all([
        getRatioResults(id),
        getFinancialPeriod(id),
      ]);

      // If period doesn't exist, treat as invalid period
      if (!periodData) {
        console.warn("Period not found:", id);
        setValidPeriodId(null);
        setLoading(false);
        return;
      }

      setRatios(ratioData);
      setPeriod(periodData);
    } catch (error: any) {
      // Check if it's a 404 error (period not found)
      if (error.response?.status === 404) {
        console.warn("Period not found (404):", id);
        setValidPeriodId(null);
      } else {
        console.error("Error loading ratio data:", error);
        toast.error("Failed to load ratio data");
      }
    } finally {
      setLoading(false);
    }
  };

  const handleDataUpdate = () => {
    if (validPeriodId) {
      loadData(validPeriodId);
    }
    toast.success("Period data updated and ratio results recalculated.");
  };

  const exportToExcel = () => {
    if (!ratios || !period) {
      toast.error("No data to export");
      return;
    }

    try {
      const workbook = XLSX.utils.book_new();

      // Sheet 1: Summary
      const summaryData = [
        ["PERIOD DETAILS"],
        ["Period Label", period.label],
        ["Period Type", period.period_type],
        ["Start Date", period.start_date],
        ["End Date", period.end_date],
        ["Is Finalized", period.is_finalized ? "Yes" : "No"],
        ["Calculated At", new Date(ratios.calculated_at).toLocaleDateString()],
        [],
        ["KEY METRICS"],
        ["Working Fund", ratios.working_fund],
        [],
        ["TRADING RATIOS"],
        ["Stock Turnover", ratios.stock_turnover, ratios.traffic_light_status?.stock_turnover || ""],
        ["Gross Profit Ratio", ratios.gross_profit_ratio, ratios.traffic_light_status?.gross_profit_ratio || ""],
        ["Net Profit Ratio", ratios.net_profit_ratio, ratios.traffic_light_status?.net_profit_ratio || ""],
        [],
        ["CAPITAL EFFICIENCY"],
        ["Capital Turnover Ratio", ratios.capital_turnover_ratio || 0, ratios.traffic_light_status?.capital_turnover_ratio || ""],
        [],
        ["FUND STRUCTURE RATIOS"],
        ["Net Own Funds", ratios.net_own_funds || 0, ""],
        ["Own Fund to WF", ratios.own_fund_to_wf || 0, ratios.traffic_light_status?.own_fund_to_wf || ""],
        ["Deposits to WF", ratios.deposits_to_wf || 0, ratios.traffic_light_status?.deposits_to_wf || ""],
        ["Borrowings to WF", ratios.borrowings_to_wf || 0, ratios.traffic_light_status?.borrowings_to_wf || ""],
        ["Loans to WF", ratios.loans_to_wf || 0, ratios.traffic_light_status?.loans_to_wf || ""],
        ["Investments to WF", ratios.investments_to_wf || 0, ratios.traffic_light_status?.investments_to_wf || ""],
        ["Earning Assets to WF", ratios.earning_assets_to_wf || 0, ratios.traffic_light_status?.earning_assets_to_wf || ""],
        ["Interest Tagged Funds to WF", ratios.interest_tagged_funds_to_wf || 0, ratios.traffic_light_status?.interest_tagged_funds_to_wf || ""],
        [],
        ["YIELD & COST RATIOS"],
        ["Cost of Deposits", ratios.cost_of_deposits, ratios.traffic_light_status?.cost_of_deposits || ""],
        ["Yield on Loans", ratios.yield_on_loans, ratios.traffic_light_status?.yield_on_loans || ""],
        ["Yield on Investments", ratios.yield_on_investments || 0, ratios.traffic_light_status?.yield_on_investments || ""],
        ["Credit Deposit Ratio", ratios.credit_deposit_ratio, ratios.traffic_light_status?.credit_deposit_ratio || ""],
        ["Avg Cost of WF", ratios.avg_cost_of_wf || 0, ratios.traffic_light_status?.avg_cost_of_wf || ""],
        ["Avg Yield on WF", ratios.avg_yield_on_wf || 0, ratios.traffic_light_status?.avg_yield_on_wf || ""],
        ["Misc Income to WF", ratios.misc_income_to_wf || 0, ratios.traffic_light_status?.misc_income_to_wf || ""],
        ["Interest Exp to Interest Income", ratios.interest_exp_to_interest_income || 0, ratios.traffic_light_status?.interest_exp_to_interest_income || ""],
        [],
        ["MARGIN RATIOS"],
        ["Gross Financial Margin", ratios.gross_fin_margin, ratios.traffic_light_status?.gross_fin_margin || ""],
        ["Operating Cost to WF", ratios.operating_cost_to_wf || 0, ratios.traffic_light_status?.operating_cost_to_wf || ""],
        ["Net Financial Margin", ratios.net_fin_margin, ratios.traffic_light_status?.net_fin_margin || ""],
        ["Risk Cost to WF", ratios.risk_cost_to_wf || 0, ratios.traffic_light_status?.risk_cost_to_wf || ""],
        ["Net Margin", ratios.net_margin, ratios.traffic_light_status?.net_margin || ""],
        [],
        ["PRODUCTIVITY RATIOS"],
        ["Per Employee Deposit", ratios.per_employee_deposit || 0, ratios.traffic_light_status?.per_employee_deposit || ""],
        ["Per Employee Loan", ratios.per_employee_loan || 0, ratios.traffic_light_status?.per_employee_loan || ""],
        ["Per Employee Contribution", ratios.per_employee_contribution || 0, ratios.traffic_light_status?.per_employee_contribution || ""],
        ["Per Employee Operating Cost", ratios.per_employee_operating_cost || 0, ratios.traffic_light_status?.per_employee_operating_cost || ""],
      ];
      const summarySheet = XLSX.utils.aoa_to_sheet(summaryData);
      summarySheet["!cols"] = [{ wch: 30 }, { wch: 20 }, { wch: 15 }];
      XLSX.utils.book_append_sheet(workbook, summarySheet, "All Details");

      // Generate filename
      const fileName = `RatioAnalysis_${period.label}_${new Date().toISOString().split("T")[0]}.xlsx`;
      XLSX.writeFile(workbook, fileName);
      toast.success("Exported to Excel successfully!");
    } catch (error) {
      console.error("Error exporting to Excel:", error);
      toast.error("Failed to export to Excel");
    }
  };

  const exportToPDF = () => {
    if (!ratios || !period) {
      toast.error("No data to export");
      return;
    }

    try {
      const pdf = new jsPDF() as jsPDFType & {
        autoTable?: (options: any) => jsPDFType;
        lastAutoTable?: { finalY: number };
      };
      const pageWidth = pdf.internal.pageSize.getWidth();
      const pageHeight = pdf.internal.pageSize.getHeight();
      let yPos = 15;

      // Helper function to add section
      const addSection = (title: string, data: string[][], startY: number) => {
        pdf.setFontSize(12);
        pdf.setFont("helvetica", "bold");
        pdf.text(title, 15, startY);
        let sectionY = startY + 8;

        if (pdf.autoTable && typeof pdf.autoTable === "function") {
          pdf.autoTable({
            startY: sectionY,
            head: [data[0]],
            body: data.slice(1),
            margin: { left: 15, right: 15 },
            theme: "grid",
            headStyles: {
              fillColor: [59, 130, 246],
              textColor: [255, 255, 255],
              fontStyle: "bold",
              font: "helvetica",
              fontSize: 9,
            },
            bodyStyles: {
              font: "helvetica",
              fontSize: 8,
            },
            alternateRowStyles: {
              fillColor: [245, 245, 245],
            },
            columnStyles: {
              0: { halign: "left" },
              1: { halign: "right" },
              2: { halign: "center" },
            },
          });
          return pdf.lastAutoTable?.finalY || sectionY + 50;
        } else {
          // Fallback: manual table
          const col1Width = 50;
          const col2Width = 35;
          const col3Width = 25;

          pdf.setFillColor(59, 130, 246);
          pdf.setTextColor(255, 255, 255);
          pdf.rect(15, sectionY - 4, col1Width + col2Width + col3Width, 5, "F");
          pdf.setFontSize(8);
          pdf.text(data[0][0], 17, sectionY);
          pdf.text(data[0][1], 15 + col1Width + 2, sectionY);
          pdf.text(data[0][2], 15 + col1Width + col2Width + 2, sectionY);
          sectionY += 7;

          pdf.setTextColor(0, 0, 0);
          data.slice(1).forEach((row, idx) => {
            if (idx % 2 === 0) {
              pdf.setFillColor(245, 245, 245);
              pdf.rect(15, sectionY - 4, col1Width + col2Width + col3Width, 5, "F");
            }
            pdf.text(row[0], 17, sectionY);
            pdf.text(row[1], 15 + col1Width + 2, sectionY);
            pdf.text(row[2], 15 + col1Width + col2Width + 2, sectionY);
            sectionY += 5;
          });
          return sectionY + 5;
        }
      };

      // Title
      pdf.setFontSize(18);
      pdf.setFont("helvetica", "bold");
      pdf.text("Ratio Analysis Report - Complete Details", pageWidth / 2, yPos, { align: "center" });
      pdf.setFont("helvetica", "normal");
      yPos += 12;

      // Period Information
      pdf.setFontSize(10);
      pdf.text(`Period: ${period.label} | Type: ${period.period_type}`, 15, yPos);
      yPos += 5;
      pdf.text(`From ${period.start_date} to ${period.end_date} | Finalized: ${period.is_finalized ? "Yes" : "No"}`, 15, yPos);
      yPos += 5;
      pdf.text(`Working Fund: ₹${Number(ratios.working_fund).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`, 15, yPos);
      yPos += 10;

      // Trading Ratios
      const tradingData = [
        ["Metric", "Value", "Status"],
        ["Stock Turnover", String(Number(ratios.stock_turnover || 0).toFixed(2)), String(ratios.traffic_light_status?.stock_turnover || "-")],
        ["Gross Profit Ratio %", String(Number(Number(ratios.gross_profit_ratio || 0) * 100).toFixed(2)), String(ratios.traffic_light_status?.gross_profit_ratio || "-")],
        ["Net Profit Ratio %", String(Number(Number(ratios.net_profit_ratio || 0) * 100).toFixed(2)), String(ratios.traffic_light_status?.net_profit_ratio || "-")],
      ];
      yPos = addSection("TRADING RATIOS", tradingData, yPos) + 8;

      // Fund Structure
      const fundStructureData = [
        ["Metric", "Value", "Status"],
        ["Net Own Funds", String(Number(ratios.net_own_funds || 0).toFixed(2)), ""],
        ["Own Fund to WF %", String(Number(ratios.own_fund_to_wf || 0).toFixed(2)), String(ratios.traffic_light_status?.own_fund_to_wf || "-")],
        ["Deposits to WF %", String(Number(ratios.deposits_to_wf || 0).toFixed(2)), String(ratios.traffic_light_status?.deposits_to_wf || "-")],
        ["Borrowings to WF %", String(Number(ratios.borrowings_to_wf || 0).toFixed(2)), String(ratios.traffic_light_status?.borrowings_to_wf || "-")],
        ["Loans to WF %", String(Number(ratios.loans_to_wf || 0).toFixed(2)), String(ratios.traffic_light_status?.loans_to_wf || "-")],
      ];
      yPos = addSection("FUND STRUCTURE", fundStructureData, yPos) + 8;

      // Add page break if needed
      if (yPos > pageHeight - 60) {
        pdf.addPage();
        yPos = 15;
      }

      // Yield & Cost
      const yieldCostData = [
        ["Metric", "Value", "Status"],
        ["Cost of Deposits %", String(Number(Number(ratios.cost_of_deposits || 0) * 100).toFixed(2)), String(ratios.traffic_light_status?.cost_of_deposits || "-")],
        ["Yield on Loans %", String(Number(Number(ratios.yield_on_loans || 0) * 100).toFixed(2)), String(ratios.traffic_light_status?.yield_on_loans || "-")],
        ["Yield on Investments %", String(Number(Number(ratios.yield_on_investments || 0) * 100).toFixed(2)), String(ratios.traffic_light_status?.yield_on_investments || "-")],
        ["Credit Deposit Ratio %", String(Number(ratios.credit_deposit_ratio || 0).toFixed(2)), String(ratios.traffic_light_status?.credit_deposit_ratio || "-")],
        ["Avg Cost of WF %", String(Number(Number(ratios.avg_cost_of_wf || 0) * 100).toFixed(2)), String(ratios.traffic_light_status?.avg_cost_of_wf || "-")],
      ];
      yPos = addSection("YIELD & COST RATIOS", yieldCostData, yPos) + 8;

      // Margin Ratios
      const marginData = [
        ["Metric", "Value", "Status"],
        ["Gross Financial Margin %", String(Number(Number(ratios.gross_fin_margin || 0) * 100).toFixed(2)), String(ratios.traffic_light_status?.gross_fin_margin || "-")],
        ["Operating Cost to WF %", String(Number(Number(ratios.operating_cost_to_wf || 0) * 100).toFixed(2)), String(ratios.traffic_light_status?.operating_cost_to_wf || "-")],
        ["Net Financial Margin %", String(Number(Number(ratios.net_fin_margin || 0) * 100).toFixed(2)), String(ratios.traffic_light_status?.net_fin_margin || "-")],
        ["Risk Cost to WF %", String(Number(Number(ratios.risk_cost_to_wf || 0) * 100).toFixed(2)), String(ratios.traffic_light_status?.risk_cost_to_wf || "-")],
        ["Net Margin %", String(Number(Number(ratios.net_margin || 0) * 100).toFixed(2)), String(ratios.traffic_light_status?.net_margin || "-")],
      ];
      yPos = addSection("MARGIN RATIOS", marginData, yPos) + 8;

      // Add page break if needed
      if (yPos > pageHeight - 60) {
        pdf.addPage();
        yPos = 15;
      }

      // Productivity Ratios
      const productivityData = [
        ["Metric", "Value", "Status"],
        ["Per Employee Deposit", String(Number(ratios.per_employee_deposit || 0).toFixed(2)), String(ratios.traffic_light_status?.per_employee_deposit || "-")],
        ["Per Employee Loan", String(Number(ratios.per_employee_loan || 0).toFixed(2)), String(ratios.traffic_light_status?.per_employee_loan || "-")],
        ["Per Employee Contribution", String(Number(ratios.per_employee_contribution || 0).toFixed(2)), String(ratios.traffic_light_status?.per_employee_contribution || "-")],
        ["Per Employee Operating Cost", String(Number(ratios.per_employee_operating_cost || 0).toFixed(2)), String(ratios.traffic_light_status?.per_employee_operating_cost || "-")],
      ];
      yPos = addSection("PRODUCTIVITY RATIOS", productivityData, yPos) + 8;

      // Footer
      pdf.setFontSize(8);
      pdf.setTextColor(128, 128, 128);
      const footerText = `Generated on ${new Date().toLocaleString()}`;
      const approxTextWidth = footerText.length * 1.5;
      pdf.text(footerText, (pageWidth - approxTextWidth) / 2, pageHeight - 10);

      // Save the PDF
      const fileName = `RatioAnalysis_${period.label}_${new Date().toISOString().split("T")[0]}.pdf`;
      pdf.save(fileName);
      toast.success("Exported to PDF successfully!");
    } catch (error) {
      console.error("PDF Export Error:", error);
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error("Error details:", errorMsg);
      toast.error(`Failed to export to PDF: ${errorMsg}`);
    }
  };

  // Show error if period ID is invalid
  if (validPeriodId === null && !loading) {
    return (
      <div className="p-6 min-h-screen flex items-center justify-center">
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8 max-w-md text-center">
          <div className="mb-4">
            <div className="flex justify-center mb-4">
              <div className="h-16 w-16 rounded-full bg-red-100 dark:bg-red-900/30 flex items-center justify-center">
                <svg className="h-8 w-8 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4v.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>
            <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-2">
              Invalid Period ID
            </h2>
            <p className="text-gray-600 dark:text-gray-400 mb-6">
              The period ID in the URL is invalid or not found. Please select a period from the dashboard.
            </p>
          </div>
          <button
            onClick={() => navigate('/ratio-analysis')}
            className="w-full px-4 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors"
          >
            Back to All Periods
          </button>
        </div>
      </div>
    );
  }

  // Don't render anything while redirecting (when validPeriodId is null and loading is true)
  if (validPeriodId === null) {
    return null;
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <BeatLoader color="#3b82f6" />
      </div>
    );
  }

  if (!ratios) {
    return (
      <div className="p-6 min-h-screen flex items-center justify-center">
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8 max-w-md text-center">
          <div className="mb-4">
            <div className="flex justify-center mb-4">
              <div className="h-16 w-16 rounded-full bg-yellow-100 dark:bg-yellow-900/30 flex items-center justify-center">
                <svg className="h-8 w-8 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>
            <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-2">
              Ratios Not Calculated Yet
            </h2>
            <p className="text-gray-600 dark:text-gray-400 mb-2">
              Financial ratio analysis hasn't been calculated for this period.
            </p>
            <p className="text-sm text-gray-500 dark:text-gray-400 mb-6">
              Click the button below to view the period data and calculate ratios.
            </p>
          </div>
          <div className="space-y-3">
            <button
              onClick={() => navigate(`/financial-statements/${periodId}`)}
              className="w-full px-4 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors"
            >
              Go to Period Data & Calculate
            </button>
            <button
              onClick={() => navigate('/ratio-analysis')}
              className="w-full px-4 py-3 bg-gray-200 dark:bg-gray-700 text-gray-900 dark:text-white rounded-lg font-medium transition-colors hover:bg-gray-300 dark:hover:bg-gray-600"
            >
              Back to All Periods
            </button>
          </div>
        </div>
      </div>
    );
  }

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

  const capitalEfficiencyRatios = [
    {
      name: "Capital Turnover Ratio",
      value: ratios.capital_turnover_ratio || 0,
      unit: "times",
      idealValue: 6.0,
      status: ratios.traffic_light_status?.capital_turnover_ratio,
    },
  ];

  const fundStructureRatios = [
    {
      name: "Net Own Funds",
      value: ratios.net_own_funds || 0,
      unit: "",
      status: (ratios.net_own_funds && ratios.net_own_funds > 0 ? "green" : "red") as "green" | "red",
    },
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
    {
      name: "Earning Assets to Working Fund",
      value: ratios.earning_assets_to_wf || 0,
      unit: "%",
      idealValue: 80.0,
      status: ratios.traffic_light_status?.earning_assets_to_wf,
    },
    {
      name: "Interest Tagged Funds to Working Fund",
      value: ratios.interest_tagged_funds_to_wf || 0,
      unit: "%",
      status: ratios.traffic_light_status?.interest_tagged_funds_to_wf,
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
    {
      name: "Miscellaneous Income to WF",
      value: ratios.misc_income_to_wf || 0,
      unit: "%",
      idealValue: 0.50,
      status: ratios.traffic_light_status?.misc_income_to_wf,
    },
    {
      name: "Interest Expenses to Interest Income",
      value: ratios.interest_exp_to_interest_income || 0,
      unit: "%",
      idealValue: 62.0,
      status: ratios.traffic_light_status?.interest_exp_to_interest_income,
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

  const productivityRatios = [
    {
      name: "Per Employee Deposit",
      value: ratios.per_employee_deposit || 0,
      unit: " Lakhs",
      idealValue: 200.0,
      status: ratios.traffic_light_status?.per_employee_deposit,
    },
    {
      name: "Per Employee Loan",
      value: ratios.per_employee_loan || 0,
      unit: " Lakhs",
      idealValue: 150.0,
      status: ratios.traffic_light_status?.per_employee_loan,
    },
    {
      name: "Per Employee Contribution",
      value: ratios.per_employee_contribution || 0,
      unit: " Lakhs",
      status: ratios.traffic_light_status?.per_employee_contribution,
    },
    {
      name: "Per Employee Operating Cost",
      value: ratios.per_employee_operating_cost || 0,
      unit: " Lakhs",
      status: ratios.traffic_light_status?.per_employee_operating_cost,
    },
  ];

  return (
    <div className="p-6 space-y-6">
      <ToastContainer position="bottom-right" autoClose={3000} />

      {/* Header */}
      <div className="flex justify-between items-start gap-4">
        <div>
          <button
            onClick={() => navigate('/ratio-analysis')}
            className="flex items-center gap-2 text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 mb-2 transition-colors"
          >
            <ArrowLeft size={20} />
            <span>Back to Periods</span>
          </button>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Ratio Analysis Dashboard
          </h1>
          {period && (
            <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
              {period.label} - Calculated on{" "}
              {new Date(ratios.calculated_at).toLocaleDateString()}
            </p>
          )}
        </div>

        {/* View Toggle & Quick Actions */}
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          {/* View Toggle */}
          <div className="flex gap-2 bg-gray-100 dark:bg-gray-800 rounded-lg p-1">
            <button
              onClick={() => setViewMode("cards")}
              className={`px-4 py-2 rounded flex items-center gap-2 transition-colors ${viewMode === "cards"
                ? "bg-blue-600 text-white"
                : "bg-transparent text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
                }`}
            >
              <LayoutGrid className="w-4 h-4" />
              Cards
            </button>
            <button
              onClick={() => setViewMode("table")}
              className={`px-4 py-2 rounded flex items-center gap-2 transition-colors ${viewMode === "table"
                ? "bg-blue-600 text-white"
                : "bg-transparent text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
                }`}
            >
              <Table className="w-4 h-4" />
              Table
            </button>
          </div>

          {/* Quick Action Buttons */}
          <div className="flex gap-2">
            <button
              onClick={() => navigate(`/productivity-analysis/${periodId}`)}
              className="flex items-center gap-2 px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors font-medium"
              title="View detailed productivity metrics"
            >
              <BarChart3 size={18} />
              <span className="hidden sm:inline">Productivity</span>
            </button>
            <button
              onClick={() => navigate(`/interpretation/${periodId}`)}
              className="flex items-center gap-2 px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg transition-colors font-medium"
              title="View automated interpretation"
            >
              <MessageSquare size={18} />
              <span className="hidden sm:inline">Interpretation</span>
            </button>

            {/* Export Dropdown Button */}
            <div className="relative export-menu-container">
              <button
                onClick={() => setShowExportMenu(!showExportMenu)}
                className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition-colors font-medium"
                title="Export options"
              >
                <Download size={18} />
                <span className="hidden sm:inline">Export</span>
                <ChevronDown size={16} className={`transition-transform ${showExportMenu ? "rotate-180" : ""}`} />
              </button>

              {/* Dropdown Menu */}
              {showExportMenu && (
                <div className="absolute right-0 mt-2 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-xl border border-gray-200 dark:border-gray-700 z-50">
                  <button
                    onClick={() => {
                      exportToExcel();
                      setShowExportMenu(false);
                    }}
                    className="w-full flex items-center gap-3 px-4 py-3 text-left hover:bg-gray-50 dark:hover:bg-gray-700 border-b border-gray-200 dark:border-gray-700 transition-colors"
                  >
                    <Download size={18} className="text-green-600" />
                    <div>
                      <p className="font-medium text-gray-900 dark:text-white">Excel</p>
                      <p className="text-xs text-gray-600 dark:text-gray-400">All details in xlsx</p>
                    </div>
                  </button>
                  <button
                    onClick={() => {
                      exportToPDF();
                      setShowExportMenu(false);
                    }}
                    className="w-full flex items-center gap-3 px-4 py-3 text-left hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                  >
                    <FileText size={18} className="text-red-600" />
                    <div>
                      <p className="font-medium text-gray-900 dark:text-white">PDF</p>
                      <p className="text-xs text-gray-600 dark:text-gray-400">Formatted report pdf</p>
                    </div>
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Uploaded File Link */}
      {period && period.uploaded_file && (() => {
        const fileUrl = period.uploaded_file.startsWith('http')
          ? period.uploaded_file
          : createApiUrl(period.uploaded_file);

        return (
          <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
            <a
              href={fileUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-3 hover:opacity-80 transition-opacity cursor-pointer"
            >
              {period.file_type === 'excel' && (
                <svg className="w-8 h-8 text-green-600 dark:text-green-400 flex-shrink-0" fill="currentColor" viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8l-6-6z"></path><path d="M14 2v6h6"></path><path d="M9 15l2 2 4-4" stroke="white" strokeWidth="1.5" fill="none"></path></svg>
              )}
              {period.file_type === 'docx' && (
                <svg className="w-8 h-8 text-blue-600 dark:text-blue-400 flex-shrink-0" fill="currentColor" viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8l-6-6z"></path><path d="M14 2v6h6"></path></svg>
              )}
              {period.file_type === 'pdf' && (
                <svg className="w-8 h-8 text-red-600 dark:text-red-400 flex-shrink-0" fill="currentColor" viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8l-6-6z"></path><path d="M14 2v6h6"></path></svg>
              )}
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-gray-900 dark:text-white truncate">
                  {period.uploaded_file.split('/').pop()?.split('_').slice(1).join('_') || 'Financial Document'}
                </p>
                <p className="text-xs text-gray-600 dark:text-gray-400">
                  {period.file_type?.toUpperCase()} file • Click to open
                </p>
              </div>
            </a>
          </div>
        );
      })()}

      {/* Working Fund Summary - Always Show */}
      <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
          Working Fund
        </h2>
        <p className="text-3xl font-bold text-blue-600 dark:text-blue-400">
          ₹{Number(ratios.working_fund).toLocaleString("en-IN", {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
          })}
        </p>
      </div>

      {/* Interpretation Section */}
      {ratios.interpretation && (
        <div className="bg-blue-50 dark:bg-blue-900/20 p-6 rounded-lg border border-blue-200 dark:border-blue-800">
          <h2 className="text-xl font-bold mb-2 text-gray-900 dark:text-white">
            Interpretation
          </h2>
          <p className="text-gray-700 dark:text-gray-300 leading-relaxed">
            {ratios.interpretation}
          </p>
        </div>
      )}

      {/* View-based Content */}
      {viewMode === "table" ? (
        <RatioAnalysisTable ratios={ratios} period={period?.label} />
      ) : (
        <>
          {/* Trading Ratios */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
              Trading Ratios
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {tradingRatios.map((ratio) => (
                <RatioCard key={ratio.name} {...ratio} />
              ))}
            </div>
          </div>

          {/* Capital Efficiency Ratios */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
              Capital Efficiency
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {capitalEfficiencyRatios.map((ratio) => (
                <RatioCard key={ratio.name} {...ratio} />
              ))}
            </div>
          </div>

          {/* Fund Structure Ratios */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
              Fund Structure Ratios
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {fundStructureRatios.map((ratio) => (
                <RatioCard key={ratio.name} {...ratio} />
              ))}
            </div>
          </div>

          {/* Yield & Cost Ratios */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
              Yield & Cost Ratios
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {yieldCostRatios.map((ratio) => (
                <RatioCard key={ratio.name} {...ratio} />
              ))}
            </div>
          </div>

          {/* Margin Ratios */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
              Margin Ratios
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {marginRatios.map((ratio) => (
                <RatioCard key={ratio.name} {...ratio} />
              ))}
            </div>
          </div>

          {/* Productivity Ratios */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
              Productivity Ratios
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {productivityRatios.map((ratio) => (
                <RatioCard key={ratio.name} {...ratio} />
              ))}
            </div>
          </div>
        </>
      )}

      {/* Legend - Only show in card view */}
      {viewMode === "cards" && (
        <div className="p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
          <h3 className="text-sm font-semibold text-gray-900 dark:text-white mb-3">
            Status Legend
          </h3>
          <div className="flex flex-wrap gap-4">
            <div className="flex items-center">
              <div className="w-3 h-3 rounded-full bg-green-500 mr-2" />
              <span className="text-sm text-gray-600 dark:text-gray-400">
                Meets or exceeds ideal
              </span>
            </div>
            <div className="flex items-center">
              <div className="w-3 h-3 rounded-full bg-yellow-500 mr-2" />
              <span className="text-sm text-gray-600 dark:text-gray-400">
                Sub-optimal but acceptable
              </span>
            </div>
            <div className="flex items-center">
              <div className="w-3 h-3 rounded-full bg-red-500 mr-2" />
              <span className="text-sm text-gray-600 dark:text-gray-400">
                Critical - requires attention
              </span>
            </div>
          </div>
        </div>
      )}

      {/* Edit period data */}
      {localStorage.getItem("userRole") === "master" && (
        <div className="mt-10 p-6 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
          <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-white">
            Edit period data & recalculate ratios
          </h2>
          <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
            Update Trading Account, Profit & Loss, Balance Sheet, and Operational Metrics. Then click &quot;Update data & recalculate ratios&quot; to save and store updated ratio results.
          </p>
          <PeriodDataEditForm
            periodId={parseInt(periodId!)}
            onSuccess={handleDataUpdate}
          />
        </div>
      )}
    </div>
  );
};
export default RatioDashboard;
