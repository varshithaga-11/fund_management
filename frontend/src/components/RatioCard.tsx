import React from "react";
import { TrendingUp, AlertCircle, CheckCircle } from "lucide-react";

interface RatioCardProps {
  name: string;
  value: number;
  unit?: string;
  idealValue?: number;
  status?: "green" | "yellow" | "red";
  description?: string;
}

const RatioCard: React.FC<RatioCardProps> = ({
  name,
  value,
  unit = "%",
  idealValue,
  status,
  description,
}) => {
  const getGradientBg = () => {
    switch (status) {
      case "green":
        return "bg-gradient-to-br from-emerald-50 to-green-50 dark:from-emerald-950/30 dark:to-green-950/30 border-emerald-200 dark:border-emerald-800 hover:shadow-green-100/50";
      case "yellow":
        return "bg-gradient-to-br from-amber-50 to-yellow-50 dark:from-amber-950/30 dark:to-yellow-950/30 border-amber-200 dark:border-amber-800 hover:shadow-amber-100/50";
      case "red":
        return "bg-gradient-to-br from-red-50 to-rose-50 dark:from-red-950/30 dark:to-rose-950/30 border-red-200 dark:border-red-800 hover:shadow-red-100/50";
      default:
        return "bg-gradient-to-br from-slate-50 to-gray-50 dark:from-slate-900/40 dark:to-gray-900/40 border-slate-200 dark:border-slate-700 hover:shadow-slate-100/50";
    }
  };

  const getStatusIcon = () => {
    switch (status) {
      case "green":
        return (
          <div className="flex items-center justify-center w-10 h-10 rounded-full bg-emerald-100 dark:bg-emerald-900/40">
            <CheckCircle className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
          </div>
        );
      case "yellow":
        return (
          <div className="flex items-center justify-center w-10 h-10 rounded-full bg-amber-100 dark:bg-amber-900/40">
            <AlertCircle className="w-5 h-5 text-amber-600 dark:text-amber-400" />
          </div>
        );
      case "red":
        return (
          <div className="flex items-center justify-center w-10 h-10 rounded-full bg-red-100 dark:bg-red-900/40">
            <AlertCircle className="w-5 h-5 text-red-600 dark:text-red-400" />
          </div>
        );
      default:
        return (
          <div className="flex items-center justify-center w-10 h-10 rounded-full bg-slate-100 dark:bg-slate-800/40">
            <TrendingUp className="w-5 h-5 text-slate-600 dark:text-slate-400" />
          </div>
        );
    }
  };

  const getVarianceColor = () => {
    if (!idealValue) return "text-gray-600 dark:text-gray-400";
    const variance = ((value - idealValue) / idealValue) * 100;
    if (variance > 10) return "text-emerald-600 dark:text-emerald-400";
    if (variance > -10) return "text-amber-600 dark:text-amber-400";
    return "text-red-600 dark:text-red-400";
  };

  const getVarianceValue = () => {
    if (!idealValue) return null;
    const variance = ((value - idealValue) / idealValue) * 100;
    const sign = variance > 0 ? "+" : "";
    return `${sign}${variance.toFixed(1)}%`;
  };

  const formatValue = (val: number) => {
    if (unit === "times" || unit === "") {
      return val.toLocaleString("en-IN", {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      });
    }
    return val.toLocaleString("en-IN", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    });
  };

  return (
    <div
      className={`group relative p-6 rounded-xl border-2 ${getGradientBg()} transition-all duration-300 hover:shadow-xl hover:-translate-y-1 cursor-default overflow-hidden`}
    >
      {/* Decorative background element */}
      <div className="absolute top-0 right-0 w-20 h-20 opacity-5 dark:opacity-10 rounded-full blur-2xl transform translate-x-8 -translate-y-8 group-hover:scale-150 transition-transform duration-500" />

      {/* Header with icon and status */}
      <div className="flex items-start justify-between mb-4 relative z-10">
        <div className="flex-1">
          <h4 className="text-sm font-bold text-gray-800 dark:text-gray-200 mb-2 uppercase tracking-wide">
            {name}
          </h4>
          {description && (
            <p className="text-xs text-gray-600 dark:text-gray-400 line-clamp-2">
              {description}
            </p>
          )}
        </div>
        <div className="ml-3 flex-shrink-0">
          {getStatusIcon()}
        </div>
      </div>

      {/* Main value display */}
      <div className="mt-4 relative z-10">
        <div className="flex items-baseline gap-2">
          <div className="text-4xl font-black text-gray-900 dark:text-white leading-none">
            {formatValue(value)}
          </div>
          <div className="text-sm font-semibold text-gray-600 dark:text-gray-400">
            {unit}
          </div>
        </div>

        {/* Ideal value and variance */}
        {idealValue !== undefined && (
          <div className="mt-3 pt-3 border-t border-gray-300/50 dark:border-gray-600/50 space-y-1">
            <div className="flex items-center justify-between">
              <span className="text-xs font-medium text-gray-600 dark:text-gray-400">
                Ideal Value
              </span>
              <span className="text-sm font-semibold text-gray-700 dark:text-gray-300">
                {formatValue(idealValue)} {unit}
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-xs font-medium text-gray-600 dark:text-gray-400">
                Variance
              </span>
              <span className={`text-sm font-bold ${getVarianceColor()}`}>
                {getVarianceValue()}
              </span>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default RatioCard;
