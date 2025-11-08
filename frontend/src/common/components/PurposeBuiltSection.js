import React from "react";
import { Link } from "react-router-dom";

function PurposeBuiltSection() {
  const categories = [
    {
      key: "Electronics",
      title: "Electronics",
      subtitle: "Latest smartphones, laptops, gadgets and tech accessories from trusted retailers",
      gradient: "from-orange-400/20 via-yellow-400/10 to-orange-300/10",
      accent: "orange",
    },
    {
      key: "Furniture",
      title: "Furniture",
      subtitle: "Quality furniture for home and office from verified manufacturers and dealers",
      gradient: "from-yellow-400/20 via-orange-400/10 to-yellow-300/10",
      accent: "yellow",
    },
    {
      key: "Appliances",
      title: "Home Appliances",
      subtitle: "Energy-efficient appliances for kitchen, laundry and home automation",
      gradient: "from-blue-400/20 via-blue-500/10 to-blue-600/10",
      accent: "blue",
    },
    {
      key: "Fashion",
      title: "Fashion",
      subtitle: "Trendy clothing, accessories and footwear from established fashion retailers",
      gradient: "from-emerald-400/20 via-teal-400/10 to-green-400/10",
      accent: "emerald",
    },
  ];

  return (
    <section
      className="relative isolate overflow-hidden px-4 py-20 bg-gradient-to-br from-white via-orange-50/30 to-yellow-50/20"
    >
      {/* Light background overlay */}
      <div className="absolute inset-0 bg-gradient-to-t from-slate-100/20 via-transparent to-white/10" />
      <div className="absolute inset-0 bg-gradient-to-r from-orange-600/5 via-transparent to-yellow-500/5" />
      {/* blueprint grid background */}
      <div className="pointer-events-none absolute inset-0 -z-10">
        <div className="absolute inset-0 opacity-20 bg-[linear-gradient(to_right,rgba(59,130,246,0.1)_1px,transparent_1px),linear-gradient(to_bottom,rgba(59,130,246,0.1)_1px,transparent_1px)] [background-size:20px_20px]" />
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(247,147,30,0.05),transparent_60%)]" />
      </div>

      <div className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-3 gap-10">
        {/* sticky intro column */}
        <div className="lg:col-span-1">
          <div className="lg:sticky lg:top-24">
            <span className="inline-flex items-center gap-2 rounded-full bg-orange-100 px-4 py-2 text-sm font-semibold text-orange-800 ring-1 ring-orange-300 shadow-sm">
              <span className="h-2 w-2 rounded-full bg-orange-600 animate-pulse" />
              Product Categories
            </span>
            <h2 className="mt-4 text-3xl sm:text-4xl font-extrabold tracking-tight text-slate-900">
              Quality products and services across multiple industries
            </h2>
            <p className="mt-4 text-slate-900 text-base font-medium bg-white/95 backdrop-blur-sm rounded-lg p-4 border border-slate-200 shadow-md">
              Discover trusted businesses offering everything from electronics and furniture to fashion and home services. Each category features verified partners committed to quality and customer satisfaction.
            </p>
            <div className="mt-6 flex gap-3">
              <Link to="/ventures" className="px-6 py-3 bg-gradient-to-r from-orange-600 to-orange-700 text-white rounded-lg shadow-lg hover:shadow-xl hover:scale-105 transition-all duration-300 font-semibold">
                Browse All Categories
              </Link>
              <Link to="/login" className="px-6 py-3 bg-white/95 border-2 border-slate-300 text-slate-900 rounded-lg hover:bg-white hover:border-slate-400 transition-all duration-300 font-semibold shadow-md backdrop-blur-sm">
                Become a Partner
              </Link>
            </div>
            {/* mini metrics */}
            <div className="mt-8 grid grid-cols-3 gap-3">
              {[{v:"50+",l:"Customers"},{v:"10+",l:"Partners"},{v:"8",l:"Categories"}].map((m)=> (
                <div key={m.l} className="rounded-xl bg-white/95 ring-1 ring-slate-200 p-4 text-center shadow-md hover:shadow-lg hover:scale-105 transition-all duration-300 backdrop-blur-sm">
                  <p className="text-xl font-extrabold text-slate-900">{m.v}</p>
                  <p className="text-xs text-slate-700 font-medium mt-1">{m.l}</p>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* blueprint canvas with cards */}
        <div className="lg:col-span-2 relative">
          {/* decorative connectors (schematic) */}
          <svg className="pointer-events-none absolute inset-0 -z-10" viewBox="0 0 800 600" fill="none" xmlns="http://www.w3.org/2000/svg">
            <g stroke="#F7931E" strokeOpacity="0.25" strokeWidth="2">
              <path d="M80 120 C 220 120, 240 260, 360 260" />
              <path d="M360 260 C 520 260, 560 160, 700 160" />
              <path d="M360 260 C 520 260, 560 420, 700 420" />
              <circle cx="80" cy="120" r="4" fill="#F7931E" opacity="0.5" />
              <circle cx="360" cy="260" r="4" fill="#F7931E" opacity="0.5" />
              <circle cx="700" cy="160" r="4" fill="#F7931E" opacity="0.5" />
              <circle cx="700" cy="420" r="4" fill="#F7931E" opacity="0.5" />
            </g>
          </svg>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
            {categories.map((cat, idx) => (
              <article
                key={cat.key}
                className={`group relative overflow-hidden rounded-2xl bg-white/95 ring-1 ring-slate-200 shadow transition-all duration-300 hover:shadow-lg hover:-translate-y-0.5 backdrop-blur-sm ${
                  idx % 2 === 1 ? "sm:translate-y-6" : ""
                }`}
              >
                <div className={`relative h-40 bg-gradient-to-br ${cat.gradient} border-b border-slate-200`}>
                  <div className="absolute inset-0 opacity-20 bg-[radial-gradient(rgba(59,130,246,0.3)_1px,transparent_1px)] [background-size:18px_18px]" />
                  <div className="absolute inset-0 grid place-items-center">
                    <span className="inline-flex items-center rounded-full bg-white/95 backdrop-blur-sm px-3 py-1 text-xs font-bold text-slate-900 ring-1 ring-slate-300 shadow-sm">
                      {cat.key}
                    </span>
                  </div>
                </div>
                <div className="p-6 bg-white/90">
                  <h3 className="text-lg font-bold text-slate-900 tracking-tight group-hover:text-orange-600 transition-colors">
                    {cat.title}
                  </h3>
                  <p className="text-sm text-slate-700 mt-2 font-medium leading-relaxed">{cat.subtitle}</p>
                  <div className="mt-4 flex flex-wrap gap-2">
                    {["Verified Sellers", "Quality Assured", "Secure Payment"].map((t) => (
                      <span key={t} className="text-xs px-3 py-1 rounded-full bg-orange-100 text-orange-800 ring-1 ring-orange-300 font-medium shadow-sm backdrop-blur-sm">
                        {t}
                      </span>
                    ))}
                  </div>
                </div>
                <Link to="/ventures" className="absolute inset-0" aria-label={`Open ${cat.title}`} />
              </article>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

export default PurposeBuiltSection;


