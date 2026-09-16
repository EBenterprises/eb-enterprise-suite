/** @type {import('next').NextConfig} */

const nextConfig = {
  turbopack: {},
    allowedDevOrigins: [
        "127.0.0.1",
        "localhost",
        "192.168.1.188"
    ],

    webpack: (config) => {
        config.resolve.alias = {
            ...(config.resolve.alias || {}),
            "@framework": require("path").resolve(
                __dirname,
                "framework"
            ),
            "@app": require("path").resolve(
                __dirname,
                "app"
            ),
            "@": require("path").resolve(
                __dirname
            )
        };

        return config;
    }
};

module.exports = nextConfig;
