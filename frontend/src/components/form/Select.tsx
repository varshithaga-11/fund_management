import React, { useEffect, useRef, useState } from "react";

interface Option { value: string; label: string; }
interface SelectProps {
  name?: string;                // optional name
  options: Option[];
  value?: string;
  onChange: (value: string) => void;
  placeholder?: string;
  className?: string;
  disabled?: boolean;           // optional disabled
  error?: string;               // optional error message
  required?: boolean; // <-- add required
}

const Select: React.FC<SelectProps> = ({
  options,
  value,
  onChange,
  placeholder = "Select an option",
  className = "",
  disabled = false,
  error,
  required = false, // <-- default false

}) => {
  const [open, setOpen] = useState(false);
  const [internal, setInternal] = useState(value ?? "");
  const ref = useRef<HTMLDivElement>(null);
  const [touched, setTouched] = useState(false); // track if field was touched

  // sync external value
  useEffect(() => { if (value !== undefined) setInternal(value); }, [value]);

  // close on outside click
  useEffect(() => {
    const onDoc = (e: MouseEvent) => {
      if (!ref.current || ref.current.contains(e.target as Node)) return;
      setOpen(false);
    };
    document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, []);

  const selected = options.find(o => o.value === internal);
  const showError = required && touched && !internal; // show error if required and empty

  return (
    <div ref={ref} className={`relative ${className}`}>
      <button
        type="button"
        onClick={() => { setOpen(o => !o); setTouched(true); }}
        disabled={disabled}
        className={`h-11 w-full rounded-lg border border-gray-300 dark:border-gray-700
                  bg-white dark:bg-gray-900 px-4 pr-10 text-left text-sm
                  text-gray-900 dark:text-white/90 focus:outline-none
                  ${disabled ? "opacity-50 cursor-not-allowed" : ""}
                  ${showError ? "border-red-500" : ""}`}
      >
        {selected ? selected.label : <span className="text-gray-400">{placeholder}</span>}
        <svg className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 opacity-70"
             viewBox="0 0 20 20" fill="currentColor"><path d="M5.23 7.21a.75.75 0 0 1 1.06.02L10 10.94l3.71-3.71a.75.75 0 1 1 1.06 1.06l-4.24 4.24a.75.75 0 0 1-1.06 0L5.21 8.29a.75.75 0 0 1 .02-1.08z"/></svg>
      </button>

      {open && (
        <ul
          className="absolute z-50 mt-1 w-full max-h-60 overflow-auto rounded-lg
                     border border-gray-700 dark:border-gray-900 bg-white dark:bg-gray-900
                     shadow-lg"
        >
          {options.map(opt => (
            <li key={opt.value}>
              <button
                type="button"
                onClick={() => { setInternal(opt.value); onChange(opt.value); setOpen(false); }}
                className={`block w-full px-4 py-2 text-left text-sm
                           ${internal === opt.value
                              ? "bg-gray-100 dark:bg-gray-800"
                              : "hover:bg-gray-50 dark:hover:bg-gray-800/70"}
                           text-gray-900 dark:text-gray-100`}
              >
                {opt.label}
              </button>
            </li>
          ))}
        </ul>
      )}
      {(showError || error) && <p className="text-red-500 text-xs mt-1">{error || "This field is required"}</p>}

    </div>
  );
};

export default Select;
