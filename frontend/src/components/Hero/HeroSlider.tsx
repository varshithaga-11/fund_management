import React, { useState, useEffect } from 'react';
import happy from '../../assets/happy-bank.jpg';
import female from '../../assets/female.jpg';

const HeroSection = () => {
  const [currentImage, setCurrentImage] = useState(0);
  const images = [female, happy]; // Use direct references to imported images

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentImage((prev) => (prev === 0 ? 1 : 0));
    }, 3000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="relative w-full h-screen flex items-center justify-start ">
      {/* Full-width banner with transitioning images */}
      <div className="absolute inset-0 w-full h-full">
        {images.map((image, index) => (
          <img
            key={index}
            src={image}
            alt={index === 0 ? 'Female Customer' : 'Happy Bank Customer'} // Updated alt text
            className={`absolute w-full h-full object-cover transition-opacity duration-1000 ${
              index === currentImage ? 'opacity-100' : 'opacity-0'
            }`}
          />
        ))}
      </div>
      {/* Text overlay */}
      <div className="relative z-10 text-white px-10">
        <p className="text-sm uppercase">Banking Solutions</p>
        <h1 className="text-5xl font-bold">Innovative Banking Services</h1>
        <p className="text-lg mt-4">
          Empowering your financial future with secure and innovative banking solutions.
        </p>
        <button className="mt-6 bg-blue-600 text-white px-6 py-2 rounded flex items-center">
          Learn More <span className="ml-2">→</span>
        </button>
      </div>
    </div>
  );
};

export default HeroSection;