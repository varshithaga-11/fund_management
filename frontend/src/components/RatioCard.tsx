import React from "react";

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
  const getStatusColor = () => {
    switch (status) {
      case "green":
        return "bg-green-100 border-green-500 dark:bg-green-900/20 dark:border-green-500";
      case "yellow":
        return "bg-yellow-100 border-yellow-500 dark:bg-yellow-900/20 dark:border-yellow-500";
      case "red":
        return "bg-red-100 border-red-500 dark:bg-red-900/20 dark:border-red-500";
      default:
        return "bg-gray-100 border-gray-300 dark:bg-gray-800 dark:border-gray-700";
    }
  };

  const getStatusDot = () => {
    switch (status) {
      case "green":
        return "bg-green-500";
      case "yellow":
        return "bg-yellow-500";
      case "red":
        return "bg-red-500";
      default:
        return "bg-gray-400";
    }
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
      className={`p-4 rounded-lg border-2 ${getStatusColor()} transition-all hover:shadow-md`}
    >
      <div className="flex items-start justify-between mb-2">
        <div className="flex-1">
          <h4 className="text-sm font-semibold text-gray-900 dark:text-white mb-1">
            {name}
          </h4>
          {description && (
            <p className="text-xs text-gray-600 dark:text-gray-400">
              {description}
            </p>
          )}
        </div>
        {status && (
          <div
            className={`w-3 h-3 rounded-full ${getStatusDot()} flex-shrink-0 ml-2`}
            title={status}
          />
        )}
      </div>

      <div className="mt-3">
        <div className="text-2xl font-bold text-gray-900 dark:text-white">
          {formatValue(value)} {unit}
        </div>
        {idealValue !== undefined && (
          <div className="text-xs text-gray-600 dark:text-gray-400 mt-1">
            Ideal: {formatValue(idealValue)} {unit}
          </div>
        )}
      </div>
    </div>
  );
};

export default RatioCard;
