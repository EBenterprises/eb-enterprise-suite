/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,

  // Termux / Android filesystem stability:
  // avoid webpack persistent filesystem cache races.
  webpack: (config) => {
    config.cache = false;
    return config;
  },

  experimental: {
    cpus: 1,
  },
};

export default nextConfig;
