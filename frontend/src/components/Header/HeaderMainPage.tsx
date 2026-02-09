"use client";

import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import {
  FaFacebookF,
  FaTwitter,
  FaInstagram,
  FaPinterestP,
  FaSearch,
} from "react-icons/fa";
import { FiChevronDown } from "react-icons/fi";
import { useLanguage } from "../Context/LanguageContext";
import logo from "../../assets/logo.jpg";

export default function HeaderMainPage() {
  const { language, setLanguage } = useLanguage();
  const [openDropdown, setOpenDropdown] = useState<string | null>(null);
  const [langOpen, setLangOpen] = useState(false);
  const [isScrolled, setIsScrolled] = useState(false);

  // ✅ detect scroll
  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY > 50) {
        setIsScrolled(true);
      } else {
        setIsScrolled(false);
      }
    };
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  // ✅ translations
  const translations = {
    en: {
      home: "HOME",
      about: "ABOUT US",
      services: "SERVICE",
      branch: "BRANCHES",
      blogs: "Blogs",
      contact: "CONTACT ",

      // Dropdowns
      history: "History",
      team: "Our Team",
      career: "Career",
      loans: "Loans",
      savings: "Savings",
      branch1: "Branch 1",
      branch2: "Branch 2",
    },
    ml: {
      home: "ഹോം",
      about: "ഞങ്ങളേക്കുറിച്ച്",
      career: "കരിയർ",
      services: "സേവനങ്ങൾ",
      branch: "ശാഖകൾ",
      blogs: "ബ്ലോഗുകൾ",
      contact: "ബന്ധപ്പെടുക",

      // Dropdowns
      history: "ചരിത്രം",
      team: "ഞങ്ങളുടെ സംഘം",
      loans: "ലോണുകൾ",
      savings: "സേവിംഗ്സ്",
      branch1: "ശാഖ 1",
      branch2: "ശാഖ 2",
    },
  };

  const t = translations[language];

  return (
    <header className="w-full  z-50 relative">
      {/* Top bar (NOT sticky) */}
      <div className="bg-[#030333] text-white text-md py-4 px-28 flex justify-between items-center">
        <div className="flex items-center space-x-6">
          <span className="flex items-center space-x-2">
            <span>📍</span>
            <span>256 Avenue, Mark Street, NewYork City</span>
          </span>
          <span className="flex items-center space-x-2">
            <span>✉️</span>
            <a href="mailto:info@gmail.com" className="hover:underline">
              info@gmail.com
            </a>
          </span>
        </div>
        <div className="flex items-center space-x-4">
          <a href="tel:+12348844889" className="flex items-center hover:underline">
            📞 +123 4884 4889
          </a>
          <a href="#" className="hover:text-blue-500">
            <FaFacebookF />
          </a>
          <a href="#" className="hover:text-blue-400">
            <FaTwitter />
          </a>
          <a href="#" className="hover:text-pink-500">
            <FaInstagram />
          </a>
          <a href="#" className="hover:text-red-500">
            <FaPinterestP />
          </a>
          <Link to="/login">
            <button className="ml-4 px-4 py-2 border border-white text-white rounded hover:bg-white hover:text-black transition-all duration-500">Login</button>
          </Link>
        </div>
      </div>

      {/* Navbar (Sticky + smooth transition) */}
      <nav
        className={` top-0 transition-all duration-500 flex justify-around items-center px-6 py-6 ${
          isScrolled
            ? "bg-white shadow-md translate-y-0 opacity-100 fixed w-full"
            : "bg-transparent  opacity-90"
        }`}
      >
        {/* Logo */}
        <div className="flex items-center justify-center space-x-2 font-bold text-2xl">
          <span className="w-15 h-10 overflow-hidden">
            <img src={logo} alt="logo" />
          </span>
          <div className="flex flex-col items-center justify-center">
            <p className="text-[24px] font-bold italic text-black">
              Account Management
            </p>
            <p className="text-[10px] italic font-bold text-black">
              Account Management
            </p>
          </div>
        </div>

        {/* Navigation */}
        <ul className="flex items-center space-x-8 font-medium relative z-50">
          {/* Home */}
          <li>
            <Link to="/" className="hover:text-blue-600">
              {t.home}
            </Link>
          </li>

          {/* About Dropdown */}
          <li
            className="relative"
            onMouseEnter={() => setOpenDropdown("about")}
            onMouseLeave={() => setOpenDropdown(null)}
          >
            <button className="flex items-center space-x-1 hover:text-blue-600">
              {t.about} <FiChevronDown />
            </button>
            <ul
              className={`absolute z-[1001] left-0 mt-9 bg-white shadow-md border-t-2 border-white rounded-b-md w-40 transition-all duration-300 transform ${
                openDropdown === "about"
                  ? "opacity-100 translate-y-0"
                  : "opacity-0 -translate-y-10 "
              }`}
            >
              <li>
                <Link to="/about" className="block px-4 py-2  hover:text-blue-600">
                  {t.history}
                </Link>
              </li>
              <li>
                <Link to="/team" className="block px-4 py-2  hover:text-blue-600">
                  {t.team}
                </Link>
              </li>
              <li>
                <Link to="/careers" className="block px-4 py-2  hover:text-blue-600">
                  {t.career}
                </Link>
              </li>
            </ul>
          </li>

          {/* Services Dropdown */}
          <li
            className="relative"
            onMouseEnter={() => setOpenDropdown("services")}
            onMouseLeave={() => setOpenDropdown(null)}
          >
            <button className="flex items-center space-x-1 hover:text-blue-600">
              {t.services} <FiChevronDown />
            </button>
            <ul
              className={`absolute left-0 mt-9 bg-white shadow-md rounded-b-md w-40 transition-all duration-300 transform ${
                openDropdown === "services"
                  ? "opacity-100 translate-y-0"
                  : "opacity-0 -translate-y-10 "
              }`}
            >
              <li>
                <Link to="/service" className="block px-4 py-2 hover:text-blue-600">
                  {t.services}
                </Link>
                <Link to="/loans" className="block px-4 py-2 hover:text-blue-600">
                  {t.loans}
                </Link>
              </li>
              <li>
                <Link to="/savings" className="block px-4 py-2 hover:text-blue-600">
                  {t.savings}
                </Link>
              </li>
            </ul>
          </li>

          {/* Branch Dropdown */}
          <li
            className="relative"
            onMouseEnter={() => setOpenDropdown("branch")}
            onMouseLeave={() => setOpenDropdown(null)}
          >
            <button className="flex items-center space-x-1 hover:text-blue-600">
              {t.branch} <FiChevronDown />
            </button>
            <ul
              className={`absolute left-0 mt-9 bg-white shadow-md rounded-b-md w-40 transition-all duration-300 transform ${
                openDropdown === "branch"
                  ? "opacity-100 translate-y-0"
                  : "opacity-0 -translate-y-10 cursor-pointer "
              }`}
            >
              <li>
                <Link to="/branch1" className="block px-4 py-2 hover:text-blue-600">
                  {t.branch1}
                </Link>
              </li>
              <li>
                <Link to="/branch2" className="block px-4 py-2 hover:text-blue-600">
                  {t.branch2}
                </Link>
              </li>
            </ul>
          </li>

          {/* Blogs */}
          {/* <li>
            <Link to="/blogs" className="hover:text-blue-600">
              {t.blogs}
            </Link>
          </li> */}

          {/* Contact */}
          <li>
            <Link to="/contact" className="hover:text-blue-600">
              {t.contact}
            </Link>
          </li>
        </ul>

        {/* Right side actions */}
        <div className="flex items-center space-x-4 relative">
          <button className="p-2 hover:text-blue-600">
            <FaSearch />
          </button>

          {/* Language Dropdown */}
          <div className="relative">
            <button
              onClick={() => setLangOpen(!langOpen)}
              className="px-4 py-2 border-1 border-gray-400 rounded-lg flex items-center space-x-2 hover:bg-blue-700 hover:text-white transition-all duration-500"
            >
              <span>{language === "en" ? "English" : "മലയാളം"}</span>
              <FiChevronDown />
            </button>
            <ul
              className={`absolute right-0 mt-2 bg-white shadow-md rounded-lg border w-36 transition-all duration-300 transform ${
                langOpen
                  ? "opacity-100 translate-y-0"
                  : "opacity-0 -translate-y-2 pointer-events-none"
              }`}
            >
              <li
                className="px-4 py-2 hover:text-blue-600 cursor-pointer"
                onClick={() => {
                  setLanguage("en");
                  setLangOpen(false);
                }}
              >
                English
              </li>
              <li
                className="px-4 py-2 hover:text-blue-600 cursor-pointer"
                onClick={() => {
                  setLanguage("ml");
                  setLangOpen(false);
                }}
              >
                മലയാളം
              </li>
            </ul>
          </div>
        </div>
      </nav>
    </header>
  );
}
