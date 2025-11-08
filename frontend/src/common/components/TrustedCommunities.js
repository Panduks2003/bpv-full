import React from "react";

function TrustedCommunities() {
  const businessTypes = [
    "Electronics Stores",
    "Furniture Retailers",
    "Home Appliances",
    "Fashion Boutiques",
    "Local Services",
    "Home Decor",
    "Tech Solutions",
    "Lifestyle Brands",
  ];

  return (
    <section className="relative px-4 py-16 overflow-hidden bg-gradient-to-br from-white via-orange-50/30 to-yellow-50/20">
      {/* Light background overlay */}
      <div className="absolute inset-0 bg-gradient-to-t from-slate-100/20 via-transparent to-white/10" />
      <div className="absolute inset-0 bg-gradient-to-r from-orange-600/5 via-transparent to-yellow-500/5" />
      {/* soft background */}
      <div className="pointer-events-none absolute inset-0 -z-10">
        <div className="absolute -top-40 -left-32 h-[26rem] w-[26rem] rounded-full bg-gradient-to-tr from-orange-500/15 via-yellow-500/15 to-orange-400/15 blur-3xl" />
        <div className="absolute -bottom-40 -right-32 h-[24rem] w-[24rem] rounded-full bg-gradient-to-br from-yellow-500/15 via-orange-500/15 to-blue-600/10 blur-3xl" />
      </div>

      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="text-center">
          <span className="inline-flex items-center gap-2 rounded-full bg-orange-100 px-4 py-2 text-sm font-semibold text-orange-800 ring-1 ring-orange-300 shadow-sm">
            <span className="h-2 w-2 rounded-full bg-orange-600 animate-pulse" />
            Serving diverse business categories
          </span>
          <h2 className="mt-4 text-3xl sm:text-4xl font-bold text-slate-900">
            Connecting customers with quality businesses
          </h2>
          <p className="mt-3 text-slate-900 max-w-2xl mx-auto text-base font-medium bg-white/95 backdrop-blur-sm rounded-lg p-3 border border-slate-200 shadow-md">
            From electronics to fashion, furniture to home services - discover trusted businesses across multiple industries.
          </p>
        </div>

        {/* Marquee row 1 */}
        <div className="relative mt-12 mb-6">
          {/* gradient fade edges */}
          <div className="pointer-events-none absolute inset-y-0 left-0 w-16 bg-gradient-to-r from-white via-white/80 to-transparent z-10" />
          <div className="pointer-events-none absolute inset-y-0 right-0 w-16 bg-gradient-to-l from-white via-white/80 to-transparent z-10" />

          <Marquee>
            {businessTypes.map((name, idx) => (
              <BusinessCard key={`m1-${idx}-${name}`} name={name} variant={idx % 4} />
            ))}
          </Marquee>
        </div>

        {/* Marquee row 2 (reverse) */}
        <div className="relative mt-6 mb-8">
          <div className="pointer-events-none absolute inset-y-0 left-0 w-16 bg-gradient-to-r from-white via-white/80 to-transparent z-10" />
          <div className="pointer-events-none absolute inset-y-0 right-0 w-16 bg-gradient-to-l from-white via-white/80 to-transparent z-10" />

          <Marquee reverse={true}>
            {businessTypes.map((name, idx) => (
              <BusinessCard key={`m2-${idx}-${name}`} name={name} variant={(idx + 2) % 4} />
            ))}
          </Marquee>
        </div>

        {/* Stats ribbon */}
        <div className="mt-16">
          <div className="relative mx-auto max-w-5xl overflow-hidden rounded-2xl bg-gradient-to-r from-orange-600 via-yellow-500 to-orange-700 text-white shadow-xl border border-orange-300">
            <div className="absolute inset-0 opacity-20 bg-[radial-gradient(rgba(255,255,255,0.4)_1px,transparent_1px)] [background-size:18px_18px]" />
            <div className="absolute inset-0 bg-white/5" />
            <div className="relative grid grid-cols-2 sm:grid-cols-4 divide-x divide-white/20">
              <Stat value="50+" label="Customers" />
              <Stat value="10+" label="Partners" />
              <Stat value="8" label="Categories" />
              <Stat value="24/7" label="Support" />
            </div>
          </div>
        </div>
      </div>

      {/* marquee keyframes */}
      <style>{`
        @keyframes marquee {
          0% { transform: translateX(0%); }
          100% { transform: translateX(-100%); }
        }
        
        .marquee-container {
          display: flex;
          animation: marquee 30s linear infinite;
          gap: 24px;
        }
        
        .marquee-reverse {
          display: flex;
          animation: marquee 35s linear infinite reverse;
          gap: 24px;
        }
      `}</style>
    </section>
  );
}

function Marquee({ children, reverse = false }) {
  return (
    <div className="overflow-hidden relative">
      <div className={reverse ? "marquee-reverse" : "marquee-container"}>
        {children}
        {children}
      </div>
    </div>
  );
}

function BusinessCard({ name, variant }) {
  const gradients = [
    "from-white to-gray-50",
    "from-orange-100 to-orange-50",
    "from-yellow-100 to-yellow-50",
    "from-blue-100 to-blue-50",
  ];
  const rings = [
    "ring-gray-300",
    "ring-orange-300",
    "ring-yellow-300",
    "ring-blue-300",
  ];
  const textColors = [
    "text-gray-800",
    "text-orange-800",
    "text-yellow-800",
    "text-blue-800",
  ];
  return (
    <div className={`flex-shrink-0 rounded-xl bg-gradient-to-br ${gradients[variant]} ring-1 ${rings[variant]} shadow-md hover:shadow-lg transition-all duration-300 hover:scale-105`}> 
      <div className={`h-12 sm:h-14 w-[180px] sm:w-[200px] px-4 grid place-items-center text-xs sm:text-sm font-semibold ${textColors[variant]} drop-shadow-sm whitespace-nowrap`}>
        {name}
      </div>
    </div>
  );
}

function Stat({ value, label }) {
  return (
    <div className="px-5 py-5 sm:px-6 sm:py-6 text-center hover:bg-white/10 transition-colors duration-300">
      <p className="text-2xl sm:text-3xl font-extrabold text-white drop-shadow-lg">{value}</p>
      <p className="text-sm sm:text-base text-white font-medium drop-shadow-md mt-1">{label}</p>
    </div>
  );
}

export default TrustedCommunities;


